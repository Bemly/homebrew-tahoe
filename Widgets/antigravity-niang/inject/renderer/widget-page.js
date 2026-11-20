// Gemini 娘挂件 · 页内 DOM 形态。
// 本文件由 inject-widget.mjs 追加进宿主自己的 dist/preload.js（标记块包裹），
// 与汉化引擎的面板同一条注入路径：preload 有 DOM 访问权，UI 直接长在宿主页面里。
// 不开独立窗口 → 跟窗/最小化/全屏/登录页隐藏全是页面内天然行为，也不会被宿主
// 「Reloading all windows」整窗重载劫持（重载后 preload 重新执行，挂件自动重建）。
//
// 门控：只在工作台挂载。判据复用汉化引擎面板的选择器
// [data-testid="agent-input-box"]（输入框）——登录/欢迎页没有这个节点。
'use strict';
(() => {
  const g = globalThis;
  if (g.__gyWidgetPageInstalled) return;
  try {
    if (g.top !== g.self) return; // 只挂主框架，plugin: 子框架不挂
    const loc = g.location;
    if (!loc || !/^https?:$/.test(loc.protocol)) return;
    if (!/^(127\.0\.0\.1|localhost)$/.test(loc.hostname)) return;
  } catch (_e) {
    return;
  }
  // preload 是 webpack bundle：electron 的导入别名是 electron_1（汉化引擎的
  // bridge 注入也依赖它）；require 兜底应对未打包形态。
  const ipc = (typeof electron_1 !== 'undefined' && electron_1 && electron_1.ipcRenderer) ||
    (typeof require === 'function' ? (() => { try { return require('electron').ipcRenderer; } catch (_e) { return null; } })() : null);
  if (!ipc) return;
  g.__gyWidgetPageInstalled = true;

  const CSS = `
#gyw-root{position:fixed;z-index:2147483647;pointer-events:none;display:flex;flex-direction:column;align-items:flex-end;gap:8px;font:12px/1.5 -apple-system,'PingFang SC',system-ui,sans-serif;color:#e8e8ec;user-select:none;-webkit-user-select:none}
#gyw-root *{box-sizing:border-box}
#gyw-bubble{pointer-events:auto;max-width:340px;background:rgba(22,22,28,.88);border:1px solid rgba(255,255,255,.14);border-radius:12px;padding:8px 10px;backdrop-filter:blur(8px);cursor:pointer;box-shadow:0 4px 18px rgba(0,0,0,.35)}
#gyw-bubble .gyw-title{font-weight:600;margin-bottom:4px;color:#fff}
#gyw-bubble .gyw-row{display:flex;justify-content:space-between;gap:10px;margin:2px 0}
#gyw-bubble .gyw-bar{height:4px;border-radius:2px;background:rgba(255,255,255,.16);margin:2px 0 6px}
#gyw-bubble .gyw-bar i{display:block;height:100%;border-radius:2px;background:#7aa2f7}
#gyw-bubble .gyw-dim{color:#9aa0ae}
#gyw-bubble .gyw-quote{white-space:pre-wrap}
#gyw-portrait{pointer-events:auto;display:block;height:180px;width:auto;cursor:grab;filter:drop-shadow(0 6px 14px rgba(0,0,0,.45))}
#gyw-portrait.gyw-drag{cursor:grabbing}
#gyw-menu{pointer-events:auto;position:fixed;display:none;min-width:190px;max-height:70vh;overflow:auto;background:rgba(28,28,34,.97);border:1px solid rgba(255,255,255,.16);border-radius:10px;padding:4px;box-shadow:0 8px 28px rgba(0,0,0,.5)}
#gyw-menu .gyw-item{padding:5px 10px;border-radius:6px;cursor:pointer;white-space:nowrap}
#gyw-menu .gyw-item:hover{background:rgba(122,162,247,.28)}
#gyw-menu .gyw-item.gyw-on{color:#7aa2f7}
#gyw-menu .gyw-sep{height:1px;margin:4px 6px;background:rgba(255,255,255,.14)}
#gyw-menu .gyw-head{padding:4px 10px 2px;color:#9aa0ae;font-size:11px}
`;

  let state = null;
  let root = null;
  let bubble = null;
  let portrait = null;
  let menu = null;
  let styleEl = null;
  let page = 0;
  let mounted = false;
  let portraitFor = null;
  let drag = null;

  const workbenchReady = () => !!document.querySelector('[data-testid="agent-input-box"]');

  function el(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function unmount() {
    if (root) root.remove();
    if (styleEl) styleEl.remove();
    if (menu) menu.remove();
    root = bubble = portrait = menu = styleEl = null;
    mounted = false;
  }

  function mount() {
    if (mounted) return;
    styleEl = el('style');
    styleEl.textContent = CSS;
    document.head.appendChild(styleEl);
    root = el('div');
    root.id = 'gyw-root';
    bubble = el('div');
    bubble.id = 'gyw-bubble';
    portrait = el('img');
    portrait.id = 'gyw-portrait';
    portrait.draggable = false;
    portrait.alt = '';
    root.appendChild(bubble);
    root.appendChild(portrait);
    document.body.appendChild(root);
    menu = el('div');
    menu.id = 'gyw-menu';
    document.body.appendChild(menu);
    mounted = true;

    bubble.addEventListener('click', () => { page += 1; renderBubble(); });
    root.addEventListener('contextmenu', (e) => { e.preventDefault(); e.stopPropagation(); openMenu(e.clientX, e.clientY); });
    portrait.addEventListener('pointerdown', (e) => {
      if (e.button !== 0) return;
      drag = { x: e.clientX, y: e.clientY, ox: state ? state.offset.x : 0, oy: state ? state.offset.y : 0 };
      portrait.classList.add('gyw-drag');
      portrait.setPointerCapture(e.pointerId);
      e.preventDefault();
    });
    portrait.addEventListener('pointermove', (e) => {
      if (!drag) return;
      const dx = e.clientX - drag.x;
      const dy = e.clientY - drag.y;
      applyOffset(drag.ox - dx, drag.oy - dy);
    });
    const endDrag = () => {
      if (!drag) return;
      drag = null;
      portrait.classList.remove('gyw-drag');
      if (state) ipc.invoke('gy:action', { type: 'offset', x: state.offset.x, y: state.offset.y });
    };
    portrait.addEventListener('pointerup', endDrag);
    portrait.addEventListener('pointercancel', endDrag);
    document.addEventListener('pointerdown', (e) => {
      if (menu && menu.style.display === 'block' && !menu.contains(e.target)) closeMenu();
    }, true);
    place();
    renderAll();
  }

  function applyOffset(x, y) {
    if (!state || !root) return;
    const r = root.getBoundingClientRect();
    const maxX = Math.max(0, window.innerWidth - r.width - 16);
    const maxY = Math.max(0, window.innerHeight - r.height - 16);
    state.offset = { x: Math.round(Math.min(maxX, Math.max(0, x))), y: Math.round(Math.min(maxY, Math.max(0, y))) };
    place();
  }

  function place() {
    if (!root || !state) return;
    const s = state.scale || 1;
    root.style.right = Math.round(28 * s + state.offset.x) + 'px';
    root.style.bottom = Math.round(20 * s + state.offset.y) + 'px';
    if (portrait) portrait.style.height = Math.round(180 * s) + 'px';
    if (bubble) bubble.style.maxWidth = Math.round(340 * s) + 'px';
  }

  function resetText() {
    const iso = state && state.quota && state.quota.updatedAt;
    return iso ? new Date(iso).toLocaleTimeString() : '';
  }

  function renderBubble() {
    if (!bubble || !state) return;
    bubble.textContent = '';
    const pages = (state.quota && state.quota.pages) || [];
    const quotes = state.quotes || [];
    const total = pages.length + 1;
    const idx = page % total;
    if (idx < pages.length) {
      bubble.appendChild(el('div', 'gyw-title', '额度剩余 · ' + (idx + 1) + '/' + pages.length));
      for (const row of pages[idx]) {
        const line = el('div', 'gyw-row');
        line.appendChild(el('span', null, row.label));
        line.appendChild(el('span', 'gyw-dim', row.fraction == null ? '—' : Math.round(row.fraction * 100) + '%'));
        bubble.appendChild(line);
        if (row.fraction != null) {
          const bar = el('div', 'gyw-bar');
          const fill = el('i');
          fill.style.width = Math.round(Math.min(1, Math.max(0, row.fraction)) * 100) + '%';
          bar.appendChild(fill);
          bubble.appendChild(bar);
        }
        if (row.resetTime) bubble.appendChild(el('div', 'gyw-dim', '重置 ' + row.resetTime));
      }
      if (state.quota.source !== 'hub-api') {
        bubble.appendChild(el('div', 'gyw-dim', '快照 ' + resetText() + (state.quota.reason ? ' · ' + state.quota.reason : '')));
      }
    } else if (quotes.length) {
      bubble.appendChild(el('div', 'gyw-quote', quotes[page % quotes.length]));
    } else {
      bubble.appendChild(el('div', 'gyw-dim', '右键换角色 / 导入图片'));
    }
  }

  function renderPortrait() {
    if (!portrait || !state) return;
    if (portraitFor === state.active) return;
    portraitFor = state.active;
    ipc.invoke('gy:portrait', state.active).then((res) => {
      if (!portrait) return;
      if (res && res.ok) {
        portrait.src = res.dataUrl;
        ipc.send('gy:ready', { portraitState: 'loaded', quotaRows: rowCount(), quoteCount: (state.quotes || []).length, workbench: workbenchReady() });
      } else {
        ipc.send('gy:ready', { portraitState: 'error', reason: res && res.reason, quotaRows: rowCount(), quoteCount: (state.quotes || []).length, workbench: workbenchReady() });
      }
    }).catch(() => {});
  }

  function rowCount() {
    return ((state && state.quota && state.quota.pages) || []).reduce((n, p) => n + p.length, 0);
  }

  function renderAll() {
    place();
    renderBubble();
    renderPortrait();
  }

  function closeMenu() {
    if (menu) menu.style.display = 'none';
  }

  function menuItem(label, on, opts) {
    const n = el('div', 'gyw-item' + (opts && opts.on ? ' gyw-on' : ''), label);
    n.addEventListener('click', (e) => { e.stopPropagation(); closeMenu(); on(); });
    menu.appendChild(n);
  }

  function openMenu(x, y) {
    if (!menu || !state) return;
    menu.textContent = '';
    menuItem('立即刷新额度', () => ipc.invoke('gy:action', { type: 'refresh' }));
    menuItem('导入角色图片…', () => ipc.invoke('gy:action', { type: 'import' }));
    menu.appendChild(el('div', 'gyw-head', '选择角色'));
    for (const c of state.characters || []) {
      menuItem(c.name + (c.kind === 'custom' ? '（导入）' : ''), () => ipc.invoke('gy:action', { type: 'select', id: c.id }), { on: c.id === state.active });
    }
    if ((state.removedCharacters || []).length) {
      menu.appendChild(el('div', 'gyw-head', '恢复已移除'));
      for (const c of state.removedCharacters) {
        menuItem(c.name, () => ipc.invoke('gy:action', { type: 'restore', id: c.id }));
      }
    }
    menu.appendChild(el('div', 'gyw-sep'));
    menu.appendChild(el('div', 'gyw-head', '大小'));
    for (const s of [0.75, 1, 1.25, 1.5, 2]) {
      menuItem(Math.round(s * 100) + '%', () => ipc.invoke('gy:action', { type: 'scale', value: s }), { on: Math.abs((state.scale || 1) - s) < 0.01 });
    }
    menu.appendChild(el('div', 'gyw-sep'));
    menuItem('编辑我的语录…', () => ipc.invoke('gy:action', { type: 'edit-quotes' }));
    menuItem('恢复内置语录', () => ipc.invoke('gy:action', { type: 'reset-quotes' }));
    menuItem('打开数据目录', () => ipc.invoke('gy:action', { type: 'open-dir' }));
    menu.appendChild(el('div', 'gyw-sep'));
    menuItem('本次运行隐藏挂件', () => ipc.invoke('gy:action', { type: 'hide' }));
    menu.style.display = 'block';
    const r = menu.getBoundingClientRect();
    menu.style.left = Math.max(8, Math.min(x, window.innerWidth - r.width - 8)) + 'px';
    menu.style.top = Math.max(8, Math.min(y, window.innerHeight - r.height - 8)) + 'px';
  }

  function evaluate() {
    const want = !!(state && !state.hidden && workbenchReady() && document.body);
    if (want && !mounted) mount();
    else if (!want && mounted) unmount();
    else if (mounted) renderAll();
  }

  ipc.on('gy:state', (_e, payload) => {
    state = payload;
    evaluate();
  });

  // SPA 切换（欢迎页 ↔ 工作台）不会重新执行 preload，靠观察 DOM 补门控。
  let debounce = null;
  const observer = new MutationObserver(() => {
    if (debounce) return;
    debounce = setTimeout(() => { debounce = null; evaluate(); }, 250);
  });
  const start = () => {
    observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
    setInterval(evaluate, 1500);
    ipc.invoke('gy:state').then((payload) => { state = payload; evaluate(); }).catch(() => {});
  };
  if (document.body) start();
  else document.addEventListener('DOMContentLoaded', start, { once: true });
})();
