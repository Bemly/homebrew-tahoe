import { readdir, readFile } from "node:fs/promises";
import path from "node:path";

const CALL_METHODS = new Set([
  "desc", "homepage", "url", "version", "license", "depends_on", "uses_from_macos",
  "revision", "keg_only", "name", "arch", "sha256", "auto_updates", "conflicts_with",
  "deprecate!", "disable!",
]);

const FORMULA_CONTEXTS = new Set(["class", "stable", "on_macos", "on_arm", "on_intel", "on_system_macos"]);
const CASK_CONTEXTS = new Set(["cask", "on_macos", "on_arm", "on_intel", "on_system_macos"]);
const ARCHIVE_EXTENSIONS = [
  ".tar.gz", ".tar.bz2", ".tar.xz", ".tar.zst", ".tar.lz", ".tgz", ".tbz2", ".txz", ".zip",
  ".gz", ".bz2", ".xz", ".zst", ".dmg", ".pkg", ".jar", ".phar", ".whl",
];

function skipString(source, start) {
  const quote = source[start];
  let index = start + 1;
  while (index < source.length) {
    if (source[index] === "\\") {
      index += 2;
      continue;
    }
    if (source[index] === quote) return index + 1;
    if (quote === '"' && source.startsWith("#{", index)) {
      const interpolation = skipInterpolation(source, index + 2);
      index = interpolation.end;
      continue;
    }
    index += 1;
  }
  return source.length;
}

function skipInterpolation(source, start) {
  let depth = 1;
  let index = start;
  let inner = "";
  while (index < source.length) {
    const character = source[index];
    if (character === '"' || character === "'") {
      const end = skipString(source, index);
      inner += source.slice(index, end);
      index = end;
      continue;
    }
    if (character === "{") depth += 1;
    if (character === "}") {
      depth -= 1;
      if (depth === 0) return { inner, end: index + 1 };
    }
    inner += character;
    index += 1;
  }
  return { inner, end: index };
}

