// Gemini 娘挂件 · WKWebView 页内版（GitHub Copilot 桌面版 / Tauri）。
// 由 build.sh 把下面的 PAYLOAD 占位符替换成 {characters:[{id,name,dataUrl}], quotes:[…]}
// 后经 GyWidgetCN.dylib 以 WKUserScript 注入。无 Electron IPC：设置与导入图存
// localStorage，导入走 <input type=file> + FileReader（WKWebView 原生文件面板）。
// 注意：本文件里**不要**再出现占位符的字面量（注释里也不行）——build.sh 用
// replaceAll 替换，注释里出现一次就会把 4MB 的 JSON 灌进注释里。
'use strict';
(() => {
  const g = globalThis;
  if (g.__gyPetInstalled) return;
  try {
    if (g.top !== g.self) return;
  } catch (_e) {
    return;
  }
  g.__gyPetInstalled = true;
  const PAYLOAD = __PAYLOAD__;
  const LS_KEY = 'gyPetSettings.v1';

  const CSS = `
#gyw-root{position:fixed;z-index:2147483647;pointer-events:none;display:flex;flex-direction:column;align-items:flex-end;gap:8px;font:12px/1.5 -apple-system,'PingFang SC',system-ui,sans-serif;color:#e8e8ec;user-select:none;-webkit-user-select:none}
#gyw-root *{box-sizing:border-box}
#gyw-bubble{pointer-events:auto;max-width:320px;background:rgba(22,22,28,.88);border:1px solid rgba(255,255,255,.14);border-radius:12px;padding:8px 10px;cursor:pointer;box-shadow:0 4px 18px rgba(0,0,0,.35)}
#gyw-bubble .gyw-quote{white-space:pre-wrap}
#gyw-bubble .gyw-dim{color:#9aa0ae}
#gyw-portrait{pointer-events:auto;display:block;height:170px;width:auto;cursor:grab;filter:drop-shadow(0 6px 14px rgba(0,0,0,.45))}
#gyw-portrait.gyw-drag{cursor:grabbing}
#gyw-menu{pointer-events:auto;position:fixed;display:none;min-width:180px;max-height:70vh;overflow:auto;background:rgba(28,28,34,.97);border:1px solid rgba(255,255,255,.16);border-radius:10px;padding:4px;box-shadow:0 8px 28px rgba(0,0,0,.5)}
#gyw-menu .gyw-item{padding:5px 10px;border-radius:6px;cursor:pointer;white-space:nowrap}
#gyw-menu .gyw-item:hover{background:rgba(122,162,247,.28)}
#gyw-menu .gyw-item.gyw-on{color:#7aa2f7}
#gyw-menu .gyw-sep{height:1px;margin:4px 6px;background:rgba(255,255,255,.14)}
#gyw-menu .gyw-head{padding:4px 10px 2px;color:#9aa0ae;font-size:11px}
#gyw-file{display:none}
`;

  let settings = load();
  let root = null, bubble = null, portrait = null, menu = null, styleEl = null, fileInput = null;
  let mounted = false, page = 0, drag = null, hidden = false;

  function load() {
    try {
      const s = JSON.parse(localStorage.getItem(LS_KEY) || '{}');
      return {
        character: typeof s.character === 'string' ? s.character : (PAYLOAD.characters[0] || {}).id,
        scale: Number.isFinite(+s.scale) ? Math.min(2, Math.max(0.6, +s.scale)) : 1,
        offset: { x: Number(s.offset && s.offset.x) || 0, y: Number(s.offset && s.offset.y) || 0 },
        imported: Array.isArray(s.imported) ? s.imported : [],
      };
    } catch (_e) {
      return { character: (PAYLOAD.characters[0] || {}).id, scale: 1, offset: { x: 0, y: 0 }, imported: [] };
    }
  }
  function save() {
    try {
      localStorage.setItem(LS_KEY, JSON.stringify(settings));
      return true;
    } catch (_e) {
      return false; // localStorage 满（导入图太大）时不崩，菜单里提示
    }
  }
  function characters() {
    return PAYLOAD.characters.concat(settings.imported);
  }
  function active() {
    return characters().find((c) => c.id === settings.character) || characters()[0];
  }
  // 工作台门控：Copilot 主界面有输入框（textarea / contenteditable），登录页没有。
  const ready = () => !!document.querySelector('textarea,[contenteditable="true"]');

  function el(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }
  function unmount() {
    for (const n of [root, styleEl, menu, fileInput]) if (n) n.remove();
    root = bubble = portrait = menu = styleEl = fileInput = null;
    mounted = false;
  }
  function mount() {
    if (mounted) return;
    styleEl = el('style');
    styleEl.textContent = CSS;
    document.head.appendChild(styleEl);
    root = el('div'); root.id = 'gyw-root';
    bubble = el('div'); bubble.id = 'gyw-bubble';
    portrait = el('img'); portrait.id = 'gyw-portrait'; portrait.draggable = false; portrait.alt = '';
    root.appendChild(bubble); root.appendChild(portrait);
    document.body.appendChild(root);
    menu = el('div'); menu.id = 'gyw-menu'; document.body.appendChild(menu);
    fileInput = el('input'); fileInput.id = 'gyw-file'; fileInput.type = 'file';
    fileInput.accept = 'image/png,image/jpeg,image/gif,image/webp,image/avif,image/bmp';
    document.body.appendChild(fileInput);
    mounted = true;

    bubble.addEventListener('click', () => { page += 1; renderBubble(); });
    root.addEventListener('contextmenu', (e) => { e.preventDefault(); e.stopPropagation(); openMenu(e.clientX, e.clientY); });
    portrait.addEventListener('pointerdown', (e) => {
      if (e.button !== 0) return;
      drag = { x: e.clientX, y: e.clientY, ox: settings.offset.x, oy: settings.offset.y };
      portrait.classList.add('gyw-drag');
      portrait.setPointerCapture(e.pointerId);
      e.preventDefault();
    });
    portrait.addEventListener('pointermove', (e) => {
      if (!drag) return;
      const r = root.getBoundingClientRect();
      const maxX = Math.max(0, window.innerWidth - r.width - 16);
      const maxY = Math.max(0, window.innerHeight - r.height - 16);
      settings.offset.x = Math.round(Math.min(maxX, Math.max(0, drag.ox - (e.clientX - drag.x))));
      settings.offset.y = Math.round(Math.min(maxY, Math.max(0, drag.oy - (e.clientY - drag.y))));
      place();
    });
    const endDrag = () => { if (drag) { drag = null; portrait.classList.remove('gyw-drag'); save(); } };
    portrait.addEventListener('pointerup', endDrag);
    portrait.addEventListener('pointercancel', endDrag);
    fileInput.addEventListener('change', () => {
      const f = fileInput.files && fileInput.files[0];
      fileInput.value = '';
      if (!f) return;
      const rd = new FileReader();
      rd.onload = () => {
        const id = 'custom-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
        settings.imported.push({ id, name: f.name.replace(/\.[^.]+$/, ''), dataUrl: String(rd.result) });
        settings.character = id;
        if (!save()) {
          settings.imported.pop();
          // 不用 alert()：WKWebView 的 alert 要靠宿主实现 UIDelegate，Tauri 未必接，
          // 弹不出来就等于静默失败。直接把提示写进气泡（页面内自有 DOM，一定看得见）。
          settings.character = (PAYLOAD.characters[0] || {}).id;
          renderAll();
          if (bubble) {
            bubble.textContent = '';
            bubble.appendChild(el('div', 'gyw-quote',
              '导入失败：本地存储空间不足（localStorage 约 5MB）。先在右键菜单里移除一些导入的角色，或换更小的图片。'));
          }
          return;
        }
        renderAll();
      };
      rd.readAsDataURL(f);
    });
    document.addEventListener('pointerdown', (e) => {
      if (menu && menu.style.display === 'block' && !menu.contains(e.target)) menu.style.display = 'none';
    }, true);
    place();
    renderAll();
  }
  function place() {
    if (!root) return;
    const s = settings.scale;
    root.style.right = Math.round(24 * s + settings.offset.x) + 'px';
    root.style.bottom = Math.round(18 * s + settings.offset.y) + 'px';
    if (portrait) portrait.style.height = Math.round(170 * s) + 'px';
  }
  function renderBubble() {
    if (!bubble) return;
    bubble.textContent = '';
    const q = PAYLOAD.quotes || [];
    if (q.length) bubble.appendChild(el('div', 'gyw-quote', q[page % q.length]));
    else bubble.appendChild(el('div', 'gyw-dim', '右键换角色 / 导入图片'));
  }
  function renderAll() {
    place();
    renderBubble();
    const c = active();
    if (portrait && c) portrait.src = c.dataUrl;
  }
  function item(label, on, opts) {
    const n = el('div', 'gyw-item' + (opts && opts.on ? ' gyw-on' : ''), label);
    n.addEventListener('click', (e) => { e.stopPropagation(); menu.style.display = 'none'; on(); });
    menu.appendChild(n);
  }
  function openMenu(x, y) {
    if (!menu) return;
    menu.textContent = '';
    menu.appendChild(el('div', 'gyw-head', '选择角色'));
    for (const c of characters()) {
      item(c.name + (settings.imported.some((i) => i.id === c.id) ? '（导入）' : ''),
        () => { settings.character = c.id; save(); renderAll(); }, { on: c.id === settings.character });
    }
    item('导入角色图片…', () => fileInput.click());
    if (settings.imported.length) {
      menu.appendChild(el('div', 'gyw-sep'));
      menu.appendChild(el('div', 'gyw-head', '移除导入的角色'));
      for (const c of settings.imported.slice()) {
        item(c.name, () => {
          settings.imported = settings.imported.filter((i) => i.id !== c.id);
          if (settings.character === c.id) settings.character = (PAYLOAD.characters[0] || {}).id;
          save(); renderAll();
        });
      }
    }
    menu.appendChild(el('div', 'gyw-sep'));
    menu.appendChild(el('div', 'gyw-head', '大小'));
    for (const s of [0.75, 1, 1.25, 1.5, 2]) {
      item(Math.round(s * 100) + '%', () => { settings.scale = s; save(); place(); },
        { on: Math.abs(settings.scale - s) < 0.01 });
    }
    menu.appendChild(el('div', 'gyw-sep'));
    item('本次运行隐藏挂件', () => { hidden = true; unmount(); });
    menu.style.display = 'block';
    const r = menu.getBoundingClientRect();
    menu.style.left = Math.max(8, Math.min(x, window.innerWidth - r.width - 8)) + 'px';
    menu.style.top = Math.max(8, Math.min(y, window.innerHeight - r.height - 8)) + 'px';
  }
  function evaluate() {
    const want = !hidden && ready() && document.body;
    if (want && !mounted) mount();
    else if (!want && mounted) unmount();
  }
  let deb = null;
  const start = () => {
    evaluate();
    new MutationObserver(() => {
      if (deb) return;
      deb = setTimeout(() => { deb = null; evaluate(); }, 300);
    }).observe(document.body || document.documentElement, { childList: true, subtree: true });
    setInterval(evaluate, 1500);
  };
  if (document.body) start();
  else document.addEventListener('DOMContentLoaded', start, { once: true });
})();
