#!/usr/bin/env bash
# GitHub Copilot 桌面版 中文补丁 + Gemini 娘挂件 成品构建（bemly/tahoe 破例同 antigravity）
#
#   Widgets/github-copilot-cn/build.sh [--version 1.4.2] [--revision 1]
#                                      [--cn-ref <tag|commit>] [--upload] [--keep-work]
#
# 宿主是 Tauri（WKWebView + brotli 前端嵌在 Mach-O 里），没有 asar 可改：
#   官方 Intel dmg → 复制 app → 编两个 x86_64 注入 dylib（上游 CopilotCN + 本仓 GyWidgetCN）
#   → runtime/词典/宠物 payload 进 Resources/CopilotCN
#   → 官方主二进制改名 github-real，github 位置换成自编译的注入启动器（launcher.c）：
#     它算出 dylib 的**绝对路径**设进 DYLD_INSERT_LIBRARIES 再 exec github-real。
#     不用 Info.plist LSEnvironment + @executable_path：那样子进程继承到的路径按子进程
#     自身展开 → 不存在 → dyld SIGABRT 杀掉子进程（/tmp 探针实测 child_rc=6），
#     Copilot 大量 spawn git/shell/MCP，功能会全废；绝对路径实测 child_rc=0。
#   → 照上游 sign.sh 逐组件 ad-hoc 重签，github-real 与 app 带 disable-library-validation /
#     allow-dyld-environment-variables entitlements（保留 hardened runtime）
#   → 重打 dmg → （可选）传本仓 Release
#
# 运行时文件由 GyWidgetCN 构造函数同步到 ~/Library/Application Support/CopilotCN：
# 往签名过的 bundle 里写文件会破坏签名封印，故数据落用户目录。
# 任一步失败立刻退出，绝不产出半成品；产物只落 .build/ 且不入 git。

set -euo pipefail

WIDGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$WIDGET_DIR/../.." && pwd)"
ZH_REPO="shuhuNB515/githubcopilot-desktop-zh-mac"
# 上游按项目版本打 tag（v1.0.x），机制跨宿主版本稳定；默认跟最大 tag，--cn-ref 可锁定。
CN_REF=""
APP_VERSION=""
REVISION="1"
UPLOAD=false
KEEP_WORK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) APP_VERSION="$2"; shift 2 ;;
    --revision) REVISION="$2"; shift 2 ;;
    --cn-ref) CN_REF="$2"; shift 2 ;;
    --upload) UPLOAD=true; shift ;;
    --keep-work) KEEP_WORK=true; shift ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
die() { printf '\033[31m[失败] %s\033[0m\n' "$1" >&2; exit 1; }

for tool in node curl git xcrun clang codesign hdiutil python3 shasum lipo strings; do
  command -v "$tool" >/dev/null 2>&1 || die "缺少命令：$tool"
done
if [[ "$UPLOAD" == true ]] && ! command -v gh >/dev/null 2>&1; then
  die "缺少命令：gh（--upload 需要）"
fi

CORE_JSON="$(mktemp)"
curl -fsS "https://formulae.brew.sh/api/cask/github-copilot-app.json" -o "$CORE_JSON"
if [[ -z "$APP_VERSION" ]]; then
  APP_VERSION="$(python3 -c "import json;print(json.load(open('$CORE_JSON'))['version'])")"
fi
OFFICIAL_URL="https://github.com/github/app/releases/download/v${APP_VERSION}/GitHub-Copilot-darwin-x64.dmg"
PATCHED_VERSION="${APP_VERSION}-cn${REVISION}"
WORK="${REPO_DIR}/.build/github-copilot-cn/${PATCHED_VERSION}"
DMG_NAME="GitHub-Copilot-${PATCHED_VERSION}.dmg"
OUT_DMG="${REPO_DIR}/.build/github-copilot-cn/${DMG_NAME}"

say "官方包：${APP_VERSION}（Intel 直链，sha 下载实算——core 那份是 arm64 的）"
echo "  直链 $OFFICIAL_URL"
rm -rf "$WORK"
mkdir -p "$WORK"
CACHE_DIR="${REPO_DIR}/.build/github-copilot-cn/cache"
mkdir -p "$CACHE_DIR"
say "下载官方 darwin-x64 dmg"
curl -fL --retry 3 -o "$WORK/official.dmg" "$OFFICIAL_URL"
OFFICIAL_SHA="$(shasum -a 256 "$WORK/official.dmg" | awk '{print $1}')"
CACHE="$CACHE_DIR/official-${OFFICIAL_SHA}.dmg"
if [[ ! -f "$CACHE" ]]; then cp "$WORK/official.dmg" "$CACHE"; fi
echo "  sha256 $OFFICIAL_SHA"

