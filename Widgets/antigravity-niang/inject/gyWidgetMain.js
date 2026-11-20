'use strict';

// Gemini 娘挂件（macOS 移植版）宿主侧模块。
// 构建脚本把它写入 app.asar 的 dist/gyWidgetMain.js，并在 dist/main.js 末尾以
// try/catch 包裹 require —— 任何异常都不允许影响 Antigravity 本体启动。
//
// 只用 Electron 公开 API（BaseWindow/BrowserWindow 枚举 + 窗口事件 + 定时器），
// 不包宿主内部函数：宿主升级改了 dist 内部形状时，挂件顶多是跟不准，不会崩宿主。

const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const crypto = require('crypto');
const { URL, pathToFileURL } = require('url');
const electron = require('electron');

const { app, dialog, ipcMain, shell, BrowserWindow } = electron;
const BaseWindow = electron.BaseWindow || BrowserWindow;

const WIDGET_DIR = path.join(__dirname, 'gyWidget');
const APP_NAME = 'GeminiNiangWidget';
// 与上游 Windows 挂件同名：上游配套插件的额度 MCP 读的就是本目录下的
// status.json，保持形状兼容它才能继续可用。
const DATA_DIR = path.join(os.homedir(), 'Library', 'Application Support', APP_NAME);
const QUOTA_PATH = '/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary';
const ROWS_PER_PAGE = 3;
const REFRESH_MS = 60000;
const FOLLOW_MS = 200;
const IMPORT_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.avif', '.bmp'];
const SCALE_MIN = 0.6;
const SCALE_MAX = 2;

const BUILTIN = readJson(path.join(WIDGET_DIR, 'characters', 'characters.json'), { characters: [], default: '' });
const BUILTIN_QUOTES = readJson(path.join(WIDGET_DIR, 'assets', 'quotes.json'), { quotes: [] }).quotes || [];

let overlay = null;
let hostWindow = null;
let timers = [];
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
    url: pathToFileURL(path.join(WIDGET_DIR, 'characters', c.file)).href,
  })).filter((c) => c.url);

  const custom = customCatalog().characters
    .filter(isOwnCustom)
    .filter((c) => fs.existsSync(path.join(customDir(c), c.file)))
    .map((c) => ({
      id: c.id,
      name: c.name || '自定义角色',
      kind: c.removed ? 'removed' : 'custom',
      url: pathToFileURL(path.join(customDir(c), c.file)).href,
    }));

  return { shown: builtin.concat(custom.filter((c) => c.kind === 'custom')), removed: custom.filter((c) => c.kind === 'removed') };
}

function characterUrl(id) {
  const { shown, removed } = characterList();
  const hit = shown.find((c) => c.id === id) || removed.find((c) => c.id === id) || shown.find((c) => c.id === settings.character);
  return hit ? hit.url : null;
}

