'use strict';

// Gemini 娘挂件（macOS 移植版）宿主侧模块。
// 构建脚本把它写入 app.asar 的 dist/gyWidgetMain.js，并在 dist/main.js 末尾以
// try/catch 包裹 require —— 任何异常都不允许影响 Antigravity 本体启动。
//
// 形态：**不开独立窗口**。UI 全部注入宿主页面 DOM（见 inject/renderer/widget-page.js，
// 由构建脚本追加进宿主自己的 dist/preload.js，与汉化引擎面板同一条注入路径）。
// 本模块只做数据与系统能力：额度拉取、角色图库、导入对话框、设置持久化，
// 经 ipcMain 与页内挂件通信。好处是跟窗/最小化/登录页隐藏都是页面内天然行为，
// 也不会被宿主「Port changed! Reloading all windows」之类的整窗重载劫持。

const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const crypto = require('crypto');
const electron = require('electron');

const { app, dialog, ipcMain, shell, webContents } = electron;

const WIDGET_DIR = path.join(__dirname, 'gyWidget');
const APP_NAME = 'GeminiNiangWidget';
// 与上游 Windows 挂件同名：上游配套插件的额度 MCP 读的就是本目录下的
// status.json，保持形状兼容它才能继续可用。
const DATA_DIR = path.join(os.homedir(), 'Library', 'Application Support', APP_NAME);
const QUOTA_PATH = '/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary';
const ROWS_PER_PAGE = 3;
const REFRESH_MS = 60000;
const IMPORT_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.avif', '.bmp'];
const SCALE_MIN = 0.6;
const SCALE_MAX = 2;
const MIME = {
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif',
  '.webp': 'image/webp', '.avif': 'image/avif', '.bmp': 'image/bmp',
};

const BUILTIN = readJson(path.join(WIDGET_DIR, 'characters', 'characters.json'), { characters: [], default: '' });
const BUILTIN_QUOTES = readJson(path.join(WIDGET_DIR, 'assets', 'quotes.json'), { quotes: [] }).quotes || [];

let timers = [];
let sessionHidden = false;
let quota = { source: 'none', groups: [], updatedAt: 0, reason: '' };
let settings = loadSettings();

function readJson(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (_e) {
    return fallback;
  }
}

function writeJson(file, value) {
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, JSON.stringify(value, null, 2), 'utf8');
    return true;
  } catch (e) {
    console.warn('[gyWidget] 写入失败:', file, e.message);
    return false;
  }
}

function loadSettings() {
  const stored = readJson(path.join(DATA_DIR, 'settings.json'), {});
  const scale = Number(stored.scale);
  const offset = stored.offset && typeof stored.offset === 'object' ? stored.offset : {};
  const ox = Number(offset.x);
  const oy = Number(offset.y);
  return {
    character: typeof stored.character === 'string' && stored.character ? stored.character : (BUILTIN.default || 'gemini-default'),
    scale: Number.isFinite(scale) ? Math.min(SCALE_MAX, Math.max(SCALE_MIN, scale)) : 1,
    offset: { x: Number.isFinite(ox) ? ox : 0, y: Number.isFinite(oy) ? oy : 0 },
    quotes: Array.isArray(stored.quotes) ? stored.quotes : null,
  };
}

function saveSettings() {
  writeJson(path.join(DATA_DIR, 'settings.json'), {
    character: settings.character,
    scale: settings.scale,
    offset: settings.offset,
  });
}

function activeQuotes() {
  const userFile = readJson(path.join(DATA_DIR, 'quotes.json'), null);
  if (userFile && Array.isArray(userFile.quotes) && userFile.quotes.length) return userFile.quotes;
  if (settings.quotes && settings.quotes.length) return settings.quotes;
  return BUILTIN_QUOTES;
}

// ---------------------------------------------------------------------------
// 角色图库：内置清单 + 用户导入（id 形如 custom-<32hex>，移除进 removed/ 可恢复）
// 页内挂件拿不到 fs，图片字节由本模块经 gy:portrait 以 data URL 交付。
// ---------------------------------------------------------------------------

function customCatalog() {
  const cat = readJson(path.join(DATA_DIR, 'characters.json'), null);
  if (!cat || !Array.isArray(cat.characters)) return { version: 1, characters: [] };
  return cat;
}

function isOwnCustom(entry) {
  const id = String(entry && entry.id || '');
  const file = String(entry && entry.file || '');
  return /^custom-[0-9a-f]{32}$/.test(id) && (file === id + '.png' || file === id + '.gif');
}