say "挂载并复制 GitHub Copilot.app"
MOUNT="$WORK/mnt"
mkdir -p "$MOUNT"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT" "$WORK/official.dmg" >/dev/null
[[ -d "$MOUNT/GitHub Copilot.app" ]] || die "dmg 内没有 GitHub Copilot.app"
cp -R "$MOUNT/GitHub Copilot.app" "$WORK/"
hdiutil detach "$MOUNT" >/dev/null
APP="$WORK/GitHub Copilot.app"
[[ -f "$APP/Contents/MacOS/github" ]] || die "主二进制不是 Contents/MacOS/github，包结构变了"
file "$APP/Contents/MacOS/github" | grep -q x86_64 || die "官方包不是 x86_64"

say "取中文插件源码"
if [[ -z "$CN_REF" ]]; then
  CN_REF="$(git ls-remote --tags "https://github.com/$ZH_REPO" 2>/dev/null \
            | awk '{ ref=$2; sub(/\^\{\}$/, "", ref); if (ref ~ /^refs\/tags\/v[0-9]/) print substr(ref, 11) }' \
            | sort -u | sort -V | tail -1)"
  [[ -n "$CN_REF" ]] || die "上游没有可用 tag"
  echo "  解析到 tag $CN_REF"
else
  echo "  人工指定 ref：$CN_REF"
fi
if [[ "$CN_REF" =~ ^[0-9a-fA-F]{40}$ ]]; then
  ZH_URL="https://codeload.github.com/$ZH_REPO/tar.gz/$CN_REF"
else
  ZH_URL="https://codeload.github.com/$ZH_REPO/tar.gz/refs/tags/$CN_REF"
fi
ZH="$WORK/zh"
mkdir -p "$ZH"
curl -fL --retry 3 "$ZH_URL" | tar xz -C "$ZH" --strip-components=1
[[ -f "$ZH/src/inject.m" ]] || die "插件源码不完整"

say "编译 x86_64 注入 dylib（上游 CopilotCN + 本仓 GyWidgetCN）"
RES="$APP/Contents/Resources/CopilotCN"
mkdir -p "$RES/runtime" "$RES/gy"
# xcrun 而非裸 clang：开发机上裸 clang 可能找不到 SDK 头文件（stdio.h not found）。
xcrun clang -dynamiclib -fobjc-arc -O2 -arch x86_64 -mmacosx-version-min=11.0 \
  -framework Foundation -framework AppKit -framework WebKit \
  -o "$RES/CopilotCN.dylib" "$ZH/src/inject.m" || die "CopilotCN.dylib 编译失败"
xcrun clang -dynamiclib -fobjc-arc -O2 -arch x86_64 -mmacosx-version-min=11.0 \
  -framework Foundation -framework AppKit -framework WebKit \
  -o "$RES/GyWidgetCN.dylib" "$WIDGET_DIR/widget-inject.m" || die "GyWidgetCN.dylib 编译失败"
for dy in "$RES/CopilotCN.dylib" "$RES/GyWidgetCN.dylib"; do
  lipo -archs "$dy" | grep -q x86_64 || die "$dy 不是 x86_64"
  codesign --force --sign - "$dy" >/dev/null 2>&1 || die "$dy 签名失败"
done
echo "  两个 dylib 均为 x86_64 且已 ad-hoc 签名"

say "词典与运行时文件"
DICT_LOG="$(python3 "$ZH/tools/build_dict.py" 2>&1)" || die "dict.json 重建失败：$DICT_LOG"
echo "  $DICT_LOG"
for f in dict.json translator.js bridge.js collector.js menu.json; do
  [[ -f "$ZH/runtime/$f" ]] || die "缺少 runtime/$f"
  cp "$ZH/runtime/$f" "$RES/runtime/$f"
done
python3 - "$RES/runtime/dict.json" <<'PY' || die "词典自检未通过"
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
# 上游 v1.0.1 实测 504 条 / 39KB（DUP 行是上游自带的重复键，正常）。
# 下限取 300：只拦「词典几乎为空」的真故障，不拿猜测的条目数当门。
if not isinstance(d, dict) or len(d) < 300:
    raise SystemExit(f"词典条目异常：{len(d) if isinstance(d, dict) else type(d)}")
