#!/usr/bin/env bash
# Antigravity 中文补丁版成品构建（本 tap 破例：分发修改并重签过的专有包）
#
#   Widgets/antigravity-niang/build.sh [--version 2.33.0] [--build 4731201358004224]
#                                      [--official-sha <sha256>]
#                                      [--revision 1] [--cn-ref <tag|commit>]
#                                      [--upload] [--keep-work]
#
# 流程：官方 darwin-x64 dmg → 校验 sha → 挂载取 app → 汉化引擎静态改写 asar →
#       巡检门 → 注入挂件与禁自更新 → ad-hoc 重签 → 重打 dmg → （可选）传本仓 Release
#
# 任一步失败立刻退出，绝不产出半成品；产物只落在 .build/ 下且不入 git。

set -euo pipefail

WIDGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$WIDGET_DIR/../.." && pwd)"
CN_REPO="Silas-02/antigravity-desktop-cn"
# 汉化引擎与宿主版本强耦合，但上游是**按宿主版本打 tag** 的（v2.33.0、v2.33.0.1…，
# 每个 Antigravity 版本一对，通常两天内跟上），所以默认跟着 tag 走：宿主升版自动拿到
# 对应字典，不需要人工改脚本。tag 缺失说明上游还没适配 → 直接失败，绝不拿旧字典硬上
# （旧字典的锚点对不上，最坏情况是「装得上但没汉化」）。
# 需要临时锁定（回滚验证、上游 tag 被移动）时用 --cn-ref 传 tag 名或 commit。
CN_REF=""

APP_VERSION=""
APP_BUILD=""
OFFICIAL_SHA=""
REVISION="1"
UPLOAD=false
KEEP_WORK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) APP_VERSION="$2"; shift 2 ;;
    --build) APP_BUILD="$2"; shift 2 ;;
    --official-sha) OFFICIAL_SHA="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"; shift 2 ;;
    --revision) REVISION="$2"; shift 2 ;;
    --cn-ref) CN_REF="$2"; shift 2 ;;
    --cn-pin) CN_REF="$2"; shift 2 ;;   # 旧名，等价 --cn-ref
    --upload) UPLOAD=true; shift ;;
    --keep-work) KEEP_WORK=true; shift ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
done

# 支持 --version 2.33.0,4731201358004224 简写
if [[ "$APP_VERSION" == *,* && -z "$APP_BUILD" ]]; then
  APP_BUILD="${APP_VERSION##*,}"
  APP_VERSION="${APP_VERSION%%,*}"
fi

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die() { printf '\033[31m[失败] %s\033[0m\n' "$1" >&2; exit 1; }

# 版本与下载直链动态取自官方下载页；SHA-256 按「版本-构建号」pin 到
# official-sha256.txt。首次遇到新版本时允许从官方 GCS 对象元数据 bootstrap pin，
# 后续重跑必须逐字节核对。显式锁定旧版本仍要求同时给 build 与 official-sha。
PIN_FILE="$WIDGET_DIR/official-sha256.txt"
OFFICIAL_PAGE="$(mktemp)"
HEADERS="$(mktemp)"
trap 'rm -f "$OFFICIAL_PAGE" "$HEADERS"' EXIT
curl -fsS "https://antigravity.google/download" -o "$OFFICIAL_PAGE"
LATEST_HOST="$(python3 -c '
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"https://storage\.googleapis\.com/antigravity-public/antigravity-hub/(\d+(?:\.\d+)+)-(\d+)/darwin-x64/Antigravity\.dmg", s)
if not m: sys.exit("官方下载页没有 macOS Intel 链接")
print(f"{m.group(1)}-{m.group(2)}")
' "$OFFICIAL_PAGE")"
LATEST_APP="${LATEST_HOST%-*}"
LATEST_BUILD="${LATEST_HOST##*-}"
LATEST_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${LATEST_HOST}/darwin-x64/Antigravity.dmg"
PINNED_SHA="$(awk -v host="$LATEST_HOST" '$1==host {print $2; exit}' "$PIN_FILE" 2>/dev/null || true)"

if [[ -z "$APP_VERSION" && -z "$APP_BUILD" ]]; then
  APP_VERSION="$LATEST_APP"
  APP_BUILD="$LATEST_BUILD"
  OFFICIAL_URL="$LATEST_URL"
  OFFICIAL_SHA="${OFFICIAL_SHA:-$PINNED_SHA}"
elif [[ "$APP_VERSION" == "$LATEST_APP" ]] && [[ -z "$APP_BUILD" || "$APP_BUILD" == "$LATEST_BUILD" ]]; then
  APP_BUILD="$LATEST_BUILD"
  OFFICIAL_URL="$LATEST_URL"
  OFFICIAL_SHA="${OFFICIAL_SHA:-$PINNED_SHA}"