function customDir(entry) {
  return entry.removed ? path.join(DATA_DIR, 'characters', 'removed') : path.join(DATA_DIR, 'characters');
}

function characterList() {
  const builtin = (BUILTIN.characters || []).map((c) => ({
    id: c.id,
    name: c.name,
    kind: 'built-in',
    path: path.join(WIDGET_DIR, 'characters', c.file),
  })).filter((c) => fs.existsSync(c.path));

  const custom = customCatalog().characters
    .filter(isOwnCustom)
    .map((c) => ({
      id: c.id,
      name: c.name || '自定义角色',
      kind: c.removed ? 'removed' : 'custom',
      path: path.join(customDir(c), c.file),
    }))
    .filter((c) => fs.existsSync(c.path));

  return { shown: builtin.concat(custom.filter((c) => c.kind === 'custom')), removed: custom.filter((c) => c.kind === 'removed') };
}

function characterPath(id) {
  const { shown, removed } = characterList();
  const hit = shown.find((c) => c.id === id) || removed.find((c) => c.id === id) || shown.find((c) => c.id === settings.character);
  return hit ? hit.path : null;
}

function portrait(id) {
  const file = characterPath(id);
  if (!file) return { ok: false, reason: '角色不存在' };
  try {
    const mime = MIME[path.extname(file).toLowerCase()] || 'image/png';
    return { ok: true, dataUrl: 'data:' + mime + ';base64,' + fs.readFileSync(file).toString('base64') };
  } catch (e) {
    return { ok: false, reason: e.message };
  }
}

function importCharacter() {
  const picked = dialog.showOpenDialogSync({
    title: '导入角色图片',
    buttonLabel: '导入',
    properties: ['openFile'],
    filters: [{ name: '图片', extensions: IMPORT_EXTS.map((e) => e.slice(1)) }],
  });
  if (!picked || !picked.length) return { ok: false, reason: '已取消' };
  const src = picked[0];
  const ext = path.extname(src).toLowerCase();
  if (!IMPORT_EXTS.includes(ext)) return { ok: false, reason: '支持 PNG、JPG、GIF、WebP、AVIF 和 BMP' };
  if (!fs.existsSync(src)) return { ok: false, reason: '文件不存在' };

  const id = 'custom-' + crypto.randomBytes(16).toString('hex');
  // Chromium 原生解这些格式，保留原图不转码（Windows 版必须转 PNG 是 WPF 的限制）。
  const file = id + (ext === '.gif' ? '.gif' : ext === '.png' ? '.png' : ext === '.jpg' || ext === '.jpeg' ? '.jpg' : ext);
  const dest = path.join(DATA_DIR, 'characters', file);
  try {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  } catch (e) {
    return { ok: false, reason: '复制失败：' + e.message };
  }

  const cat = customCatalog();
  cat.characters.push({ id, file, name: path.basename(src, ext) });
  if (!writeJson(path.join(DATA_DIR, 'characters.json'), cat)) {
    try { fs.rmSync(dest, { force: true }); } catch (_e) {}
    return { ok: false, reason: '写入角色清单失败' };
  }
  setCharacter(id);
  return { ok: true, id };
}

function removeCharacter(id) {
  const cat = customCatalog();
  const entry = cat.characters.find((c) => isOwnCustom(c) && c.id === id && !c.removed);
  if (!entry) return { ok: false, reason: '找不到可移除的导入角色' };
  const from = path.join(customDir(entry), entry.file);
  const to = path.join(DATA_DIR, 'characters', 'removed', entry.file);
  try {
    fs.mkdirSync(path.dirname(to), { recursive: true });
    fs.renameSync(from, to);
  } catch (e) {
    return { ok: false, reason: e.message };
  }
  entry.removed = true;
  writeJson(path.join(DATA_DIR, 'characters.json'), cat);
  if (settings.character === id) setCharacter(BUILTIN.default);
  else pushState();
  return { ok: true };
}

function restoreCharacter(id) {
  const cat = customCatalog();
  const entry = cat.characters.find((c) => isOwnCustom(c) && c.id === id && c.removed);
  if (!entry) return { ok: false, reason: '找不到可恢复的导入角色' };
  const from = path.join(DATA_DIR, 'characters', 'removed', entry.file);
  const to = path.join(DATA_DIR, 'characters', entry.file);
  if (cat.characters.some((c) => !c.removed && c.file === entry.file)) return { ok: false, reason: '同名角色已存在' };
  try {
    fs.renameSync(from, to);
  } catch (e) {
    return { ok: false, reason: e.message };
  }
  delete entry.removed;
  writeJson(path.join(DATA_DIR, 'characters.json'), cat);
  pushState();
  return { ok: true };
}