print(f"  词典自检通过：{len(d)} 条")
PY
cp "$ZH/src/ent.plist" "$WORK/ent.plist"
cp "$ZH/src/ent-git-credential.plist" "$WORK/ent-git-credential.plist"
grep -q disable-library-validation "$WORK/ent.plist" || die "entitlements 缺 disable-library-validation"
grep -q allow-dyld-environment-variables "$WORK/ent.plist" || die "entitlements 缺 allow-dyld-environment-variables"

say "生成宠物 payload（内置角色 base64 + 语录）"
node - "$WIDGET_DIR" "$RES/gy/pet.js" <<'JS'
const fs = require('fs');
const path = require('path');
const [widgetDir, out] = process.argv.slice(2);
const charsDir = path.join(widgetDir, '..', 'antigravity-niang', 'characters');
const cat = JSON.parse(fs.readFileSync(path.join(charsDir, 'characters.json'), 'utf8'));
const mime = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.avif': 'image/avif', '.bmp': 'image/bmp' };
const characters = cat.characters.map((c) => {
  const file = path.join(charsDir, c.file);
  return { id: c.id, name: c.name, dataUrl: 'data:' + (mime[path.extname(file).toLowerCase()] || 'image/png') + ';base64,' + fs.readFileSync(file).toString('base64') };
});
const quotes = JSON.parse(fs.readFileSync(path.join(widgetDir, '..', 'antigravity-niang', 'assets', 'quotes.json'), 'utf8')).quotes || [];
const tpl = fs.readFileSync(path.join(widgetDir, 'pet-template.js'), 'utf8');
if (!tpl.includes('__PAYLOAD__')) throw new Error('pet-template.js 缺 __PAYLOAD__ 占位');
fs.writeFileSync(out, tpl.replace('__PAYLOAD__', JSON.stringify({ characters, quotes })));
console.log('  角色 ' + characters.length + ' 个 / 语录 ' + quotes.length + ' 条 → gy/pet.js');
JS
grep -q __PAYLOAD__ "$RES/gy/pet.js" && die "payload 占位未被替换"

