#!/usr/bin/env node
// asar 命令行外壳，实现见 asar-lib.mjs。
//
//   asar.mjs list <app.asar>
//   asar.mjs cat  <app.asar> <asar内的路径>
//   asar.mjs pack <in.asar> <out.asar> [--add <本地文件或目录> <asar内前缀>]...
//                                       [--append <asar内文件> <本地片段文件>]...

import fs from 'node:fs';
import { addLocalTree, appendText, loadEntries, parseAsar, readEntry, writeAsar } from './asar-lib.mjs';

const USAGE = `用法：
  asar.mjs list <app.asar>
  asar.mjs cat  <app.asar> <asar内的路径>
  asar.mjs pack <in.asar> <out.asar> [--add <本地文件或目录> <asar内前缀>] [--append <asar内文件> <本地片段文件>]`;

function parseArgs(argv) {
  const [cmd, ...rest] = argv;
  const positional = [];
  const adds = [];
  const appends = [];
  for (let i = 0; i < rest.length; i++) {
    if (rest[i] === '--add') adds.push({ src: rest[++i], prefix: rest[++i] });
    else if (rest[i] === '--append') appends.push({ target: rest[++i], snippet: rest[++i] });
    else positional.push(rest[i]);
  }
  return { cmd, positional, adds, appends };
}

const { cmd, positional, adds, appends } = parseArgs(process.argv.slice(2));

if (cmd === 'list') {
  for (const [p] of loadEntries(parseAsar(positional[0]))) console.log(p);
} else if (cmd === 'cat') {
  const content = readEntry(parseAsar(positional[0]), positional[1]);
  if (!content) {
    console.error(`找不到 ${positional[1]}`);
    process.exit(1);
  }
  process.stdout.write(content);
} else if (cmd === 'pack') {
  const [inPath, outPath] = positional;
  if (!inPath || !outPath) {
    console.error(USAGE);
    process.exit(2);
  }
  const entries = loadEntries(parseAsar(inPath));
  for (const add of adds) addLocalTree(entries, add.src, add.prefix);
  for (const append of appends) appendText(entries, append.target, fs.readFileSync(append.snippet, 'utf8'));
  const stats = writeAsar(entries, outPath);
  console.log(`[asar] 写出 ${outPath}：${stats.entries} 条目 / packed ${stats.packedBytes} B / header ${stats.headerBytes} B`);
} else {
  console.error(USAGE);
  process.exit(2);
}
