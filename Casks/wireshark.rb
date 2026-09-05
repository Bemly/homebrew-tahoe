cask "wireshark" do
  version "4.4.18"
  # 上游 Intel 构建停在 4.4 系（4.6+ 无 Intel dmg，只有 arm 包），故版本不跟
  # core 公式 stable（4.6.8），而是跟官方 Sparkle appcast 里带 "Intel 64" 的
  # 那一项；sha256 直接取 appcast 同项注释里的官方值，无需下载 66MB 实算。
  # 镜像到本仓 Release（tag wireshark-<ver>）：注意 GitHub 存资产时把空格
  # 换成点，上游的 "Wireshark <ver> Intel 64.dmg" 存成
  # "Wireshark.<ver>.Intel.64.dmg"，url 必须写点分隔形态，否则 404
  # （checkra1n 同例，2026-09-05 实测）。
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 插值，否则
  # audit 会因"URL 无版本"要求 sha256 :no_check。
  sha256 "84140b6014fb53da2d285482796283e583bf25b0c1d4ed7faee65f1f338a8570"

  url "https://github.com/Bemly/homebrew-tahoe-intel/releases/download/wireshark-#{version}/Wireshark.#{version}.Intel.64.dmg"
  name "Wireshark"
  desc "Network protocol analyzer"
  homepage "https://www.wireshark.org/"

  # 本 tap 只要 Intel：上游按架构分包，Intel 64 dmg 只含 x86_64。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Wireshark.app"
  # 不装这个就抓不了包：/dev/bpf* 默认 root:wheel 600，普通用户打不开。
  # 同 dmg 内的官方包，作用三件套（已拆包验过 postinstall 实物）：
  # 建 access_bpf 组并把 admin 组 + 当前用户加进去，装 LaunchDaemon
  # （org.wireshark.ChmodBPF）开机/装完即改 bpf 设备组归属。装它要弹密码
  # （写 /Library），属正常 cask/pkg 行为。
  pkg "Install ChmodBPF.pkg"
  # Phase 0 要 tshark / editcap：官方 dmg 里它们在 app 包内，随包附带。
  binary "#{appdir}/Wireshark.app/Contents/MacOS/tshark", target: "tshark"
  binary "#{appdir}/Wireshark.app/Contents/MacOS/editcap", target: "editcap"

  uninstall launchctl: "org.wireshark.ChmodBPF",
            quit:      "org.wireshark.Wireshark",
            pkgutil:   "org.wireshark.ChmodBPF.pkg"

  caveats <<~EOS
    抓包权限（ChmodBPF 已随本 cask 安装）：
      安装包把你加进了 access_bpf 组，但组身份要重新登录才生效——
      注销重登一次（或重启），再跑：
        tshark -i lo0 -c 3
      还报 Permission denied 就再登出登入一次；管理员之外的用户需手动
      `sudo dseditgroup -o edit -a <用户名> -t user access_bpf`。
  EOS
end