function tokenize(source) {
  const tokens = [];
  let index = 0;
  while (index < source.length) {
    const character = source[index];
    if (/\s/.test(character)) {
      index += 1;
      continue;
    }
    if (character === "#") {
      while (index < source.length && source[index] !== "\n") index += 1;
      continue;
    }
    if (character === '"' || character === "'") {
      const end = skipString(source, index);
      const raw = source.slice(index + 1, end - (source[end - 1] === character ? 1 : 0));
      tokens.push({ type: "string", value: decodeString(raw) });
      index = end;
      continue;
    }
    if (character === ":" && /[A-Za-z_:"']/.test(source[index + 1] ?? "")) {
      index += 1;
      if (source[index] === '"' || source[index] === "'") {
        const end = skipString(source, index);
        tokens.push({ type: "symbol", value: decodeString(source.slice(index + 1, end - 1)) });
        index = end;
      } else {
        const match = source.slice(index).match(/^[A-Za-z_][\w!?]*/);
        if (match) {
          tokens.push({ type: "symbol", value: match[0] });
          index += match[0].length;
        } else {
          tokens.push({ type: "symbol", value: "" });
        }
      }
      continue;
    }
    if (/\d/.test(character)) {
      const match = source.slice(index).match(/^\d[\d._-]*/);
      tokens.push({ type: "number", value: match[0] });
      index += match[0].length;
      continue;
    }
    if (/[A-Za-z_]/.test(character)) {
      const match = source.slice(index).match(/^[A-Za-z_][\w]*[!?]?/);
      tokens.push({ type: "identifier", value: match[0] });
      index += match[0].length;
      continue;
    }
    const pair = source.slice(index, index + 2);
    if (["=>", "==", "!=", "<=", ">=", "::", "&&", "||", "=>"].includes(pair)) {
      tokens.push({ type: "punctuation", value: pair });
      index += 2;
      continue;
    }
    tokens.push({ type: "punctuation", value: character });
    index += 1;
  }
  return tokens;
}

function decodeString(value) {
  return value
    .replace(/\\n/g, "\n")
    .replace(/\\t/g, "\t")
    .replace(/\\(["'\\])/g, "$1");
}

class ArgumentParser {
  constructor(source) {
    this.tokens = tokenize(source);
    this.index = 0;
  }

  parse() {
    const values = [];
    while (this.index < this.tokens.length) {
      if (this.peek()?.value === ",") {
        this.index += 1;
        continue;
      }
      values.push(this.parseValue());
    }
    return values;
  }

  parseValue() {
    const token = this.peek();
    if (!token) return { kind: "nil", value: null };
    if (token.type === "string" || token.type === "number" || token.type === "symbol") {
      this.index += 1;
      const value = { kind: token.type, value: token.value };
      return this.parsePair(value);
    }
    if (token.type === "identifier") {
      this.index += 1;
      if (["true", "false", "nil"].includes(token.value)) {
        return { kind: "literal", value: token.value === "nil" ? null : token.value === "true" };
      }
      if (this.peek()?.value === ":") {
        this.index += 1;
        return { kind: "hash", value: { [token.value]: this.parseValue() } };
      }
      return this.parsePair({ kind: "raw", value: token.value });
    }
    if (token.value === "[") {
      this.index += 1;
      const values = [];
      while (this.peek() && this.peek().value !== "]") {
        if (this.peek().value === ",") {
          this.index += 1;
          continue;
        }
        values.push(this.parseValue());
      }
      this.expect("]");
      return { kind: "array", value: values };
    }
    if (token.value === "{") {
      this.index += 1;
      const entries = {};
      while (this.peek() && this.peek().value !== "}") {
        if (this.peek().value === ",") {
          this.index += 1;
          continue;
        }
        const pair = this.parseValue();
        if (pair.kind === "hash") Object.assign(entries, pair.value);
      }
      this.expect("}");
      return { kind: "hash", value: entries };
    }
    this.index += 1;
    const raw = [token.value];
    while (this.peek() && ![",", "]", "}"].includes(this.peek().value)) raw.push(this.next().value);
    return { kind: "raw", value: raw.join("") };
  }

  parsePair(left) {
    if (this.peek()?.value === "=>") {
      this.index += 1;
      return { kind: "hash", value: { [scalar(left)]: this.parseValue() } };
    }
    return left;
  }

  peek() {
    return this.tokens[this.index];
  }

  next() {
    const token = this.tokens[this.index];
    this.index += 1;
    return token;
  }

  expect(value) {
    if (this.peek()?.value === value) this.index += 1;
  }
}

function scalar(value) {
  if (!value) return "";
  if (value.kind === "hash" || value.kind === "array") return "";
  return String(value.value ?? "");
}

function strings(value) {
  if (!value) return [];
  if (value.kind === "string" || value.kind === "symbol" || value.kind === "number") return [scalar(value)];
  if (value.kind === "array") return value.value.flatMap(strings);
  if (value.kind === "hash") return Object.entries(value.value).flatMap(([key, child]) => {
    if (key === "with") return strings(child);
    return strings(child);
  });
  return value.kind === "raw" ? [value.value] : [];
}

function hashEntries(args) {
  return Object.assign({}, ...args.filter((argument) => argument.kind === "hash").map((argument) => argument.value));
}

function stripComment(line) {
  let quote = null;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (quote) {
      if (character === "\\") {
        index += 1;
        continue;
      }
      if (character === quote) quote = null;
      continue;
    }
    if (character === '"' || character === "'") quote = character;
    if (character === "#") return line.slice(0, index);
  }
  return line;
}

function bracketBalance(source) {
  let balance = 0;
  for (const token of tokenize(source)) {
    if (token.type !== "punctuation") continue;
    if (["[", "(", "{"].includes(token.value)) balance += 1;
    if (["]", ")", "}"].includes(token.value)) balance -= 1;
  }
  return balance;
}

function blockLabel(line) {
  if (/^class\b/.test(line)) return "class";
  if (/^module\b/.test(line)) return "module";
  if (/^def\b/.test(line) && !/^def\s+[^\s=]+\s*=/.test(line)) return "def";
  if (/^(if|unless|case|begin|while|until|for)\b/.test(line)) return line.match(/^(if|unless|case|begin|while|until|for)\b/)[1];
  const doMatch = line.match(/\bdo(?:\s*\|[^|]*\|)?\s*$/);
  if (doMatch) {
    const before = line.slice(0, doMatch.index).trim();
    const method = before.match(/^([A-Za-z_][\w.!?]*)/)?.[1] ?? "do";
    if (method === "on_system") return /\bmacos:/.test(before) ? "on_system_macos" : "on_system_linux";
    return method;
  }
  return null;
}

function parseCalls(source, type) {
  const lines = source.split(/\r?\n/);
  const calls = [];
  const stack = [];
  const contexts = type === "formula" ? FORMULA_CONTEXTS : CASK_CONTEXTS;
  let index = 0;
  while (index < lines.length) {
    const line = stripComment(lines[index]).trim();
    if (!line) {
      index += 1;
      continue;
    }
    if (/^end\b/.test(line)) {
      stack.pop();
      index += 1;
      continue;
    }
    const callMatch = line.match(/^([A-Za-z_][\w!?]*)\s*(.*)$/);
    const metadataContext = stack.length > 0 && stack.every((context) => contexts.has(context));
    if (callMatch && CALL_METHODS.has(callMatch[1]) && metadataContext) {
      let statement = line;
      let end = index;
      let balance = bracketBalance(statement);
      while (balance > 0 && end + 1 < lines.length) {
        end += 1;
        statement += `\n${stripComment(lines[end]).trim()}`;
        balance = bracketBalance(statement);
      }
      const args = new ArgumentParser(callMatch[2]).parse();
      calls.push({ method: callMatch[1], args, line: index + 1, context: stack.at(-1) });
      index = end + 1;
      continue;
    }
    const label = blockLabel(line);
    if (label) stack.push(label);
    index += 1;
  }
  return calls;
}

function callValue(calls, method, contexts) {
  for (const context of contexts) {
    const call = calls.find((candidate) => candidate.method === method && candidate.context === context);
    if (call) return call;
  }
  return calls.find((candidate) => candidate.method === method) ?? null;
}

function firstString(call) {
  return call?.args.map(scalar).find(Boolean) ?? "";
}

function detectVersion(url) {
  if (!url || url.includes("#{")) return "";
  let decoded;
  try {
    decoded = decodeURIComponent(url);
  } catch {
    decoded = url;
  }
  decoded = decoded.split(/[?#]/, 1)[0];
  const githubRelease = decoded.match(/github\.com\/.+\/releases\/download\/(?:[rvV]_?)?(\d+(?:\.\d+)+)\//);
  if (githubRelease) return githubRelease[1];
  let stem = decoded.split("/").at(-1);
  for (const extension of ARCHIVE_EXTENSIONS) {
    if (stem.toLowerCase().endsWith(extension)) {
      stem = stem.slice(0, -extension.length);
      break;
    }
  }
  const numeric = String.raw`\d+(?:\.\d+)*`;
  const dotted = String.raw`\d+(?:\.\d+)+`;
  const prerelease = String.raw`[._-]?(?:alpha|beta|pre|rc)\.?\d{0,2}`;
  const patterns = [
    new RegExp(String.raw`(?:^|[._-]?)v?(\d{4}-\d{2}-\d{2})`, "i"),
    new RegExp(String.raw`((?:\d+_)+\d+)$`),
    new RegExp(String.raw`[_-](${dotted}-(?:p|rc)?\d+)$`, "i"),
    new RegExp(String.raw`^v?(${dotted}(?:-${numeric})+)`, "i"),
    new RegExp(String.raw`[-v](${numeric})$`, "i"),
    new RegExp(String.raw`-(\d+-\d+)`),
    new RegExp(String.raw`-(${numeric})$`),
    new RegExp(String.raw`-(${numeric}(?:\.post\d+)?)$`, "i"),
    new RegExp(String.raw`-(${numeric}(?:[abc]|rc)\d*)$`, "i"),
    new RegExp(String.raw`-(${numeric}-(?:alpha|beta|rc)\d*)$`, "i"),
    new RegExp(String.raw`[_-](${numeric}(?:-\d+)?)[._-](?:i[36]86|x86|x64(?:[_-](?:32|64))?)$`, "i"),
    new RegExp(String.raw`-(\d+(?:\.\d+)+_(?:macos|osx))(?=[_-]|$)`, "i"),
    new RegExp(String.raw`[-.vV]?(${dotted}${prerelease})`, "i"),
    new RegExp(String.raw`(${numeric})$`),
    new RegExp(String.raw`[-vV](${dotted}[abc]?)(?:[._-](?:bin|dist|stable|src|sources?|final|full))$`, "i"),
    new RegExp(String.raw`-(${dotted})-`),
    new RegExp(String.raw`_(${numeric}[abc]?)\.orig$`, "i"),
    new RegExp(String.raw`-v?(\d[^-]+)`),
    new RegExp(String.raw`_v?(\d[^_]+)`),
    new RegExp(String.raw`\.v(\d+[a-z]?)`, "i"),
  ];
  for (const pattern of patterns) {
    const match = stem.match(pattern);
    if (match) {
      const value = match[1];
      return /^\d+(?:_\d+)+$/.test(value) ? value.replaceAll("_", ".") : value;
    }
  }
  const pathVersion = decoded.match(/\/(?:[rvV]_?)?(\d+\.\d+(?:\.\d+){0,2})(?:\/|$)/);
  return pathVersion?.[1] ?? "";
}

function resolveUrl(template, version, arch) {
  return template.replace(/#\{([^}]+)\}/g, (match, expression) => {
    if (["version", "version.to_s"].includes(expression)) return version;
    if (["version.to_s.delete(\".\")", "version.delete(\".\")"].includes(expression)) return version.replaceAll(".", "");
    if (expression === "version.major_minor") return version.split(".").slice(0, 2).join(".");
    if (expression === "version.tr(\".\", \"_\")") return version.replaceAll(".", "_");
    if (expression === "arch") return arch;
    return match;
  });
}

function inferArchitectures(calls, url, type, archHash) {
  const architectures = new Set();
  for (const call of calls.filter((candidate) => candidate.method === "depends_on")) {
    const entries = hashEntries(call.args);
    if (entries.arch) {
      for (const architecture of strings({ kind: "array", value: call.args })) {
        if (architecture === "x86_64") architectures.add("x86_64");
        if (architecture === "arm64") architectures.add("arm64");
      }
      const value = scalar(entries.arch);
      if (value === "x86_64") architectures.add("x86_64");
      if (value === "arm64") architectures.add("arm64");
    }
  }
  if (type === "cask" && Object.keys(archHash).length > 0) {
    if (archHash.arm) architectures.add("arm64");
    if (archHash.intel) architectures.add("x86_64");
  }
  if (calls.some((call) => call.method === "url" && ["on_arm", "on_intel"].includes(call.context))) {
    architectures.add("arm64");
    architectures.add("x86_64");
  }
  const lower = url.toLowerCase();
  if (lower.includes("universal")) {
    architectures.add("arm64");
    architectures.add("x86_64");
  }
  if (/(?:x86_64|amd64|x64|intel)/.test(lower)) architectures.add("x86_64");
  if (/(?:arm64|aarch64)/.test(lower)) architectures.add("arm64");
  if (architectures.size === 0) {
    architectures.add("arm64");
    architectures.add("x86_64");
  }
  return [...architectures].sort();
}

function parseDependencies(calls) {
  const dependencies = [];
  const seen = new Set();
  const tagNames = ["build", "test", "optional", "recommended", "no_linkage"];
  for (const call of calls) {
    if (!["depends_on", "uses_from_macos"].includes(call.method)) continue;
    const entries = hashEntries(call.args);
    if (entries.arch || entries.macos) continue;
    const shorthand = Object.entries(entries).find(([key, value]) => !tagNames.includes(key) && !["arch", "macos"].includes(key) && scalar(value));
    const directName = call.args.find((argument) => ["string", "symbol", "number"].includes(argument.kind) && scalar(argument))?.value;
    const name = directName ? String(directName) : shorthand?.[0];
    if (!name) continue;
    const tap = call.method === "uses_from_macos" ? "system" : name.includes("/") ? name.split("/").slice(0, 2).join("/") : "core";
    const tags = Object.entries(entries)
      .filter(([key, value]) => tagNames.includes(key) && scalar(value) !== "false")
      .map(([key]) => key);
    const shorthandTag = scalar(shorthand?.[1]);
    if (tagNames.includes(shorthandTag)) tags.push(shorthandTag);
    const kind = tags.includes("build") ? "build" : tags.includes("test") ? "test" : tags.includes("no_linkage") ? "no-linkage" : "runtime";
    const key = `${name}:${kind}`;
    if (seen.has(key)) continue;
    seen.add(key);
    dependencies.push({
      name: tap === "bemly/tahoe" ? name.slice("bemly/tahoe/".length) : name,
      fullName: tap === "bemly/tahoe" || tap === "core" || tap === "system" ? name : `bemly/tahoe/${name}`,
      tap,
      kind,
    });
  }
  return dependencies.sort((left, right) => left.name.localeCompare(right.name));
}

function parseLicense(calls) {
  const call = callValue(calls, "license", ["class", "cask"]);
  if (!call) return [];
  const values = [];
  for (const argument of call.args) {
    if (argument.kind === "hash") {
      for (const [key, value] of Object.entries(argument.value)) {
        if (key === "with") continue;
        if (value.kind === "hash" && value.value.with) {
          values.push(`${key} WITH ${scalar(value.value.with)}`);
        } else {
          values.push(...strings(value));
        }
      }
    } else {
      values.push(...strings(argument));
    }
  }
  return [...new Set(values.filter(Boolean))];
}

function callIsDue(call) {
  const date = scalar(hashEntries(call.args).date);
  return !date || date <= new Date().toISOString().slice(0, 10);
}

function parseMetadata(source, token, type, sourcePath) {
  const calls = parseCalls(source, type);
  const baseContext = type === "formula" ? "class" : "cask";
  const contexts = type === "formula"
    ? [baseContext, "stable", "on_intel", "on_macos", "on_arm"]
    : [baseContext, "on_intel", "on_macos", "on_arm"];
  const versionCall = callValue(calls, "version", contexts);
  const urlCall = callValue(calls, "url", contexts);
  const archCall = callValue(calls, "arch", [baseContext]);
  const archHash = hashEntries(archCall?.args ?? []);
  const intelArch = scalar(archHash.intel) || "x86_64";
  const explicitVersion = versionCall ? versionCall.args.map(scalar).find(Boolean) ?? "" : "";
  const urlTemplate = firstString(urlCall);
  const url = resolveUrl(urlTemplate, explicitVersion, intelArch);
  const version = explicitVersion || detectVersion(url);
  const names = type === "cask"
    ? calls.filter((call) => call.method === "name" && call.context === baseContext).flatMap((call) => call.args.map(scalar).filter(Boolean))
    : [token];
  const desc = firstString(callValue(calls, "desc", [baseContext]));
  const homepage = firstString(callValue(calls, "homepage", [baseContext]));
  const revisionCall = callValue(calls, "revision", [baseContext]);
  const revision = revisionCall ? Number(revisionCall.args.map(scalar).find(Boolean)) || 0 : 0;
  const macosCall = calls.find((call) => call.method === "depends_on" && hashEntries(call.args).macos);
  const macos = macosCall ? [scalar(hashEntries(macosCall.args).macos)] : [];
  const kegOnlyCall = callValue(calls, "keg_only", [baseContext]);
  const kegOnly = kegOnlyCall ? kegOnlyCall.args.map(scalar).find(Boolean) ?? true : false;
  const autoUpdatesCall = callValue(calls, "auto_updates", [baseContext]);
  const autoUpdates = autoUpdatesCall?.args[0]?.value === true;
  const conflictCalls = calls.filter((call) => call.method === "conflicts_with" && call.context === baseContext);
  const conflicts = conflictCalls.flatMap((call) => call.args.map(scalar).filter(Boolean));
  const fullName = `bemly/tahoe/${token}`;
  return {
    token,
    type,
    fullName,
    names,
    desc,
    homepage,
    version,
    revision,
    url: url.includes("#{") ? "" : url,
    license: parseLicense(calls),
    architectures: inferArchitectures(calls, url, type, archHash),
    macos,
    dependencies: parseDependencies(calls),
    hasBottle: type === "formula" && /\bsha256\b[^\n]*\btahoe\s*:/.test(source),
    mirrored: type === "cask" && /github\.com\/Bemly\/homebrew-tahoe\/releases\/download\//i.test(url),
    kegOnly,
    autoUpdates,
    conflicts: [...new Set(conflicts)],
    deprecated: calls.some((call) => call.method === "deprecate!" && callIsDue(call)),
    disabled: calls.some((call) => call.method === "disable!" && callIsDue(call)),
    deprecationDate: scalar(hashEntries(calls.find((call) => call.method === "deprecate!")?.args ?? []).date),
    disableDate: scalar(hashEntries(calls.find((call) => call.method === "disable!")?.args ?? []).date),
    sourcePath,
  };
}

export async function loadPackages(root) {
  const packages = [];
  for (const [type, directory] of [["formula", "Formula"], ["cask", "Casks"]]) {
    const entries = await readdir(path.join(root, directory), { withFileTypes: true });
    for (const entry of entries.filter((candidate) => candidate.isFile() && candidate.name.endsWith(".rb")).sort((a, b) => a.name.localeCompare(b.name, "en", { numeric: true }))) {
      const token = entry.name.slice(0, -3);
      const sourcePath = `${directory}/${entry.name}`;
      const source = await readFile(path.join(root, sourcePath), "utf8");
      packages.push(parseMetadata(source, token, type, sourcePath));
    }
  }
  return packages.sort((left, right) => left.token.localeCompare(right.token, "en", { numeric: true, sensitivity: "base" }));
}

export { detectVersion, parseMetadata, resolveUrl };
