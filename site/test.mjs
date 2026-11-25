import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, readFile, readdir, rm } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { detectVersion, loadPackages, parseMetadata } from "./lib/metadata.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

test("detects Homebrew-compatible versions from real URL shapes", () => {
  const cases = [
    ["https://github.com/cli/cli/releases/download/v2.105.0/gh_2.105.0_macOS_amd64.zip", "2.105.0"],
    ["https://download.java.net/java/GA/jdk26.0.2.1/hash/GPL/openjdk-26.0.2.1_macos-x64_bin.tar.gz", "26.0.2.1_macos"],
    ["https://ftp.gnu.org/gnu/make/make-4.4.1.tar.lz", "4.4.1"],
    ["https://static.rust-lang.org/rustup/archive/1.29.3/x86_64-apple-darwin/rustup-init", "1.29.3"],
    ["https://github.com/unicode-org/icu/releases/download/release-78.3/icu4c-78.3-sources.tgz", "78.3"],
    ["https://github.com/mstorsjo/llvm-mingw/releases/download/20261117/llvm-mingw-20261117-ucrt-macos-universal.tar.xz", "20261117"],
  ];
  for (const [url, expected] of cases) assert.equal(detectVersion(url), expected, url);
});

test("parses formula DSL metadata without evaluating Ruby", () => {
  const source = `class Demo < Formula
  desc "Demo package"
  homepage "https://example.com"
  url "https://example.com/v#{version}/demo-#{version.to_s.delete(".")}.tar.gz"
  version "1.2.3"
  license "MIT" => { with: "LLVM-exception" }
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  depends_on "bemly/tahoe/zstd" => :build
  bottle do
    sha256 cellar: :any_skip_relocation, tahoe: "abc"
  end
  deprecate! date: "2030-01-01", because: :deprecated_upstream
end`;
  const pkg = parseMetadata(source, "demo", "formula", "Formula/demo.rb");
  assert.equal(pkg.version, "1.2.3");
  assert.equal(pkg.url, "https://example.com/v1.2.3/demo-123.tar.gz");
  assert.deepEqual(pkg.license, ["MIT WITH LLVM-exception"]);
  assert.deepEqual(pkg.architectures, ["x86_64"]);
  assert.deepEqual(pkg.macos, ["tahoe"]);
  assert.equal(pkg.hasBottle, true);
  assert.equal(pkg.deprecated, false);
  assert.equal(pkg.deprecationDate, "2030-01-01");
  assert.deepEqual(pkg.dependencies, [{ name: "zstd", fullName: "bemly/tahoe/zstd", tap: "bemly/tahoe", kind: "build" }]);
});

test("parses repeated cask names and architecture-specific stanzas", () => {
  const source = `cask "demo" do
  arch arm: "arm64", intel: "x64"
  on_intel do
    version "2.0.0"
    url "https://example.com/demo-#{version}-#{arch}.dmg"
  end
  name "Demo"
  name "Demo 中文版"
  desc "Demo cask"
  homepage "https://example.com"
  depends_on macos: :tahoe
end`;
  const pkg = parseMetadata(source, "demo", "cask", "Casks/demo.rb");
  assert.equal(pkg.version, "2.0.0");
  assert.equal(pkg.url, "https://example.com/demo-2.0.0-x64.dmg");
  assert.deepEqual(pkg.names, ["Demo", "Demo 中文版"]);
  assert.deepEqual(pkg.architectures, ["arm64", "x86_64"]);
  assert.deepEqual(pkg.macos, ["tahoe"]);
});

test("parses git URL tags and multiline metadata", () => {
  const source = `class Demo < Formula
  desc "Demo git package"
  homepage "https://example.com"
  url "git://example.com/demo.git",
      tag: "v2.1.5",
      revision: "0123456789abcdef"
end`;
  const pkg = parseMetadata(source, "demo", "formula", "Formula/demo.rb");
  assert.equal(pkg.version, "2.1.5");
  assert.equal(pkg.url, "");
});