else
  [[ -n "$APP_VERSION" ]] || die "指定 --build 时必须同时传入 --version"
  [[ -n "$APP_BUILD" ]] || die "锁定非最新宿主版本 ${APP_VERSION} 时必须同时传入 --build <构建号>（或使用 --version <版本>,<构建号>）"
  [[ "$OFFICIAL_SHA" =~ ^[0-9a-f]{64}$ ]] || die "锁定非最新宿主版本 ${APP_VERSION}-${APP_BUILD} 时必须传入合法的 64 位 --official-sha <sha256>"
  OFFICIAL_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${APP_VERSION}-${APP_BUILD}/darwin-x64/Antigravity.dmg"
fi
HOST="${APP_VERSION}-${APP_BUILD}"

PATCHED_VERSION="${APP_VERSION}-${APP_BUILD}-cn${REVISION}"
WORK="${REPO_DIR}/.build/antigravity-cn/${PATCHED_VERSION}"
DMG_NAME="Antigravity-${PATCHED_VERSION}.dmg"
OUT_DMG="${REPO_DIR}/.build/antigravity-cn/${DMG_NAME}"

for tool in node curl git hdiutil codesign python3 shasum; do
  command -v "$tool" >/dev/null 2>&1 || die "缺少命令：$tool"
done
if [[ "$UPLOAD" == true ]] && ! command -v gh >/dev/null 2>&1; then
  die "缺少命令：gh（--upload 需要）"
fi

say "官方包：$APP_VERSION build=$APP_BUILD"
echo "  直链 $OFFICIAL_URL"
echo "  本地 pin 的 x64 sha ${OFFICIAL_SHA:-待 bootstrap}"

rm -rf "$WORK"
mkdir -p "$WORK"

curl -fsSI "$OFFICIAL_URL" > "$HEADERS"
EXPECTED_SIZE="$(tr -d '\r' < "$HEADERS" | awk -F': ' 'tolower($1)=="x-goog-stored-content-length"{print $2; exit}')"
EXPECTED_GEN="$(tr -d '\r' < "$HEADERS" | awk -F': ' 'tolower($1)=="x-goog-generation"{print $2; exit}')"
[[ -n "$EXPECTED_SIZE" && -n "$EXPECTED_GEN" ]] || die "官方 GCS 元数据缺少 size/generation：$OFFICIAL_URL"
PIN_LINE="$(awk -v host="$HOST" '$1==host {print; exit}' "$PIN_FILE" 2>/dev/null || true)"
if [[ -n "$PIN_LINE" ]]; then
  read -r PIN_SHA PIN_SIZE PIN_GEN _ <<< "$PIN_LINE"
  [[ -z "$OFFICIAL_SHA" || "$OFFICIAL_SHA" == "$PIN_SHA" ]] || die "传入 official-sha 与 pin 不一致：$HOST"
  [[ "$EXPECTED_SIZE" == "$PIN_SIZE" && "$EXPECTED_GEN" == "$PIN_GEN" ]] || die "官方 GCS 对象元数据与 pin 不一致：$HOST"
  OFFICIAL_SHA="$PIN_SHA"
  EXPECTED_SIZE="$PIN_SIZE"
  EXPECTED_GEN="$PIN_GEN"
fi

# 官方包约 240MB，按 SHA pin 缓存；新版本首次下载时按 host 临时缓存。
say "下载官方 darwin-x64 dmg"
echo "  官方下载页当前 Intel 版本：$LATEST_HOST"
echo "  本次构建版本：$HOST"
echo "  直链 $OFFICIAL_URL"
echo "  官方 GCS size=$EXPECTED_SIZE generation=$EXPECTED_GEN"
CACHE_DIR="${REPO_DIR}/.build/antigravity-cn/cache"
CACHE="$CACHE_DIR/official-${OFFICIAL_SHA:-$HOST}.dmg"
mkdir -p "$CACHE_DIR"
if [[ -f "$CACHE" ]]; then
  echo "  命中缓存 $(basename "$CACHE")"
  cp "$CACHE" "$WORK/official.dmg"
else
  curl -fL --retry 3 -o "$WORK/official.dmg" "$OFFICIAL_URL"
fi
ACTUAL_SIZE="$(stat -f%z "$WORK/official.dmg")"
[[ "$ACTUAL_SIZE" == "$EXPECTED_SIZE" ]] || die "下载大小不符：实算 $ACTUAL_SIZE ≠ 官方 GCS $EXPECTED_SIZE"
ACTUAL_SHA="$(shasum -a 256 "$WORK/official.dmg" | awk '{print $1}')"
if [[ -n "$OFFICIAL_SHA" && "$ACTUAL_SHA" != "$OFFICIAL_SHA" ]]; then
  rm -f "$WORK/official.dmg"
  die "下载校验失败：实算 $ACTUAL_SHA ≠ 官方预期 ${OFFICIAL_SHA}（上游可能重切了同版本包，请核对官方对象后再构建）"