// ---------------------------------------------------------------------------
// 额度：宿主本机 hub 接口。Windows 版用 Get-NetTCPConnection 验端口归属，
// macOS 侧靠 pid 存活 + 请求成败判定即可（同一份 hub_*.json 布局）。
// ---------------------------------------------------------------------------

function findHub() {
  const dir = path.join(os.homedir(), '.gemini', 'antigravity', 'daemon');
  let names = [];
  try {
    names = fs.readdirSync(dir).filter((f) => /^hub_.+\.json$/.test(f));
  } catch (_e) {
    return null;
  }
  const ranked = names
    .map((f) => {
      try {
        return { f, mtime: fs.statSync(path.join(dir, f)).mtimeMs };
      } catch (_e) {
        return { f, mtime: 0 };
      }
    })
    .sort((a, b) => b.mtime - a.mtime);

  for (const item of ranked) {
    const hub = readJson(path.join(dir, item.f), null);
    if (!hub || typeof hub.httpPort !== 'number' || typeof hub.csrfToken !== 'string') continue;
    if (hub.httpPort < 1 || hub.httpPort > 65535) continue;
    let alive = false;
    try {
      process.kill(hub.pid, 0);
      alive = true;
    } catch (_e) {
      alive = false;
    }
    if (!alive) continue;
    return hub;
  }
  return null;
}

function fetchQuota() {
  return new Promise((resolve) => {
    const hub = findHub();
    if (!hub) return resolve({ ok: false, reason: '未找到运行中的 Antigravity hub' });

    const req = http.request(
      {
        host: '127.0.0.1',
        port: hub.httpPort,
        path: QUOTA_PATH,
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'content-length': '2',
          'X-Codeium-Csrf-Token': hub.csrfToken,
        },
        timeout: 8000,
      },
      (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => { body += chunk; });
        res.on('end', () => {
          if (res.statusCode !== 200) return resolve({ ok: false, reason: 'HTTP ' + res.statusCode });
          let parsed = null;
          try { parsed = JSON.parse(body); } catch (_e) { return resolve({ ok: false, reason: '响应不是 JSON' }); }
          const groups = parsed && parsed.response && parsed.response.groups;
          if (!Array.isArray(groups)) return resolve({ ok: false, reason: '响应缺少 groups 字段' });
          resolve({ ok: true, groups });
        });
      }
    );
    req.on('timeout', () => req.destroy(new Error('请求超时')));
    req.on('error', (e) => resolve({ ok: false, reason: e.message }));
    req.end('{}');
  });
}

let refreshing = false;

async function refreshQuota() {
  if (refreshing) return;
  refreshing = true;
  try {
    const res = await fetchQuota();
    if (res.ok) {
      quota = { source: 'hub-api', groups: res.groups, updatedAt: Date.now(), reason: '' };
      writeJson(path.join(DATA_DIR, 'status.json'), {
        version: 1,
        updatedAt: new Date(quota.updatedAt).toISOString(),
        source: quota.source,
        groups: quota.groups,
      });
    } else if (quota.source !== 'hub-api') {
      // 后台源失效：先看本次已有读数，再回落到上次快照（与上游行为一致）。
      const last = readJson(path.join(DATA_DIR, 'status.json'), null);
      if (last && Array.isArray(last.groups)) {
        const at = Date.parse(last.updatedAt) || 0;
        quota = { source: 'snapshot', groups: last.groups, updatedAt: at, reason: res.reason };
      } else {
        quota = { source: 'none', groups: [], updatedAt: 0, reason: res.reason };
      }
    } else {
      quota.reason = res.reason;
    }
  } finally {
    refreshing = false;
    console.log('[gyWidget] 额度刷新：' + quota.source + ' 分组=' + (quota.groups || []).length + (quota.reason ? ' 原因=' + quota.reason : ''));
    pushState();
  }
}

function quotaPages() {
  const rows = [];
  for (const group of quota.groups || []) {
    for (const bucket of (group && group.buckets) || []) {
      rows.push({
        group: group.displayName || '',
        label: bucket.displayName || bucket.bucketId || '',
        fraction: typeof bucket.remainingFraction === 'number' ? bucket.remainingFraction : null,
        window: bucket.window || '',
        resetTime: bucket.resetTime || '',
        description: bucket.description || '',
      });
    }
  }
  const pages = [];
  for (let i = 0; i < rows.length; i += ROWS_PER_PAGE) pages.push(rows.slice(i, i + ROWS_PER_PAGE));
  return pages;
}

