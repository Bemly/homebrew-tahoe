#!/usr/bin/env node
// 把 Gemini 娘挂件与「禁自更新」改写注入（已汉化的）app.asar。
//
//   node tools/inject-widget.mjs --asar <app.asar> --root <Widgets/antigravity-niang>
//
// 顺序敏感：先确认宿主已被汉化引擎改过（dist/main.js 带 __AG_CTX_MONITOR_START__），
// 否则我们可能把挂件打到一个未经汉化验证的裸包上。

import fs from 'node:fs';
import path from 'node:path';
import { appendText, loadEntries, parseAsar, readEntry, replaceText, writeAsar } from './asar-lib.mjs';

const args = process.argv.slice(2);
function opt(name) {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : '';
}
const asarPath = opt('--asar');
const root = opt('--root');
if (!asarPath || !root) {
  console.error('用法：inject-widget.mjs --asar <app.asar> --root <Widgets/antigravity-niang>');
  process.exit(2);
}

const UPDATE_DISABLED_MARK = '自动更新已由 bemly/tahoe 补丁禁用';
const WIDGET_MARK = '__AGY_WIDGET_START__';
const CN_MARK = '__AG_CTX_MONITOR_START__';

const files = [
  ['inject/gyWidgetMain.js', 'dist/gyWidgetMain.js'],
  ['inject/widget-preload.js', 'dist/gyWidget/widget-preload.js'],
  ['inject/renderer', 'dist/gyWidget/renderer'],
  ['characters', 'dist/gyWidget/characters'],
  ['assets/quotes.json', 'dist/gyWidget/assets/quotes.json'],
];

const updaterPatches = [
  {
    label: 'startAutoUpdateChecks 短路',
    from: `function startAutoUpdateChecks() {\n    if (periodicCheckInterval) {`,
    to: `function startAutoUpdateChecks() {\n` +
      `    // [antigravity-cn] 不排定时器、不发起检查：更新权归 bemly/tahoe 的 cask。\n` +
      `    return;\n` +
      `}\n` +
      `function startAutoUpdateChecksOriginal() {\n    if (periodicCheckInterval) {`,
  },
  {
    label: 'checkForUpdates 短路',
    from: `function checkForUpdates(isManual = false) {\n    isManualCheck = isManual;`,
    to: `function checkForUpdates(isManual = false) {\n` +
      `    // [antigravity-cn] 更新权归 bemly/tahoe 的 cask：自更新会用官方包覆盖\n` +
      `    // 打过补丁的 app.asar，让汉化与挂件静默消失，因此这里短路掉唯一检查入口。\n` +
      `    console.log('[AutoUpdater] ${UPDATE_DISABLED_MARK}');\n` +
      `    return;\n` +
      `}\n` +
      `function checkForUpdatesOriginal(isManual = false) {\n    isManualCheck = isManual;`,
  },
  { label: 'autoDownload', from: 'autoUpdater.autoDownload = true;', to: 'autoUpdater.autoDownload = false;' },
  { label: 'autoInstallOnAppQuit', from: 'autoUpdater.autoInstallOnAppQuit = electron_1.app.isPackaged;', to: 'autoUpdater.autoInstallOnAppQuit = false;' },
];

const parsed = parseAsar(asarPath);
const entries = loadEntries(parsed);

const main = entries.get('dist/main.js');
if (!main) throw new Error('asar 内没有 dist/main.js，包结构不符合预期');
if (!main.content.toString('utf8').includes(CN_MARK)) {
  throw new Error('dist/main.js 里没有汉化注入标记 —— 请先跑汉化引擎，再注入挂件');
}

for (const patch of updaterPatches) {
  replaceText(entries, 'dist/updater.js', patch.from, patch.to, patch.label);
}

for (const [local, target] of files) {
  const src = path.join(root, local);
  if (!fs.existsSync(src)) throw new Error(`缺少素材：${src}`);
  if (fs.statSync(src).isDirectory()) {
    let count = 0;
    const walk = (dir, prefix) => {
      for (const name of fs.readdirSync(dir)) {
        const full = path.join(dir, name);
        const asarEntry = `${prefix}/${name}`;
        if (fs.statSync(full).isDirectory()) walk(full, asarEntry);
        else {
          entries.set(asarEntry, { content: fs.readFileSync(full) });
          count += 1;
        }
      }
    };
    walk(src, target);
    console.log(`[inject] ${local} → ${target}/（${count} 个文件）`);
  } else {
    entries.set(target, { content: fs.readFileSync(src) });
    console.log(`[inject] ${local} → ${target}`);
  }
}

const snippet = [
  `'${WIDGET_MARK}';`,
  `try{require('./gyWidgetMain.js');}catch(_e){}`,
  `'__AGY_WIDGET_END__';`,
].join('\n');
appendText(entries, 'dist/main.js', snippet);

const stats = writeAsar(entries, asarPath);
console.log(`[inject] 写回 ${asarPath}：${stats.entries} 条目 / packed ${stats.packedBytes} B`);

// 复验：重新解析刚写出的包，确认三处结果都在（失败就中止构建，绝不产出半成品）。
const verify = parseAsar(asarPath);
const mainText = readEntry(verify, 'dist/main.js').toString('utf8');
const updaterText = readEntry(verify, 'dist/updater.js').toString('utf8');
const checks = [
  ['main.js 含挂件注入块', mainText.includes(WIDGET_MARK) && mainText.includes("require('./gyWidgetMain.js')")],
  ['main.js 仍含汉化注入块', mainText.includes(CN_MARK)],
  ['updater.js 已禁自更新', updaterText.includes(UPDATE_DISABLED_MARK) && updaterText.includes('autoDownload = false')],
  ['挂件主模块存在', readEntry(verify, 'dist/gyWidgetMain.js') !== null],
  ['预加载脚本存在', readEntry(verify, 'dist/gyWidget/widget-preload.js') !== null],
  ['渲染层存在', readEntry(verify, 'dist/gyWidget/renderer/index.html') !== null],
  ['角色清单存在', readEntry(verify, 'dist/gyWidget/characters/characters.json') !== null],
  ['默认立绘存在', readEntry(verify, 'dist/gyWidget/characters/gemini_default.png') !== null],
  ['语录存在', readEntry(verify, 'dist/gyWidget/assets/quotes.json') !== null],
];
for (const [label, ok] of checks) {
  console.log(`${ok ? '[ok]  ' : '[FAIL]'} ${label}`);
  if (!ok) process.exit(1);
}
