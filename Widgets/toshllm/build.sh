#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

version=""
commit=""
upload=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) version="$2"; shift 2 ;;
    --commit) commit="$2"; shift 2 ;;
    --upload) upload=true; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ "$version" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9a-f]{8}$ ]] || {
  echo "version must be YYYY.MM.DD-<shortsha>" >&2; exit 2;
}
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || {
  echo "commit must be a 40-character SHA" >&2; exit 2;
}
[[ "${version##*-}" == "${commit:0:8}" ]] || {
  echo "version short SHA does not match commit" >&2; exit 2;
}
[[ -n "${GH_TOKEN:-}" ]] || {
  echo "GH_TOKEN is required to verify ToshLLM engine pins" >&2; exit 2;
}

out="$ROOT/.build/toshllm-source"
rm -rf "$out/src"
mkdir -p "$out/src"
archive="$out/toshllm.tar.gz"
curl -fL --retry 3 --retry-delay 3 --max-time 300 \
  "https://github.com/Bemly/toshllm/archive/$commit.tar.gz" -o "$archive"
tar -xzf "$archive" -C "$out/src"
src="$out/src/toshllm-$commit"
[[ -d "$src" ]] || { echo "source directory missing: $src" >&2; exit 1; }

pinned_commit() {
  ruby -e 'text = File.read(ARGV.fetch(0)); match = text.match(%r{/archive/([0-9a-f]{40})\.tar\.gz}); abort "missing pinned commit" unless match; puts match[1]' "Formula/$1.rb"
}

tree_json="$(gh api "repos/Bemly/toshllm/git/trees/$commit?recursive=1")"
for engine in llama.cpp stable-diffusion.cpp audio.cpp; do
  case "$engine" in
    llama.cpp) formula="llama.cpp"; path="vendor/llama.cpp" ;;
    stable-diffusion.cpp) formula="sd.cpp"; path="vendor/stable-diffusion.cpp" ;;
    audio.cpp) formula="audio.cpp"; path="vendor/audio.cpp" ;;
  esac
  expected="$(printf '%s' "$tree_json" | jq -r --arg path "$path" '.tree[] | select(.path == $path) | .sha')"
  actual="$(pinned_commit "$formula")"
  [[ "$expected" =~ ^[0-9a-f]{40}$ ]] || { echo "missing ToshLLM gitlink: $path" >&2; exit 1; }
  [[ "$actual" == "$expected" ]] || {
    echo "$formula pin mismatch: ToshLLM expects $expected, tap pins $actual" >&2
    exit 1
  }
done

taps_dir="$(brew --repository)/Library/Taps/bemly"
mkdir -p "$taps_dir"
ln -sfn "$ROOT" "$taps_dir/homebrew-tahoe"
brew update
brew trust bemly/tahoe
brew install --force-bottle bemly/tahoe/llama.cpp bemly/tahoe/sd.cpp bemly/tahoe/audio.cpp

prefix="$(brew --prefix)"
llama_bin="$prefix/opt/llama.cpp/libexec/bin"
sd_bin="$prefix/opt/sd.cpp/libexec/bin"
audio_bin="$prefix/opt/audio.cpp/libexec/bin"

llama_target="$src/vendor/llama.cpp/build-static/bin"
mkdir -p "$llama_target"
cp "$llama_bin/llama-server" "$llama_bin/llama-bench" "$llama_bin/llama-perplexity" "$llama_target/"
cp -R "$llama_bin/kernels" "$llama_target/"

sd_target="$src/vendor/stable-diffusion.cpp/build-static/bin"
mkdir -p "$sd_target"
cp "$sd_bin/sd-cli" "$sd_bin/sd-server" "$sd_bin/default.metallib" "$sd_target/"

audio_target="$src/vendor/audio.cpp/build-static/bin"
mkdir -p "$audio_target"
cp "$audio_bin/audiocpp_cli" "$audio_bin/audiocpp_server" "$audio_target/"
cp -R "$audio_bin/assets" "$audio_target/"
[[ ! -f "$audio_bin/default.metallib" ]] || cp "$audio_bin/default.metallib" "$audio_target/"

(
  cd "$src"
  CI=1 TOSH_NO_BUMP=1 TOSH_ARCH=x86_64 TOSH_VERSION="$version" TOSH_UPDATES=0 ./make-app.sh
)

app="$src/dist/ToshLLM.app"
[[ -d "$app" ]] || { echo "ToshLLM.app was not produced" >&2; exit 1; }
dmg="$out/ToshLLM-v$version.dmg"
hdiutil create -volname "ToshLLM $version" -srcfolder "$app" -ov -format UDZO "$dmg"
sha="$(shasum -a 256 "$dmg" | awk '{print $1}')"
printf '%s  %s\n' "$sha" "$(basename "$dmg")" > "$dmg.sha256"
printf '%s\n' "$commit" > "$out/commit"

if [[ "$upload" == true ]]; then
  tag="toshllm-$version"
  if gh release view "$tag" --repo Bemly/homebrew-tahoe >/dev/null 2>&1; then
    gh release upload "$tag" "$dmg" "$dmg.sha256" --clobber --repo Bemly/homebrew-tahoe
  else
    gh release create "$tag" "$dmg" "$dmg.sha256" \
      --repo Bemly/homebrew-tahoe \
      --title "ToshLLM $version" \
      --notes "Source build from Bemly/toshllm commit $commit with bottled llama.cpp, sd.cpp and audio.cpp engines."
  fi
fi

echo "ToshLLM source build complete: $dmg"
echo "commit: $commit"
