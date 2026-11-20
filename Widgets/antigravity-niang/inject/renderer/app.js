'use strict';

const api = window.gyWidget;

const stage = document.getElementById('stage');
const bubble = document.getElementById('bubble');
const char = document.getElementById('char');
const portrait = document.getElementById('portrait');

let state = null;
let sequence = [];
let step = -1; // -1 表示收起
let quoteCursor = 0;
let drag = null;

const fmt = new Intl.DateTimeFormat('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });

function relativeFromIso(iso) {
  const at = Date.parse(iso);
  if (!Number.isFinite(at)) return '';
  let ms = at - Date.now();
  const later = ms >= 0;
  ms = Math.abs(ms);
  const days = Math.floor(ms / 86400000);
  const hours = Math.floor((ms % 86400000) / 3600000);
  const minutes = Math.floor((ms % 3600000) / 60000);
  const parts = [];
  if (days) parts.push(days + ' 天');
  if (hours) parts.push(hours + ' 小时');
  if (!days && minutes) parts.push(minutes + ' 分钟');
  if (!parts.length) parts.push('不到 1 分钟');
  return (later ? parts.join('、') + '后重置' : parts.join('、') + '前已过时');
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function buildSequence() {
  const pages = (state && state.quota.pages) || [];
  sequence = pages.map((_, index) => ({ kind: 'quota', index }));
  if (!pages.length) sequence.push({ kind: 'note' });
  sequence.push({ kind: 'quote' });
}

function quotaPageNode(page) {
  const wrap = el('div');
  page.forEach((row) => {
    const line = el('div', 'row');
    const top = el('div', 'row-top');
    const left = el('div');
    left.appendChild(el('div', 'row-label', row.label));
    if (row.group) left.appendChild(el('div', 'row-group', row.group));
    top.appendChild(left);
    const pct = row.fraction === null ? null : Math.round(row.fraction * 100);
    top.appendChild(el('div', 'row-value', pct === null ? '—' : pct + '%'));
    line.appendChild(top);

    const bar = el('div', 'bar');
    if (pct !== null) {
      if (pct <= 10) bar.classList.add('empty');
      else if (pct < 50) bar.classList.add('low');
      const fill = el('i');
      fill.style.width = Math.max(0, Math.min(100, pct)) + '%';
      bar.appendChild(fill);
    }
    line.appendChild(bar);

    if (row.resetTime) {
      const reset = el('div', 'row-reset', relativeFromIso(row.resetTime));
      reset.title = new Date(row.resetTime).toLocaleString('zh-CN') + (row.description ? '\n' + row.description : '');
      line.appendChild(reset);
    } else if (row.description) {
      line.appendChild(el('div', 'row-reset', row.description));
    }
    wrap.appendChild(line);
  });
  return wrap;
}

function render() {
  if (!state) return;
  document.documentElement.style.setProperty('--s', String(state.scale || 1));

  bubble.textContent = '';
  if (step < 0 || !sequence.length) {
    bubble.classList.add('hidden');
    return;
  }
  bubble.classList.remove('hidden');
  const item = sequence[Math.min(step, sequence.length - 1)];
  const pages = state.quota.pages || [];

  if (item.kind === 'quota' && pages[item.index]) {
    const head = el('div', 'bubble-head');
    head.appendChild(el('span', 'row-group', '额度 ' + (state.quota.source === 'snapshot' ? '（上次快照）' : '')));
    head.appendChild(el('span', 'page', (item.index + 1) + ' / ' + pages.length));
    bubble.appendChild(head);
    bubble.appendChild(quotaPageNode(pages[item.index]));
  } else if (item.kind === 'note') {
    bubble.appendChild(el('div', 'note', '读不到额度：' + (state.quota.reason || '宿主未运行或未登录')));
  } else {
    const quotes = state.quotes || [];
    if (quotes.length) {
      bubble.appendChild(el('div', 'quote', quotes[quoteCursor % quotes.length]));
    } else {
      bubble.appendChild(el('div', 'note', '语录为空，右键「编辑我的语录…」添加'));
    }
  }

  const foot = el('div', 'bubble-foot');
  const isLast = step >= sequence.length - 1;
  foot.appendChild(el('span', 'row-group', sourceLabel()));
  foot.appendChild(el('span', 'page', isLast ? '再点一下收起' : '继续点击翻页'));
  const stamp = state.quota.updatedAt ? fmt.format(new Date(state.quota.updatedAt)) : '—';
  foot.title = '来源：' + state.quota.source + '\n读取时间：' + stamp + '\n数据目录：' + state.dataDir;
  bubble.appendChild(foot);
}

function sourceLabel() {
  switch (state.quota.source) {
    case 'hub-api':
      return '本机接口 · ' + fmt.format(new Date(state.quota.updatedAt));
    case 'snapshot':
      return '上次快照 · ' + (state.quota.updatedAt ? fmt.format(new Date(state.quota.updatedAt)) : '未知');
    default:
      return '无读数';
  }
}

function openSequence() {
  buildSequence();
  quoteCursor += 1;
  step = 0;
  render();
}

function advance() {
  if (step < 0) return openSequence();
  if (step >= sequence.length - 1) {
    step = -1;
    return render();
  }
  step += 1;
  render();
}

function applyPortrait() {
  const url = state && state.activeUrl;
  if (!url) {
    portraitState = 'none';
    portrait.removeAttribute('src');
    char.classList.add('hidden-portrait');
    return;
  }
  char.classList.remove('hidden-portrait');
  if (portrait.getAttribute('src') !== url) {
    portraitState = 'pending';
    portrait.setAttribute('src', url);
  }
}

let portraitState = 'pending';
let reported = false;

function reportReady(force) {
  if (!state || (reported && !force)) return;
  reported = true;
  api.ready({
    portraitLoaded: portraitState === 'loaded',
    portraitState,
    portraitUrl: state.activeUrl || '',
    quotaGroups: state.quota.pages.reduce((n, page) => n + page.length, 0),
    quoteCount: (state.quotes || []).length,
  });
}

portrait.addEventListener('load', () => {
  portraitState = 'loaded';
  reportReady(true);
});

portrait.addEventListener('error', () => {
  portraitState = 'error';
  reportReady(true);
});

api.onState((next) => {
  state = next;
  applyPortrait();
  const wasOpen = step >= 0;
  buildSequence();
  if (!wasOpen) step = -1;
  render();
  reportReady();
});

// 命中测试：指针落在角色或气泡上才吃点击，其余透明区域穿透给宿主。
function interactiveFrom(target) {
  return !!(target && target.closest && target.closest('#char, #bubble'));
}

let ignoring = null;
function setInteractive(interactive) {
  const next = !interactive;
  if (next === ignoring) return;
  ignoring = next;
  api.setIgnoreMouse(next);
}

window.addEventListener('pointermove', (event) => {
  setInteractive(interactiveFrom(event.target));
  if (!drag || event.pointerId !== drag.pointerId) return;
  const dx = event.screenX - drag.lastX;
  const dy = event.screenY - drag.lastY;
  if (Math.abs(dx) < 1 && Math.abs(dy) < 1) return;
  drag.lastX = event.screenX;
  drag.lastY = event.screenY;
  if (!drag.moved && Math.abs(event.screenX - drag.startX) + Math.abs(event.screenY - drag.startY) > 4) {
    drag.moved = true;
    char.classList.add('dragging');
    setInteractive(true);
  }
  if (drag.moved) api.dragBy(dx, dy);
}, true);

char.addEventListener('pointerdown', (event) => {
  if (event.button !== 0) return;
  drag = { pointerId: event.pointerId, startX: event.screenX, startY: event.screenY, lastX: event.screenX, lastY: event.screenY, moved: false };
  char.setPointerCapture(event.pointerId);
  setInteractive(true);
});

function endDrag(event) {
  if (!drag || event.pointerId !== drag.pointerId) return;
  const moved = drag.moved;
  drag = null;
  char.classList.remove('dragging');
  if (char.hasPointerCapture && char.hasPointerCapture(event.pointerId)) char.releasePointerCapture(event.pointerId);
  if (!moved) advance();
}

char.addEventListener('pointerup', endDrag);
char.addEventListener('pointercancel', endDrag);

bubble.addEventListener('click', () => advance());
window.addEventListener('contextmenu', (event) => {
  event.preventDefault();
  setInteractive(true);
  api.contextMenu();
});

window.addEventListener('blur', () => {
  drag = null;
  char.classList.remove('dragging');
});

// 定时刷新重置倒计时，避免「x 小时后」长期不更新。
setInterval(() => {
  if (step >= 0) render();
}, 30000);
