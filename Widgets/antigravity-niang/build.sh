#!/usr/bin/env bash
# Antigravity 中文补丁版成品构建（本 tap 破例：分发修改并重签过的专有包）
#
#   Widgets/antigravity-niang/build.sh [--version 2.33.0] [--build 4731201358004224]
#                                      [--revision 1] [--upload] [--keep-work]
#
# 流程：官方 darwin-x64 dmg → 校验 sha → 挂载取 app → 汉化引擎静态改写 asar →
#       巡检门 → 注入挂件与禁自更新 → ad-hoc 重签 → 重打 dmg → （可选）传本仓 Release
#
# 任一步失败立刻退出，绝不产出半成品；产物只落在 .build/ 下且不入 git。

set -euo pipefail

WIDGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$WIDGET_DIR/../.." && pwd)"
CN_REPO="Silas-02/antigravity-desktop-cn"
# 汉化引擎与字典和宿主版本强耦合，必须按 commit 固定，不能追 main。
CN_PIN="c6ba0b83be8c74fa5c9e9271f9f7fb6e91077ca7"

APP_VERSION=""
APP_BUILD=""
REVISION="1"
UPLOAD=false
KEEP_WORK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) APP_VERSION="$2"; shift 2 ;;
    --build) APP_BUILD="$2"; shift 2 ;;
    --revision) REVISION="$2"; shift 2 ;;
    --cn-pin) CN_PIN="$2"; shift 2 ;;
    --upload) UPLOAD=true; shift ;;
    --keep-work) KEEP_WORK=true; shift ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
done

# 版本与官方 sha 都取自 homebrew/core 的 cask API：它按 macOS 版本给出 darwin-x64
# 的直链与校验和，比抓官网下载页更稳，且能与 Homebrew 的收录节奏对齐。
CORE_JSON="$(mktemp)"
curl -fsS "https://formulae.brew.sh/api/cask/antigravity.json" -o "$CORE_JSON"
if [[ -z "$APP_VERSION" || -z "$APP_BUILD" ]]; then
  CORE_VERSION="$(python3 -c "import json;print(json.load(open('$CORE_JSON'))['version'])")"
  APP_VERSION="${CORE_VERSION%%,*}"
  APP_BUILD="${CORE_VERSION##*,}"
fi
OFFICIAL_URL="$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
v=d['variations'].get('tahoe') or {}
if not v.get('url'): sys.exit('core cask 没有 tahoe 变体，拿不到 darwin-x64 直链')
print(v['url'])
" "$CORE_JSON")"
OFFICIAL_SHA="$(python3 -c "
import json,sys
print(json.load(open(sys.argv[1]))['variations']['tahoe']['sha256'])
" "$CORE_JSON")"

PATCHED_VERSION="${APP_VERSION}-${APP_BUILD}-cn${REVISION}"
WORK="${REPO_DIR}/.build/antigravity-cn/${PATCHED_VERSION}"
DMG_NAME="Antigravity-${PATCHED_VERSION}.dmg"
OUT_DMG="${REPO_DIR}/.build/antigravity-cn/${DMG_NAME}"

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die() { printf '\033[31m[失败] %s\033[0m\n' "$1" >&2; exit 1; }

for tool in node curl hdiutil codesign python3 shasum; do
  command -v "$tool" >/dev/null 2>&1 || die "缺少命令：$tool"
done
if [[ "$UPLOAD" == true ]] && ! command -v gh >/dev/null 2>&1; then
  die "缺少命令：gh（--upload 需要）"
fi

say "官方包：$APP_VERSION build=$APP_BUILD"
echo "  直链 $OFFICIAL_URL"
echo "  core 记录的 x64 sha $OFFICIAL_SHA"

rm -rf "$WORK"
mkdir -p "$WORK"

# 官方包 240MB，按 core 记录的 sha 缓存，重跑构建不必再下一遍。
say "下载官方 darwin-x64 dmg"
CACHE_DIR="${REPO_DIR}/.build/antigravity-cn/cache"
CACHE="$CACHE_DIR/official-${OFFICIAL_SHA}.dmg"
mkdir -p "$CACHE_DIR"
if [[ -f "$CACHE" ]]; then
  echo "  命中缓存 $(basename "$CACHE")"
  cp "$CACHE" "$WORK/official.dmg"