say "启动器：官方主二进制改名 github-real，github 位置换成注入启动器"
# 不用 Info.plist LSEnvironment：@executable_path 形态的 DYLD_INSERT_LIBRARIES 会被
# 子进程继承并按子进程路径展开 → 路径不存在 → dyld SIGABRT 杀子进程（/tmp 探针实测
# child_rc=6）。启动器算绝对路径再 setenv，子进程继承到真实路径，实测 child_rc=0。
PLIST="$APP/Contents/Info.plist"
[[ "$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$PLIST")" == "github" ]] \
  || die "CFBundleExecutable 不是 github，包结构变了"
/usr/libexec/PlistBuddy -c "Delete :LSEnvironment" "$PLIST" >/dev/null 2>&1 || true
mv "$APP/Contents/MacOS/github" "$APP/Contents/MacOS/github-real"
xcrun clang -O2 -arch x86_64 -mmacosx-version-min=11.0 \
  -o "$APP/Contents/MacOS/github" "$WIDGET_DIR/launcher.c" || die "启动器编译失败"
chmod 0755 "$APP/Contents/MacOS/github"
lipo -archs "$APP/Contents/MacOS/github" | grep -q x86_64 || die "启动器不是 x86_64"
echo "  github（启动器）+ github-real（官方主二进制）就位"

say "注入物完整性门（缺一即不产出）"
for f in CopilotCN.dylib GyWidgetCN.dylib runtime/dict.json runtime/translator.js \
         runtime/bridge.js runtime/collector.js runtime/menu.json gy/pet.js; do
  [[ -s "$RES/$f" ]] || die "注入物缺失或为空：CopilotCN/$f"
done
[[ -s "$APP/Contents/MacOS/github-real" ]] || die "官方主二进制丢失"
strings "$APP/Contents/MacOS/github" | grep -q 'github-real' || die "启动器二进制里没有 github-real 路径"

say "ad-hoc 重签（照上游 src/sign.sh：组件逐个签，主程序带注入 entitlements）"
# 不用 --deep 一把梭：--deep 会把主程序的 entitlements 灌给所有嵌套代码，
# 而上游对 git-credential-copilot / computer-use 用的是另一份 entitlements。
# 主程序保留 hardened runtime（--options runtime）：注入靠的是
# disable-library-validation + allow-dyld-environment-variables 两条例外 entitlement，
# 不是靠丢硬化运行时（antigravity 那边丢 runtime 是因为压根没传 entitlements）。
C="$APP/Contents"
sign_one() {
  codesign --force --sign - --timestamp=none "$@" >/dev/null 2>&1 || die "签名失败：$*"
}
for dy in "$C/Frameworks/"*.dylib; do
  [[ -f "$dy" ]] || continue
  sign_one "$dy"
done
if [[ -f "$C/MacOS/git-credential-copilot" ]]; then
  sign_one --options runtime --entitlements "$WORK/ent-git-credential.plist" "$C/MacOS/git-credential-copilot"
fi
if [[ -f "$C/Resources/plugins/computer-use/computer-use-mcp" ]]; then
  sign_one --options runtime "$C/Resources/plugins/computer-use/computer-use-mcp"
fi
if [[ -d "$C/Resources/plugins/computer-use/Copilot Computer Use.app" ]]; then
  sign_one --deep --options runtime "$C/Resources/plugins/computer-use/Copilot Computer Use.app"
fi
# 真正被注入的是 github-real（启动器 exec 过去的主二进制）：它必须自己带
# disable-library-validation + allow-dyld-environment-variables，否则 dyld 会剥掉
# 启动器设的 DYLD_INSERT_LIBRARIES。不带 --deep 的 codesign 不会重签嵌套 Mach-O，
# 所以这里显式签一次（/tmp 探针实测：先签 github-real 再签 app，entitlements 保留）。
sign_one --options runtime --entitlements "$WORK/ent.plist" "$C/MacOS/github-real"
sign_one --options runtime --entitlements "$WORK/ent.plist" "$APP"
codesign --verify --deep "$APP" >/dev/null 2>&1 || die "重签后 codesign --verify 未通过"
codesign -d --entitlements :- "$APP" 2>/dev/null | grep -q disable-library-validation || die "entitlements 未生效"
codesign -d --entitlements :- "$APP" 2>/dev/null | grep -q allow-dyld-environment-variables || die "缺 allow-dyld-environment-variables"
codesign -d --entitlements :- "$C/MacOS/github-real" 2>/dev/null | grep -q allow-dyld-environment-variables \
  || die "github-real 缺 allow-dyld-environment-variables（注入会被 dyld 剥掉）"
echo "  签名与 entitlements 校验通过"

say "重打 dmg"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
mv "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$OUT_DMG"
hdiutil create -volname "GitHub Copilot" -srcfolder "$STAGE" -ov -format UDZO "$OUT_DMG" >/dev/null
[[ -f "$OUT_DMG" ]] || die "dmg 生成失败"
PATCHED_SHA="$(shasum -a 256 "$OUT_DMG" | awk '{print $1}')"
printf '%s  %s\n' "$PATCHED_SHA" "$DMG_NAME" > "$OUT_DMG.sha256"
echo "  $DMG_NAME $(stat -f%z "$OUT_DMG") B"
echo "  sha256 $PATCHED_SHA"

if [[ "$UPLOAD" == true ]]; then
  say "上传到本仓 Release：tag github-copilot-app-$PATCHED_VERSION"
  TAG="github-copilot-app-$PATCHED_VERSION"
  if gh release view "$TAG" --repo bemly/homebrew-tahoe >/dev/null 2>&1; then
    gh release upload "$TAG" --clobber --repo bemly/homebrew-tahoe "$OUT_DMG" "$OUT_DMG.sha256"
  else
    gh release create "$TAG" --repo bemly/homebrew-tahoe --title "$TAG" \
      --notes-file "$WIDGET_DIR/RELEASE-NOTES.template" \
      "$OUT_DMG#$DMG_NAME" "$OUT_DMG.sha256#$(basename "$OUT_DMG").sha256"
  fi
  say "清理旧 release（只保留 ${TAG}）"
  gh release list --repo bemly/homebrew-tahoe --json tagName --jq '.[].tagName' \
    --limit 200 2>/dev/null | while read -r old; do
      if [[ "$old" == github-copilot-app-* && "$old" != "$TAG" && "${old#github-copilot-app-}" =~ ^[0-9] ]]; then
        echo "  删除 $old"
        gh release delete "$old" --yes --repo bemly/homebrew-tahoe || echo "  警告：删除 $old 失败（不阻断）"
      fi
    done
  echo "  已上传"
fi

if [[ "$KEEP_WORK" != true ]]; then
  rm -rf "$WORK/mnt" "$WORK/stage" "$WORK/official.dmg"
fi

say "构建完成"
cat <<EOF
版本   ${PATCHED_VERSION}（宿主 ${APP_VERSION}）
插件   ${CN_REF}（${ZH_REPO}）
产物   $OUT_DMG
sha256 $PATCHED_SHA
sidecar $OUT_DMG.sha256
EOF
