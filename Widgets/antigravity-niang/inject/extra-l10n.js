// 补充汉化词典（bemly/tahoe 自有层，不改上游引擎）。
// 由 inject-widget.mjs 追加进宿主 dist/preload.js，标记块 __AGY_EXTRA_L10N_START__。
// 上游引擎的字典没覆盖模型名/元素代号/思考档位，这里补：
//   Gemini→哈基米；元素代号→周期表中文化学元素字（全表，含未来可能用的代号）；
//   Claude→克劳德，Opus→巨著、Sonnet→十四行诗、Haiku→俳句、Fable→神话 等；
//   思考档位 Low/Medium/High→低/中/高；New→新；Orchestrator→编排器。
// 只改**可见文本节点**，不碰 input/textarea/代码编辑器/终端——模型 id 与代码内容
// 保持英文原文，服务端拿到的仍是正确标识。
'use strict';
(() => {
  const g = globalThis;
  if (g.__gyExtraL10nInstalled) return;
  try {
    if (g.top !== g.self) return;
    const loc = g.location;
    if (!loc || !/^https?:$/.test(loc.protocol)) return;
    if (!/^(127\.0\.0\.1|localhost)$/.test(loc.hostname)) return;
  } catch (_e) {
    return;
  }
  g.__gyExtraL10nInstalled = true;

  // 化学元素全表（英文全名 → 中文元素字）。模型代号用的是全名（Neon/Argon/…）。
  const ELEMENTS = [
    ['Hydrogen', '氢'], ['Helium', '氦'], ['Lithium', '锂'], ['Beryllium', '铍'], ['Boron', '硼'],
    ['Carbon', '碳'], ['Nitrogen', '氮'], ['Oxygen', '氧'], ['Fluorine', '氟'], ['Neon', '氖'],
    ['Sodium', '钠'], ['Magnesium', '镁'], ['Aluminium', '铝'], ['Aluminum', '铝'], ['Silicon', '硅'],
    ['Phosphorus', '磷'], ['Sulfur', '硫'], ['Chlorine', '氯'], ['Argon', '氩'], ['Potassium', '钾'],
    ['Calcium', '钙'], ['Scandium', '钪'], ['Titanium', '钛'], ['Vanadium', '钒'], ['Chromium', '铬'],
    ['Manganese', '锰'], ['Iron', '铁'], ['Cobalt', '钴'], ['Nickel', '镍'], ['Copper', '铜'],
    ['Zinc', '锌'], ['Gallium', '镓'], ['Germanium', '锗'], ['Arsenic', '砷'], ['Selenium', '硒'],
    ['Bromine', '溴'], ['Krypton', '氪'], ['Rubidium', '铷'], ['Strontium', '锶'], ['Yttrium', '钇'],
    ['Zirconium', '锆'], ['Niobium', '铌'], ['Molybdenum', '钼'], ['Technetium', '锝'], ['Ruthenium', '钌'],
    ['Rhodium', '铑'], ['Palladium', '钯'], ['Silver', '银'], ['Cadmium', '镉'], ['Indium', '铟'],
    ['Tin', '锡'], ['Antimony', '锑'], ['Tellurium', '碲'], ['Iodine', '碘'], ['Xenon', '氙'],
    ['Caesium', '铯'], ['Cesium', '铯'], ['Barium', '钡'], ['Lanthanum', '镧'], ['Cerium', '铈'],
    ['Praseodymium', '镨'], ['Neodymium', '钕'], ['Promethium', '钷'], ['Samarium', '钐'], ['Europium', '铕'],
    ['Gadolinium', '钆'], ['Terbium', '铽'], ['Dysprosium', '镝'], ['Holmium', '钬'], ['Erbium', '铒'],
    ['Thulium', '铥'], ['Ytterbium', '镱'], ['Lutetium', '镥'], ['Hafnium', '铪'], ['Tantalum', '钽'],
    ['Tungsten', '钨'], ['Rhenium', '铼'], ['Osmium', '锇'], ['Iridium', '铱'], ['Platinum', '铂'],
    ['Gold', '金'], ['Mercury', '汞'], ['Thallium', '铊'], ['Lead', '铅'], ['Bismuth', '铋'],
    ['Polonium', '钋'], ['Astatine', '砹'], ['Radon', '氡'], ['Francium', '钫'], ['Radium', '镭'],
    ['Actinium', '锕'], ['Thorium', '钍'], ['Protactinium', '镤'], ['Uranium', '铀'], ['Neptunium', '镎'],
    ['Plutonium', '钚'], ['Americium', '镅'], ['Curium', '锔'], ['Berkelium', '锫'], ['Californium', '锎'],
    ['Einsteinium', '锿'], ['Fermium', '镄'], ['Mendelevium', '钔'], ['Nobelium', '锘'], ['Lawrencium', '铹'],
    ['Rutherfordium', '𬬻'], ['Dubnium', '𬭊'], ['Seaborgium', '𬭳'], ['Bohrium', '𬭛'], ['Hassium', '𬭶'],
    ['Meitnerium', '鿏'], ['Darmstadtium', '𫟼'], ['Roentgenium', '𬬭'], ['Copernicium', '鿔'], ['Nihonium', '鿭'],
    ['Flerovium', '𫓧'], ['Moscovium', '镆'], ['Livermorium', '𫟷'], ['Tennessine', '鿬'], ['Oganesson', '鿫'],
  ];
  const NAMES = [
    ['Gemini', '哈基米'], ['Claude', '克劳德'],
    ['Opus', '巨著'], ['Sonnet', '十四行诗'], ['Haiku', '俳句'], ['Fable', '神话'],
    ['Flash', '闪电'], ['Ultra', '极致'], ['Pro', '专业'], ['Max', '最大'],
    ['Lite', '轻量'], ['Nano', '纳米'], ['Mini', '迷你'],
    ['Medium', '中'], ['High', '高'], ['Low', '低'], ['Minimal', '极简'], ['Auto', '自动'],
    ['New', '新'], ['Orchestrator', '编排器'],
  ];

  const map = new Map();
  for (const [en, zh] of ELEMENTS.concat(NAMES)) map.set(en.toLowerCase(), zh);
  // 长词优先，避免短词先吃掉长词的前缀；\b 保证不伤 Leading/Golden 这类词。
  const keys = Array.from(map.keys()).sort((a, b) => b.length - a.length);
  const re = new RegExp('\\b(' + keys.join('|') + ')\\b', 'gi');

  const SKIP = 'script,style,textarea,input,select,code,pre,.monaco-editor,.xterm,[contenteditable="true"]';
  let replaced = 0;

  function translateNode(node) {
    const text = node.nodeValue;
    if (!text || !/[A-Za-z]/.test(text)) return;
    const next = text.replace(re, (m) => map.get(m.toLowerCase()) || m);
    if (next !== text) {
      node.nodeValue = next;
      replaced += 1;
    }
  }

  function walk(root) {
    if (!root) return;
    if (root.nodeType === 3) return translateNode(root);
    if (root.nodeType !== 1 && root.nodeType !== 9) return;
    if (root.nodeType === 1 && root.matches && root.matches(SKIP)) return;
    // 元素级 REJECT 会连子树一起剪掉：Monaco/终端里成千上万的文本节点不必逐个 closest。
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, {
      acceptNode(n) {
        if (n.nodeType === 1) return n.matches(SKIP) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_SKIP;
        return /[A-Za-z]/.test(n.nodeValue || '') ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
      },
    });
    let n;
    while ((n = walker.nextNode())) translateNode(n);
  }

  let pending = false;
  let lastReported = 0;
  function report() {
    if (pending || replaced === lastReported) return;
    pending = true;
    setTimeout(() => {
      pending = false;
      if (replaced === lastReported) return;
      lastReported = replaced;
      const ipc = (typeof electron_1 !== 'undefined' && electron_1 && electron_1.ipcRenderer) || null;
      if (ipc) {
        try { ipc.send('gy:l10n', { replaced }); } catch (_e) {}
      }
    }, 500);
  }

  const start = () => {
    walk(document.body);
    new MutationObserver((muts) => {
      for (const m of muts) {
        if (m.type === 'characterData') translateNode(m.target);
        else for (const n of m.addedNodes) walk(n);
      }
      report();
    }).observe(document.body || document.documentElement, { childList: true, subtree: true, characterData: true });
    report();
  };
  if (document.body) start();
  else document.addEventListener('DOMContentLoaded', start, { once: true });
})();