function importCharacter() {
  const picked = dialog.showOpenDialogSync(overlay || undefined, {
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
// 覆盖窗：贴在宿主窗口右下角的透明浮窗
// ---------------------------------------------------------------------------

function widgetSize() {
  return { w: Math.round(600 * settings.scale), h: Math.round(300 * settings.scale) };
}

function isLive(win) {
  try {
    return win && win.isDestroyed() === false;
  } catch (_e) {
    return false;
  }
}

// 关键：必须排掉浮窗自己，否则getAllWindows 会把挂件当成宿主，跟窗自指。
function pickHost() {
  const candidates = [];
  for (const win of BaseWindow.getAllWindows()) {
    if (!isLive(win) || win === overlay) continue;
    try {
      if (!win.isVisible() || win.isMinimized()) continue;
    } catch (_e) {
      continue;
    }
    candidates.push(win);
  }
  if (!candidates.length) return null;
  const focused = candidates.find((w) => {
    try { return w.isFocused(); } catch (_e) { return false; }
  });
  return focused || candidates[candidates.length - 1];
}

function clamp(value, lo, hi) {
  if (hi < lo) return lo;
  return Math.min(hi, Math.max(lo, value));
}

function placeOverlay() {
  if (!isLive(overlay)) return;
  const host = pickHost();
  if (!host) {
    if (overlay.isVisible()) overlay.hide();
    hostWindow = null;
    return;
  }
  hostWindow = host;
  const bounds = typeof host.getContentBounds === 'function' ? host.getContentBounds() : host.getBounds();
  const { w, h } = widgetSize();
  const anchorX = bounds.x + bounds.width - w - Math.round(28 * settings.scale);
  const anchorY = bounds.y + bounds.height - h - Math.round(20 * settings.scale);
  // 锚点 + 用户拖动偏移，并夹在宿主可视区内：拖动不会被跟位弹回，也不会丢出屏幕。
  const x = Math.round(clamp(anchorX + settings.offset.x, bounds.x + 4, bounds.x + bounds.width - w - 4));
  const y = Math.round(clamp(anchorY + settings.offset.y, bounds.y + 4, bounds.y + bounds.height - h - 4));
  if (!overlay.isVisible()) overlay.showInactive();
  if (overlay.getSize().join() !== [w, h].join()) overlay.setSize(w, h);
  if (overlay.getPosition().join() !== [x, y].join()) overlay.setPosition(x, y);
}

function dragBy(dx, dy) {
  if (!isLive(overlay)) return;
  const host = pickHost();
  const bounds = host ? (typeof host.getContentBounds === 'function' ? host.getContentBounds() : host.getBounds()) : null;
  const { w, h } = widgetSize();
  settings.offset.x = Math.round(clamp(settings.offset.x + dx, -Math.max(0, bounds ? bounds.width - w - 8 : 4000), 0));
  settings.offset.y = Math.round(clamp(settings.offset.y + dy, -Math.max(0, bounds ? bounds.height - h - 8 : 4000), 0));
  saveSettings();
  placeOverlay();
}

function createOverlay() {
  const { w, h } = widgetSize();
  overlay = new BrowserWindow({
    width: w,
    height: h,
    show: false,
    frame: false,
    transparent: true,
    resizable: false,
    movable: true,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    skipTaskbar: true,
    hasShadow: false,
    alwaysOnTop: true,
    webPreferences: {
      preload: path.join(WIDGET_DIR, 'widget-preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });
  overlay.setMenuBarVisibility(false);
  overlay.setAlwaysOnTop(true, 'floating');
  try {
    overlay.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  } catch (_e) {}
  // 默认穿透，由渲染层在指针落到角色/气泡时按需收回，避免透明区域吃掉宿主点击。
  overlay.setIgnoreMouseEvents(true, { forward: true });
  overlay.loadFile(path.join(WIDGET_DIR, 'renderer', 'index.html'));
  overlay.on('closed', () => { overlay = null; });

  ['move', 'resize', 'minimize', 'restore', 'show', 'hide', 'focus', 'blur'].forEach((event) => {
    app.on('browser-window-' + event, () => placeOverlay());
  });
  // 宿主用 BaseWindow + WebContentsView，事件面不完全一致，定时器兜底跟位。
  timers.push(setInterval(placeOverlay, FOLLOW_MS));
  placeOverlay();
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
  placeOverlay();
}

function pushState() {
  if (!isLive(overlay)) return;
  pushStateTo(overlay.webContents);
}

// ---------------------------------------------------------------------------
// IPC 与右键菜单
// ---------------------------------------------------------------------------

function reply(event, channel, payload) {
  if (event && event.sender && !event.sender.isDestroyed()) event.sender.send(channel, payload);
}

function showContextMenu() {
  const { shown, removed } = characterList();
  const template = [
    { label: '立即刷新额度', click: () => refreshQuota() },
    { label: '导入角色图片…', click: () => importCharacter() },
    {
      label: '选择角色',
      submenu: shown.map((c) => ({
        label: c.name + (c.kind === 'custom' ? '（导入）' : ''),
        type: 'radio',
        checked: c.id === settings.character,
        click: () => setCharacter(c.id),
      })),
    },
  ];

  if (removed.length) {
    template.push({
      label: '恢复已移除的角色',
      submenu: removed.map((c) => ({ label: c.name, click: () => restoreCharacter(c.id) })),
    });
  }

  template.push(
    { type: 'separator' },
    {
      label: '大小',
      submenu: [0.75, 1, 1.25, 1.5, 2].map((s) => ({
        label: Math.round(s * 100) + '%',
        type: 'radio',
        checked: Math.abs(settings.scale - s) < 0.01,
        click: () => setScale(s),
      })),
    },
    { type: 'separator' },
    {
      label: '编辑我的语录…',
      click: () => {
        const file = path.join(DATA_DIR, 'quotes.json');
        if (!fs.existsSync(file)) writeJson(file, { version: 1, quotes: activeQuotes().slice() });
        shell.openPath(file);
      },
    },
    {
      label: '恢复内置语录',
      click: () => {
        try { fs.rmSync(path.join(DATA_DIR, 'quotes.json'), { force: true }); } catch (_e) {}
        settings.quotes = null;
        pushState();
      },
    },
    { label: '打开数据目录', click: () => shell.openPath(DATA_DIR) },
    { type: 'separator' },
    { label: '本次运行隐藏挂件', click: () => { if (isLive(overlay)) overlay.hide(); } }
  );

  Menu.buildFromTemplate(template).popup({ window: overlay });
}

function registerIpc() {
  ipcMain.handle('gy:state', (event) => { pushStateTo(event.sender); return true; });
  ipcMain.on('gy:select-character', (_e, id) => { if (typeof id === 'string' && id) setCharacter(id); });
  ipcMain.on('gy:set-scale', (_e, scale) => setScale(scale));
  ipcMain.on('gy:refresh-quota', () => refreshQuota());
  ipcMain.on('gy:import-character', (event, channel) => reply(event, channel, importCharacter()));
  ipcMain.on('gy:remove-character', (event, arg) => reply(event, arg && arg.channel, removeCharacter(arg && arg.id)));
  ipcMain.on('gy:restore-character', (event, arg) => reply(event, arg && arg.channel, restoreCharacter(arg && arg.id)));
  ipcMain.on('gy:context-menu', () => showContextMenu());
  ipcMain.on('gy:renderer-ready', (_e, info) => {
    const line = '[gyWidget] 渲染层就绪：角色图=' + (info && info.portraitState) +
      ' 额度行数=' + (info && info.quotaGroups) + ' 语录=' + (info && info.quoteCount) + ' 条';
    console.log(line);
    if (info && info.portraitState === 'error') {
      console.warn('[gyWidget] 角色图加载失败：' + info.portraitUrl);
    }
  });
  ipcMain.on('gy:drag-by', (_e, arg) => {
    if (!arg) return;
    const dx = Number(arg.dx);
    const dy = Number(arg.dy);
    if (Number.isFinite(dx) && Number.isFinite(dy)) dragBy(dx, dy);
  });
  ipcMain.on('gy:set-ignore-mouse', (_e, ignore) => {
    if (!isLive(overlay)) return;
    if (ignore) overlay.setIgnoreMouseEvents(true, { forward: true });
    else overlay.setIgnoreMouseEvents(false);
  });
}

function pushStateTo(webContents) {
  if (!webContents || webContents.isDestroyed()) return;
  const { shown, removed } = characterList();
  webContents.send('gy:state', {
    characters: shown,
    removedCharacters: removed,
    active: settings.character,
    activeUrl: characterUrl(settings.character),
    scale: settings.scale,
    quota: { source: quota.source, updatedAt: quota.updatedAt, reason: quota.reason, pages: quotaPages() },
    quotes: activeQuotes(),
    dataDir: DATA_DIR,
  });
}

function init() {
  console.log('[gyWidget] homedir=' + os.homedir() + ' DATA_DIR=' + DATA_DIR);
  fs.mkdirSync(path.join(DATA_DIR, 'characters'), { recursive: true });
  registerIpc();
  createOverlay();
  if (overlay && !overlay.isDestroyed()) {
    console.log('[gyWidget] 浮窗已创建', JSON.stringify(overlay.getBounds()), '角色=' + settings.character);
  }
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
