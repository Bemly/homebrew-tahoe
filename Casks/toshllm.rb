cask "toshllm" do
  version "0.88.1"
  sha256 "1f23c70f05038d0eba6a8c5a75fa120a2e0214af3ae4b1b90ae3dfc7a78a6470"

  # 源码构建自 Bemly/toshllm 的固定 commit，watcher 比较 main HEAD，
  # 落后时由 patched.yml 构建 dmg、上传本仓 Release 并回填版本/sha。
  # source: https://github.com/Bemly/toshllm/archive/ffbf427df7edd8c89fb87e42b24d645536193fe6.tar.gz
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/toshllm-#{version}/ToshLLM-v#{version}.dmg"
  name "ToshLLM"
  desc "Run local LLMs on Intel hardware with AMD GPU acceleration"
  homepage "https://github.com/Bemly/toshllm"

  # Intel-only：app 与三个 Metal 引擎均为 thin x86_64，构建时禁用 app 自更新。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "ToshLLM.app"

  uninstall quit: "dev.engel.toshllm"

  caveats <<~EOS
    需要 Intel Mac + 支持 Metal 的 AMD 独立显卡，建议 16 GB 以上内存
    （35B 级 MoE 模型建议 32 GB）。

    本 cask 从 Bemly fork 源码构建，捆绑本 tap 的 llama.cpp、sd.cpp、
    audio.cpp 三个 Metal 引擎；仅支持 AVX2 及更新的 Intel Mac。
  EOS
end