fi
if [[ -z "$PIN_LINE" ]]; then
  printf '%s %s %s %s\n' "$HOST" "$ACTUAL_SHA" "$ACTUAL_SIZE" "$EXPECTED_GEN" >> "$PIN_FILE"
  OFFICIAL_SHA="$ACTUAL_SHA"
  SHA_CACHE="$CACHE_DIR/official-${OFFICIAL_SHA}.dmg"
  [[ -f "$SHA_CACHE" ]] || cp "$WORK/official.dmg" "$SHA_CACHE"
  echo "  已 bootstrap 官方 SHA pin：$HOST $ACTUAL_SHA"
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

say "取汉化引擎"
if [[ -z "$CN_REF" ]]; then
  # v<宿主版本> 与 v<宿主版本>.<引擎补丁> 都算候选，取版本号最大的那个。
  # ls-remote 会同时给 tag 对象与 Peel 后的 commit 行（refs/tags/x^{}），
  # 后者去掉 ^{} 后与前者同名，sort -u 去重。
  CN_REF="$(git ls-remote --tags "https://github.com/$CN_REPO" 2>/dev/null \
            | awk -v prefix="refs/tags/v$APP_VERSION" '
                { ref = $2; sub(/\^\{\}$/, "", ref)
                  if (ref == prefix || index(ref, prefix ".") == 1) print substr(ref, 11) }' \
            | sort -u | sort -V | tail -1)"
  [[ -n "$CN_REF" ]] || die "汉化引擎还没有适配 Antigravity $APP_VERSION 的 tag（v$APP_VERSION / v$APP_VERSION.x）——等 $CN_REPO 出对应版本再构建，不要拿旧字典硬上"
  echo "  按宿主版本 $APP_VERSION 解析到 tag $CN_REF"
else
  echo "  人工指定 ref：$CN_REF"
fi
# commit 用 /tar.gz/<sha>，tag 用 /tar.gz/refs/tags/<tag>（codeload 两种形态路径不同）。
if [[ "$CN_REF" =~ ^[0-9a-fA-F]{40}$ ]]; then
  CN_TARBALL_URL="https://codeload.github.com/$CN_REPO/tar.gz/$CN_REF"
else
  CN_TARBALL_URL="https://codeload.github.com/$CN_REPO/tar.gz/refs/tags/$CN_REF"
fi
CN="$WORK/cn"
mkdir -p "$CN"
curl -fL --retry 3 "$CN_TARBALL_URL" | tar xz -C "$CN" --strip-components=1
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
echo "  巡检输出锚点异常行：${ANCHOR_FAILS}（字典与注入细节见 /tmp/ag_audit.log）"

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
const must=['package.json','dist/main.js','dist/gyWidgetMain.js','dist/preload.js','dist/gyWidget/characters/characters.json'];
for(const p of must){
  try{const s=fs.readFileSync(base+'/'+p,'utf8'); if(p==='package.json') JSON.parse(s);
      if(p==='dist/preload.js' && !s.includes('__AGY_WIDGET_PAGE_START__')) throw new Error('preload 缺页内挂件块');
      if(p==='dist/preload.js' && !s.includes('__AGY_EXTRA_L10N_START__')) throw new Error('preload 缺补充词典块');}
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
  # 本仓 cask 政策：每个 cask 的 Release 只留最新一个（见 AGENTS.md §11.5）。本包的产物由
  # 脚本构建、不走 updater 的 deleteOldCaskReleases，所以这里自己清同前缀旧 tag。
  # 只认「antigravity- 后接数字」，避免误删别的前缀同名 release。
  say "清理旧 release（只保留 ${TAG}）"
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
  rm -rf "${WORK:?}/mnt" "${WORK:?}/stage" "${WORK:?}/official.dmg"
fi

say "构建完成"
cat <<EOF
版本   ${PATCHED_VERSION}（宿主 $APP_VERSION build ${APP_BUILD}）
引擎   ${CN_REF}（${CN_REPO}）
产物   $OUT_DMG
sha256 $PATCHED_SHA
sidecar $OUT_DMG.sha256

下一步：
  1) 本机验收  brew install --cask ./Casks/antigravity.rb   （或先手改 cask 的 url/sha）
  2) 提交 cask 与 updater/antigravity.swift
  3) 需要自动跟版时手动跑 watch-updates
EOF