else
  curl -fL --retry 3 -o "$WORK/official.dmg" "$OFFICIAL_URL"
fi
ACTUAL_SHA="$(shasum -a 256 "$WORK/official.dmg" | awk '{print $1}')"
if [[ "$ACTUAL_SHA" != "$OFFICIAL_SHA" ]]; then
  rm -f "$WORK/official.dmg"
  die "下载校验失败：实算 $ACTUAL_SHA ≠ core $OFFICIAL_SHA（上游可能重切了同版本包，按 AGENTS 11.24 三方核对后再构建）"
fi
echo "  sha256 一致 $ACTUAL_SHA"
if [[ ! -f "$CACHE" ]]; then
  cp "$WORK/official.dmg" "$CACHE"
  echo "  已缓存到 ${CACHE#"$REPO_DIR"/}"
fi

say "挂载并复制 Antigravity.app"
MOUNT="$WORK/mnt"
mkdir -p "$MOUNT"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT" "$WORK/official.dmg" >/dev/null
[[ -d "$MOUNT/Antigravity.app" ]] || die "dmg 内没有 Antigravity.app"
cp -R "$MOUNT/Antigravity.app" "$WORK/"
hdiutil detach "$MOUNT" >/dev/null
APP="$WORK/Antigravity.app"
RES="$APP/Contents/Resources"
asar_size="$(stat -f%z "$RES/app.asar")"
echo "  app 就位，app.asar ${asar_size} B"
[[ -f "$RES/app.asar" ]] || die "缺少 Contents/Resources/app.asar"

say "取汉化引擎（pin $CN_PIN）"
CN="$WORK/cn"
mkdir -p "$CN"
curl -fL --retry 3 "https://codeload.github.com/$CN_REPO/tar.gz/$CN_PIN" | tar xz -C "$CN" --strip-components=1
[[ -f "$CN/localization_engine.js" ]] || die "引擎源码不完整"
# Node 按「最近的 package.json」判定模块类型。引擎是 CommonJS（require），而本仓
# 根目录存在过 "type": "module" 的残留 package.json —— 那样会把引擎当 ESM 加载，
# 第一行 require 直接 ReferenceError。显式钉成 commonjs，构建不受周边文件影响。
if [[ ! -f "$CN/package.json" ]]; then
  printf '{ "type": "commonjs" }\n' > "$CN/package.json"
fi

say "静态改写：注入中文汉化"
node "$CN/localization_engine.js" --install-dir "$APP" --brand-title english --no-kill | tail -20
[[ -f "$RES/app.asar.bak" ]] || die "引擎没有留下 app.asar.bak 备份"

say "质量门：引擎自带巡检（字典/注入沙箱/asar 锚点）"
node "$CN/scripts/ag_audit.js" check --asar "$RES/app.asar" >/tmp/ag_audit.log 2>&1 || {
  tail -30 /tmp/ag_audit.log; die "ag_audit check 未通过"; }
ANCHOR_FAILS="$(grep -c '\[FAIL\]\|未命中\|失配' /tmp/ag_audit.log || true)"
echo "  巡检输出锚点异常行：$ANCHOR_FAILS（字典与注入细节见 /tmp/ag_audit.log）"

say "注入挂件 + 禁用自更新"
node "$WIDGET_DIR/tools/inject-widget.mjs" --asar "$RES/app.asar" --root "$WIDGET_DIR" | tail -12

say "ad-hoc 重签名（必须丢掉 hardened runtime，否则 dyld 因 Team ID 校验 SIGABRT）"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || die "重签名失败"
codesign --verify --deep "$APP" >/dev/null 2>&1 || die "重签名后 codesign --verify 未通过"
echo "  签名校验通过"

