cask "toshllm" do
  version "0.87.34"
  sha256 "c31752518b16501f3aeeafc237a10b6ebb2db5bc7984cbc4c50e406be0fd225c"

  # 镜像到本仓 Release（tag toshllm-<ver>，资产名沿用上游 basename
  # ToshLLM-v<ver>.dmg）：本 tap 政策是所有 cask 都镜像最新版；
  # url 用 #{version} 双插值（tag 与资产名都带版本），否则 audit 会因
  # "URL 无版本"要求 sha256 :no_check。
  # 版本更新由 updater/toshllm.swift 跟上游 GitHub releases（UpdaterCore
  # github 流），有更新时下载、上传 Release、改写本文件（blender-5x 同机制）。
  # 注意：watcher 的镜像流会把 url 整条换成字面版本（无 #{...} 插值），
  # 而 audit 的 unversioned 检查要求 url 行必须含插值——写回后须手动改回
  # 上面的双插值形态再提交（mirage-wallpaper 同例，见 AGENTS 11.34）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/toshllm-#{version}/ToshLLM-v#{version}.dmg"
  name "ToshLLM"
  desc "Run local LLMs on Intel hardware with AMD GPU acceleration"
  homepage "https://github.com/engeldlgado/toshllm"

  # 上游 app 自带更新器（检查 GitHub releases、下载并安装新版本），
  # 所以 brew upgrade 默认跳过，需要 --greedy 才会强制覆盖。
  auto_updates true
  # Intel-only：包内 138 个 Mach-O 全部为 thin x86_64（无 arm64 切片）；
  # 上游专为 Intel Mac + AMD GPU（Metal）构建，公证签名零拦截。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "ToshLLM.app"

  uninstall quit: "dev.engel.toshllm"

  caveats <<~EOS
    需要 Intel Mac + 支持 Metal 的 AMD 独立显卡，建议 16 GB 以上内存
    （35B 级 MoE 模型建议 32 GB）。

    本 cask 装的是标准 AVX2 构建；2013 年以前不支持 AVX2 的机器
    （如 Mac Pro 5,1）请改用上游的 -noavx2 变体。
  EOS
end
