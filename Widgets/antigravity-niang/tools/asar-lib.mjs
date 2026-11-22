// 零依赖 asar 读写库（不引 @electron/asar：本仓构建要能在没有 npm install 的前提下复现）。
//
// 帧格式取自两个已验证可被 Electron 加载的包（Google 原始包、汉化引擎写回的包），
// 二者结构逐字节一致：
//   u32@0 = 4 | u32@4 = jsonLen+8 | u32@8 = jsonLen+4 | u32@12 = jsonLen
//   @16   = header JSON，NUL 补齐到 4 字节边界
//   之后   = packed 文件内容顺序拼接（unpacked 条目不占空间，实体在 app.asar.unpacked/）
//
// 完整性说明：Antigravity 的 Info.plist 写了 ElectronAsarIntegrity，但实测汉化后
// 头哈希与 9 个被改文件的逐文件 integrity 全部失配、应用仍正常启动执行注入代码，
// 说明该 fuse 未启用。本库仍为每个 packed 条目重算 integrity，保持自洽。

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const BLOCK_SIZE = 4194304;
const EMPTY_SHA256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

export const align4 = (n) => (n + 3) & ~3;

export function integrityOf(content) {
  const blocks = [];
  for (let off = 0; off < content.length; off += BLOCK_SIZE) {
    blocks.push(crypto.createHash('sha256').update(content.subarray(off, off + BLOCK_SIZE)).digest('hex'));
  }
  return {
    algorithm: 'SHA256',
    hash: crypto.createHash('sha256').update(content).digest('hex'),
    blockSize: BLOCK_SIZE,
    blocks: blocks.length ? blocks : [EMPTY_SHA256],
  };
}

export function parseAsar(asarPath) {
  const buf = fs.readFileSync(asarPath);
  const jsonLen = buf.readUInt32LE(12);
  const header = JSON.parse(buf.subarray(16, 16 + jsonLen).toString('utf8').replace(/\0+$/, ''));
  return {
    buf,
    header,
    jsonLen,
    dataStart: 16 + align4(jsonLen),
    // unpacked 实体相对 asar 所在目录下的 app.asar.unpacked/
    unpackedDir: path.join(path.dirname(asarPath), 'app.asar.unpacked'),
  };
}

export function walkTree(node, prefix, visit) {
  for (const [name, entry] of Object.entries(node.files || {})) {
    const p = prefix ? `${prefix}/${name}` : name;
    if (entry.files) walkTree(entry, p, visit);
    else visit(p, entry);
  }
}

export function listEntries(asar) {
  const out = [];
  walkTree(asar.header, '', (p, entry) => out.push([p, entry]));
  return out;
}

export function readEntry(asar, entryPath) {
  let found = null;
  walkTree(asar.header, '', (p, entry) => {
    if (p === entryPath) found = entry;
  });
  if (!found) return null;
  if (found.unpacked) return fs.readFileSync(path.join(asar.unpackedDir, entryPath));
  const start = asar.dataStart + Number(found.offset);
  return Buffer.from(asar.buf.subarray(start, start + found.size));
}

export function loadEntries(asar) {
  const entries = new Map();
  for (const [p, entry] of listEntries(asar)) {
    const extras = {};
    if (entry.executable) extras.executable = true;
    if (entry.unpacked) {
      entries.set(p, { unpacked: true, size: entry.size, integrity: entry.integrity, ...extras });
    } else {
      const start = asar.dataStart + Number(entry.offset);
      entries.set(p, { content: Buffer.from(asar.buf.subarray(start, start + entry.size)), ...extras });
    }
  }
  return entries;
}

export function addLocalTree(entries, src, prefix) {
  const set = (asarPath, localPath) => entries.set(asarPath, { content: fs.readFileSync(localPath) });
  if (!fs.statSync(src).isDirectory()) {
    set(path.posix.join(prefix, path.basename(src)), src);
    return;
  }
  const step = (dir, asarDir) => {
    for (const name of fs.readdirSync(dir)) {
      const local = path.join(dir, name);
      const target = asarDir ? `${asarDir}/${name}` : name;
      if (fs.statSync(local).isDirectory()) step(local, target);
      else set(target, local);
    }
  };
  step(src, prefix);
}