say "复验：Electron 视角下 asar 可正常读取"
cp "$RES/app.asar" "$WORK/verify.asar"
cp -R "$RES/app.asar.unpacked" "$WORK/verify.unpacked" 2>/dev/null || true
cat > "$WORK/verify.cjs" <<'JS'
const fs=require('fs');
const base=process.env.VERIFY_ASAR;
const must=['package.json','dist/main.js','dist/gyWidgetMain.js','dist/gyWidget/renderer/index.html','dist/gyWidget/characters/characters.json'];
for(const p of must){
  try{const s=fs.readFileSync(base+'/'+p,'utf8'); if(p==='package.json') JSON.parse(s);}
  catch(e){console.error('读取失败 '+p+': '+String(e.message).slice(0,80)); process.exit(1);}
}
console.log('Electron fs 复验通过：'+must.length+' 个关键条目可读，package.json 为合法 JSON');
JS
VERIFY_ASAR="$WORK/verify.asar" ELECTRON_RUN_AS_NODE=1 "$APP/Contents/MacOS/Antigravity" "$WORK/verify.cjs" || die "Electron fs 复验失败"

say "重打 dmg"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
mv "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$OUT_DMG"
hdiutil create -volname Antigravity -srcfolder "$STAGE" -ov -format UDZO "$OUT_DMG" >/dev/null
[[ -f "$OUT_DMG" ]] || die "dmg 生成失败"
PATCHED_SHA="$(shasum -a 256 "$OUT_DMG" | awk '{print $1}')"
printf '%s  %s\n' "$PATCHED_SHA" "$DMG_NAME" > "$OUT_DMG.sha256"
echo "  $DMG_NAME $(stat -f%z "$OUT_DMG") B"
echo "  sha256 $PATCHED_SHA"

if [[ "$UPLOAD" == true ]]; then
  say "上传到本仓 Release：tag antigravity-$PATCHED_VERSION"
  TAG="antigravity-$PATCHED_VERSION"
  if gh release view "$TAG" --repo bemly/homebrew-tahoe >/dev/null 2>&1; then
    gh release upload "$TAG" --clobber --repo bemly/homebrew-tahoe "$OUT_DMG" "$OUT_DMG.sha256"
  else
    gh release create "$TAG" --repo bemly/homebrew-tahoe --title "$TAG" --notes-file "$WIDGET_DIR/RELEASE-NOTES.template" \
      "$OUT_DMG#$DMG_NAME" "$OUT_DMG.sha256#$(basename "$OUT_DMG").sha256"
  fi
  # 本仓 cask 政策：每个 cask 的 Release 只留最新一个（11.34.3）。本包的产物由
  # 脚本构建、不走 updater 的 deleteOldCaskReleases，所以这里自己清同前缀旧 tag。
  # 只认「antigravity- 后接数字」，避免误删别的前缀同名 release。
  say "清理旧 release（只保留 $TAG）"
  gh release list --repo bemly/homebrew-tahoe --json tagName --jq '.[].tagName' \
    --limit 200 2>/dev/null | while read -r old; do
      if [[ "$old" == antigravity-* && "$old" != "$TAG" && "${old#antigravity-}" =~ ^[0-9] ]]; then
        echo "  删除 $old"
        gh release delete "$old" --yes --repo bemly/homebrew-tahoe || echo "  警告：删除 $old 失败（不阻断）"
      fi
    done
  echo "  已上传（cask url 指向本仓 Release，检查器读 .sha256 sidecar）"
fi

if [[ "$KEEP_WORK" != true ]]; then
  rm -rf "$WORK/mnt" "$WORK/stage" "$WORK/official.dmg"
fi

say "构建完成"
cat <<EOF
版本   $PATCHED_VERSION（宿主 $APP_VERSION build $APP_BUILD）
产物   $OUT_DMG
sha256 $PATCHED_SHA
sidecar $OUT_DMG.sha256

下一步：
  1) 本机验收  brew install --cask ./Casks/antigravity.rb   （或先手改 cask 的 url/sha）
  2) 提交 cask 与 updater/antigravity.swift
  3) 需要自动跟版时手动跑 watch-updates
EOF
