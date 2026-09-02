#!/usr/bin/env bash
#
# 检查 homebrew/core 中某个 formula 的版本是否已更新，若更新则改写本地公式。
#
# 设计约束（务必遵守）：
#   1. 只由 .github/workflows/watch-updates.yml 手动触发，没有定时/cron。
#   2. 版本来源用 formulae.brew.sh，不碰 GitHub API，不消耗 API 限额。
#   3. sha256 优先从上游 checksums.txt（约 2KB）取，避免下载 15MB 的发布包。
#   4. 每个软件最多 1 次版本查询 + 1 次小文件请求，失败才回退到大文件下载。
#
# 用法： ./scripts/check-updates.sh gh
#
set -euo pipefail

FORMULA="${1:-gh}"
FORMULA_FILE="Formula/${FORMULA}.rb"

# GITHUB_OUTPUT 在本地运行时不存在，退回 stdout 方便人肉执行
OUT="${GITHUB_OUTPUT:-/dev/stdout}"

emit() { echo "$1" >> "$OUT"; }
fail() { echo "::error::$1"; exit 1; }
info() { echo "$1"; }

[[ -f "$FORMULA_FILE" ]] || fail "找不到公式文件：$FORMULA_FILE"

# ---------------------------------------------------------------- 1. 本地版本
# 公式按 Homebrew 规范不声明显式 version（让 brew 从 URL 扫描），所以优先读
# version 行，读不到再从 url 行里提取版本号。
current=$(sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p' "$FORMULA_FILE" | head -1)
if [[ -z "$current" ]]; then
  current=$(sed -nE 's|^[[:space:]]*url ".*[v_]([0-9]+\.[0-9]+\.[0-9]+).*|\1|p' "$FORMULA_FILE" | head -1)
fi
[[ -n "$current" ]] || fail "无法从 $FORMULA_FILE 解析当前版本号"
info "本地版本 : $current"

# ------------------------------------------------------- 2. brew 上游版本
# formulae.brew.sh 由 Homebrew 官方维护，与 core tap 同步，且不占用 GitHub 限额
api_url="https://formulae.brew.sh/api/formula/${FORMULA}.json"
stable=$(curl -fsSL --retry 2 --retry-delay 3 --max-time 30 "$api_url" | jq -r '.versions.stable')
[[ -n "$stable" && "$stable" != "null" ]] || fail "无法从 formulae.brew.sh 获取 ${FORMULA} 的 stable 版本"
info "brew 版本 : $stable"

# ------------------------------------------------------------- 3. 版本比较
if [[ "$current" == "$stable" ]]; then
  info "已是最新，无需更新。"
  emit "status=up-to-date"
  emit "current_version=$current"
  exit 0
fi

newest=$(printf '%s\n%s\n' "$current" "$stable" | sort -V | tail -1)
if [[ "$newest" != "$stable" ]]; then
  info "本地版本($current) 比 brew 版本($stable) 更新，保持不动。"
  emit "status=newer-than-brew"
  emit "current_version=$current"
  exit 0
fi

info "发现新版本 : $current -> $stable"

# --------------------------------------------- 4. 解析该软件的上游发布信息
# 新增软件时在此登记：资源文件名、下载 URL、可选的 checksums 文件
asset=""
download_url=""
checksums_url=""

case "$FORMULA" in
  gh)
    asset="gh_${stable}_macOS_amd64.zip"
    download_url="https://github.com/cli/cli/releases/download/v${stable}/${asset}"
    checksums_url="https://github.com/cli/cli/releases/download/v${stable}/gh_${stable}_checksums.txt"
    ;;
  *)
    fail "软件 $FORMULA 尚未在 scripts/check-updates.sh 中登记上游信息"
    ;;
esac

# ------------------------------------------ 4.5 确认新版本资源确实可下载
# HEAD 请求，几乎不产生流量；取不到时告警并把状态交给 workflow 开 issue，而不是硬失败
if ! curl -fsI --retry 2 --retry-delay 3 --max-time 30 "$download_url" >/dev/null 2>&1; then
  echo "::warning::新版本资源不可下载：$download_url"
  emit "status=upstream-missing"
  emit "current_version=$current"
  emit "new_version=$stable"
  exit 0
fi

# ------------------------------------------------------------ 5. 计算 sha256
sha=""
if [[ -n "$checksums_url" ]]; then
  sha=$(curl -fsSL --retry 2 --retry-delay 3 --max-time 30 "$checksums_url" |
    awk -v f="$asset" '$2==f {print $1}' | head -1)
  [[ -n "$sha" ]] && info "sha256（取自 checksums.txt，仅 2KB）：$sha"
fi

if [[ -z "$sha" ]]; then
  info "checksums.txt 不可用，回退：下载发布包后本地计算 sha256"
  sha=$(curl -fsSL --retry 2 --retry-delay 3 --max-time 300 "$download_url" | shasum -a 256 | cut -d' ' -f1)
fi

[[ "$sha" =~ ^[0-9a-f]{64}$ ]] || fail "得到的 sha256 不合法：$sha"

# ------------------------------------------------------------ 6. 改写公式
escaped_current=$(printf '%s' "$current" | sed 's/\./\\./g')
tmp="${FORMULA_FILE}.tmp"

sed -E \
  -e "s|^([[:space:]]*)sha256 \"[0-9a-f]{64}\"|\1sha256 \"${sha}\"|" \
  -e "s/${escaped_current}/${stable}/g" \
  "$FORMULA_FILE" > "$tmp"

mv "$tmp" "$FORMULA_FILE"

# 版本变了，旧 bottle 块的 sha256 立刻失效，先摘掉；
# 由 bottle.yml 重新制瓶后写回。重建之前 brew 会回退到 url 直链。
bottle_stale=false
if grep -q "^[[:space:]]*bottle do" "$FORMULA_FILE"; then
  sed '/^[[:space:]]*bottle do$/,/^[[:space:]]*end$/d' "$FORMULA_FILE" > "$tmp" && mv "$tmp" "$FORMULA_FILE"
  bottle_stale=true
  info "已摘除失效的 bottle 块（其 sha256 属于旧版本），需重跑 bottle workflow 重建 GHCR 瓶"
fi

# ------------------------------------------------------------ 7. 改后自检
# 公式不声明显式 version，版本号体现在 url 里，因此校验 url 而非 version 行
grep -q "v${stable}/${asset}" "$FORMULA_FILE" || fail "url 未成功更新到 ${stable}"
grep -q "sha256 \"${sha}\"" "$FORMULA_FILE" || fail "sha256 未成功更新"

info "公式已更新：$current -> $stable"

emit "status=updated"
emit "current_version=$current"
emit "new_version=$stable"
emit "sha256=$sha"
emit "bottle_stale=$bottle_stale"