export function appendText(entries, entryPath, snippet) {
  const entry = entries.get(entryPath);
  if (!entry) throw new Error(`asar 内找不到 ${entryPath}`);
  if (entry.unpacked) throw new Error(`${entryPath} 是 unpacked 条目，不能追加`);
  const text = entry.content.toString('utf8');
  const body = snippet.trim();
  // 用片段首行判重，构建脚本重复执行时不会叠加注入块。
  if (text.includes(body.split('\n')[0])) return false;
  entry.content = Buffer.from(text.replace(/\s+$/, '') + '\n\n' + body + '\n', 'utf8');
  return true;
}

export function replaceText(entries, entryPath, from, to, label) {
  const entry = entries.get(entryPath);
  if (!entry || entry.unpacked) throw new Error(`无法改写 ${entryPath}（条目不存在或为 unpacked）`);
  const text = entry.content.toString('utf8');
  if (from instanceof RegExp) {
    const flags = from.flags.includes('g') ? from.flags : `${from.flags}g`;
    const re = new RegExp(from.source, flags);
    const matches = [...text.matchAll(re)];
    if (matches.length !== 1) {
      throw new Error(`锚点 ${label || ''} 在 ${entryPath} 中出现 ${matches.length} 次（期望 1 次），拒绝打包`);
    }
    entry.content = Buffer.from(text.replace(re, () => to), 'utf8');
    return;
  }
  const count = text.split(from).length - 1;
  if (count !== 1) {
    throw new Error(`锚点 ${label || ''} 在 ${entryPath} 中出现 ${count} 次（期望 1 次），拒绝打包`);
  }
  entry.content = Buffer.from(text.replace(from, () => to), 'utf8');
}

export function writeAsar(entries, outPath) {
  const sorted = [...entries.entries()].sort((a, b) => (a[0] < b[0] ? -1 : 1));
  const tree = { files: {} };
  const blocks = [];
  let cursor = 0;

  const mkdirFor = (parts) => {
    let node = tree;
    for (const part of parts) {
      node.files = node.files || {};
      const next = node.files[part];
      if (next && !next.files) throw new Error(`asar 内 ${part} 已是文件，与目录路径冲突`);
      node = node.files[part] = next || { files: {} };
    }
    return node;
  };

  for (const [entryPath, entry] of sorted) {
    const parts = entryPath.split('/');
    const parent = mkdirFor(parts.slice(0, -1));
    const leaf = parts.at(-1);
    if (parent.files[leaf] && parent.files[leaf].files) throw new Error(`${entryPath} 与同名目录冲突`);

    if (entry.unpacked) {
      const out = { size: entry.size, unpacked: true };
      if (entry.integrity) out.integrity = entry.integrity;
      if (entry.executable) out.executable = true;
      parent.files[leaf] = out;
      continue;
    }
    parent.files[leaf] = {
      size: entry.content.length,
      offset: String(cursor),
      integrity: integrityOf(entry.content),
    };
    if (entry.executable) parent.files[leaf].executable = true;
    blocks.push(entry.content);
    cursor += entry.content.length;
  }

  const json = Buffer.from(JSON.stringify(tree), 'utf8');
  const paddedLen = align4(json.length);
  const padded = Buffer.alloc(paddedLen);
  json.copy(padded);
  const head = Buffer.alloc(16);
  // @4/@8 用的是**补齐后**长度，@12 是真实长度；Chromium 按 8+@4 定位数据区。
  // 若写成 jsonLen+8，只有 jsonLen 恰好 4 字节对齐时才凑巧正确 —— 只加文件的
  // 改动容易撞上，改已有文件就会把数据区读偏几位、package.json 变成垃圾。
  head.writeUInt32LE(4, 0);
  head.writeUInt32LE(paddedLen + 8, 4);
  head.writeUInt32LE(paddedLen + 4, 8);
  head.writeUInt32LE(json.length, 12);
  fs.writeFileSync(outPath, Buffer.concat([head, padded, ...blocks]));

  // 自证：写出的帧必须让 8+@4 与实际数据起点一致，否则立刻失败而不是产出半成品。
  const check = fs.readFileSync(outPath);
  const dataStart = 16 + paddedLen;
  if (check.readUInt32LE(4) + 8 !== dataStart || check.readUInt32LE(12) !== json.length) {
    throw new Error(`asar 头部自校验失败：@4+8=${check.readUInt32LE(4) + 8} 应为 ${dataStart}`);
  }
  return { entries: sorted.length, packedBytes: cursor, headerBytes: json.length, dataStart };
}