test("repository inventory contains exactly the formula and cask files", async () => {
  const packages = await loadPackages(root);
  const formulaFiles = (await readdir(path.join(root, "Formula"))).filter((name) => name.endsWith(".rb")).map((name) => name.slice(0, -3)).sort();
  const caskFiles = (await readdir(path.join(root, "Casks"))).filter((name) => name.endsWith(".rb")).map((name) => name.slice(0, -3)).sort();
  assert.deepEqual(packages.filter((pkg) => pkg.type === "formula").map((pkg) => pkg.token).sort(), formulaFiles);
  assert.deepEqual(packages.filter((pkg) => pkg.type === "cask").map((pkg) => pkg.token).sort(), caskFiles);
  for (const pkg of packages) {
    assert.ok(pkg.version, `${pkg.fullName} has a version`);
    assert.ok(pkg.desc, `${pkg.fullName} has an English description`);
    assert.ok(pkg.descZh, `${pkg.fullName} has a Chinese description`);
    assert.match(pkg.descZh, /[\u3400-\u9fff]/, `${pkg.fullName} Chinese description contains Chinese text`);
    assert.ok(pkg.homepage, `${pkg.fullName} has a homepage`);
    assert.ok(existsSync(path.join(root, pkg.sourcePath)), `${pkg.sourcePath} exists`);
    assert.ok(!pkg.url.includes("#{"), `${pkg.fullName} has a resolved artifact URL`);
  }
});

test("static build emits bilingual pages and valid internal links", async (context) => {
  const output = await mkdtemp(path.join(root, ".site-test-"));
  context.after(() => rm(output, { recursive: true, force: true }));
  execFileSync(process.execPath, [path.join(root, "site/build.mjs"), "--output", output], { cwd: root, stdio: "pipe" });
  const packages = JSON.parse(await readFile(path.join(output, "packages.json"), "utf8")).packages;
  assert.ok(packages.length > 0);
  assert.ok(existsSync(path.join(output, "index.html")));
  assert.ok(existsSync(path.join(output, "zh/index.html")));
  assert.ok(existsSync(path.join(output, "packages/index.html")));
  assert.ok(existsSync(path.join(output, "zh/formula/index.html")));
  assert.ok(existsSync(path.join(output, "cask/index.html")));
  assert.ok(existsSync(path.join(output, "sitemap.xml")));
  assert.ok(existsSync(path.join(output, ".nojekyll")));
  for (const pkg of packages) {
    assert.ok(existsSync(path.join(output, pkg.type, pkg.token, "index.html")), `${pkg.fullName} detail page exists`);
    assert.ok(existsSync(path.join(output, "zh", pkg.type, pkg.token, "index.html")), `${pkg.fullName} Chinese detail page exists`);
  }
  const home = await readFile(path.join(output, "index.html"), "utf8");
  const chineseHome = await readFile(path.join(output, "zh/index.html"), "utf8");
  assert.match(home, /id="language"/);
  assert.match(home, /id="theme"/);
  assert.match(home, /data-theme="system"/);
  assert.match(chineseHome, /简体中文/);
  assert.match(chineseHome, /专为 Intel Mac/);
  const chinesePackages = await readFile(path.join(output, "zh/packages/index.html"), "utf8");
  assert.match(chinesePackages, /GitHub 官方命令行工具/);
  assert.match(chinesePackages, /AFM 拼音输入法/);
  assert.match(chinesePackages, /<span class="type-badge cask">应用<\/span>/);
  const chineseFormula = await readFile(path.join(output, "zh/formula/gh/index.html"), "utf8");
  assert.match(chineseFormula, /GitHub 官方命令行工具/);
  const cask = packages.find((pkg) => pkg.type === "cask");
  const caskPage = await readFile(path.join(output, cask.type, cask.token, "index.html"), "utf8");
  assert.match(caskPage, /brew install --cask bemly\/tahoe\//);

  const htmlFiles = (await readdir(output, { recursive: true })).filter((name) => String(name).endsWith(".html"));
  for (const file of htmlFiles) {
    const html = await readFile(path.join(output, file), "utf8");
    for (const match of html.matchAll(/href="(\/[^"]*)"/g)) {
      const route = decodeURIComponent(match[1].split(/[?#]/, 1)[0]);
      const target = route.endsWith("/") ? path.join(output, route, "index.html") : path.join(output, route);
      assert.ok(existsSync(target), `${file} links to missing ${route}`);
    }
  }
});