// ---------------------------------------------------------------------------
// 状态广播与 IPC：页内挂件是唯一 UI，主进程不创建任何窗口
// ---------------------------------------------------------------------------

function statePayload() {
  const { shown, removed } = characterList();
  return {
    characters: shown,
    removedCharacters: removed,
    active: settings.character,
    scale: settings.scale,
    offset: settings.offset,
    hidden: sessionHidden,
    quota: { source: quota.source, updatedAt: quota.updatedAt, reason: quota.reason, pages: quotaPages() },
    quotes: activeQuotes(),
    dataDir: DATA_DIR,
  };
}

function pushStateTo(wc) {
  try {
    if (wc && !wc.isDestroyed()) wc.send('gy:state', statePayload());
  } catch (_e) {}
}

function pushState() {
  for (const wc of webContents.getAllWebContents()) {
    try {
      if (wc.getType() === 'window') pushStateTo(wc);
    } catch (_e) {}
  }
}

function setCharacter(id) {
  settings.character = id;
  saveSettings();
  pushState();
}

function setScale(value) {
  const scale = Number(value);
  if (!Number.isFinite(scale)) return;
  settings.scale = Math.min(SCALE_MAX, Math.max(SCALE_MIN, scale));
  saveSettings();
  pushState();
}

function handleAction(arg) {
  const type = arg && arg.type;
  switch (type) {
    case 'select': if (typeof arg.id === 'string' && arg.id) setCharacter(arg.id); return { ok: true };
    case 'scale': setScale(arg.value); return { ok: true };
    case 'offset': {
      const x = Number(arg.x); const y = Number(arg.y);
      if (Number.isFinite(x) && Number.isFinite(y)) {
        settings.offset = { x: Math.round(x), y: Math.round(y) };
        saveSettings();
      }
      return { ok: true };
    }
    case 'refresh': refreshQuota(); return { ok: true };
    case 'import': return importCharacter();
    case 'remove': return removeCharacter(arg.id);
    case 'restore': return restoreCharacter(arg.id);
    case 'edit-quotes': {
      const file = path.join(DATA_DIR, 'quotes.json');
      if (!fs.existsSync(file)) writeJson(file, { version: 1, quotes: activeQuotes().slice() });
      shell.openPath(file);
      return { ok: true };
    }
    case 'reset-quotes': {
      try { fs.rmSync(path.join(DATA_DIR, 'quotes.json'), { force: true }); } catch (_e) {}
      settings.quotes = null;
      pushState();
      return { ok: true };
    }
    case 'open-dir': shell.openPath(DATA_DIR); return { ok: true };
    case 'hide': sessionHidden = true; pushState(); return { ok: true };
    default: return { ok: false, reason: '未知动作：' + type };
  }
}

function registerIpc() {
  ipcMain.handle('gy:state', () => statePayload());
  ipcMain.handle('gy:portrait', (_e, id) => portrait(id));
  ipcMain.handle('gy:action', (_e, arg) => handleAction(arg));
  ipcMain.on('gy:l10n', (_e, info) => {
    console.log('[gyWidget] 补充词典生效：累计替换文本节点 ' + (info && info.replaced) + ' 个');
  });
  ipcMain.on('gy:ready', (_e, info) => {
    console.log('[gyWidget] 页内挂件就绪：角色图=' + (info && info.portraitState) +
      ' 额度行数=' + (info && info.quotaRows) + ' 语录=' + (info && info.quoteCount) + ' 条' +
      ' 工作台=' + (info && info.workbench));
    if (info && info.portraitState === 'error') console.warn('[gyWidget] 角色图加载失败：' + info.reason);
  });
  // 新加载的窗口立刻拿一份状态（页内挂件挂载时也会主动 pull，双保险）。
  app.on('web-contents-created', (_e, wc) => {
    wc.on('did-finish-load', () => pushStateTo(wc));
  });
}

function init() {
  console.log('[gyWidget] homedir=' + os.homedir() + ' DATA_DIR=' + DATA_DIR + '（页内 DOM 形态，无独立窗口）');
  fs.mkdirSync(path.join(DATA_DIR, 'characters'), { recursive: true });
  registerIpc();
  refreshQuota();
  timers.push(setInterval(refreshQuota, REFRESH_MS));
  app.on('before-quit', () => {
    timers.forEach((t) => clearInterval(t));
    timers = [];
  });
}

app.whenReady()
  .then(() => {
    try {
      init();
    } catch (e) {
      console.warn('[gyWidget] 初始化失败:', (e && e.stack) || e);
    }
  })
  .catch((e) => console.warn('[gyWidget] 等待 ready 失败:', (e && e.message) || e));
