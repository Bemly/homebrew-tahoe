class Workbuddy < Formula
  desc "Tencent WorkBuddy AI office workspace app (Intel x86_64 for macOS Tahoe)"
  homepage "https://www.workbuddy.cn/"
  # 版本号由 brew 从 URL 扫描得出（四段构建号，实测扫描正确，不重复声明）。
  # URL 指向官方 zip（Electron 自动更新接口给的直链）；文件名带版本 + 构建哈希，
  # 每次部署都变，由 updater/workbuddy.swift 整条更新。
  # 不用 dmg：brew 6.0.21 的 DmgUnpackStrategy 在遇到 dmg 里指向 /Applications 的
  # 符号链接时会调不存在的 MacOS.system_dir? 直接崩（上游 bug），zip 解包无此问题。
  url "https://download.codebuddy.cn/workbuddy/saas/darwin-x64/WorkBuddy-darwin-x64-5.4.7.37521366-b148bd1d.zip"
  # API 的 sha256hash 是 dmg 的（实测与 zip 不符），此值为 zip 本地实算
  sha256 "fbeca76ea4f7a92076c14717fd65a6249047f9cb1701bb70f10dbd4bdee0ba26"
  # 腾讯闭源分发包：不声明 license——闭源无 SPDX 标识可填，audit 对缺省 license 不检查
  # （实测符号 :cannot_redistribute 与字符串 "Proprietary" 均被 audit --strict 拒绝）

  # Mach-O magic 的十六进制（unpack1("H8")）：thin feedface/feedfacf 及各自小端序，
  # fat cafebabe/bebafeca。用 hex 字符串比较，避开 binary/UTF-8 编码不匹配的坑（实测踩过）
  MACH_O_MAGICS = %w[
    feedface feedfacf cefaedfe cffaedfe cafebabe bebafeca
  ].freeze

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # Homebrew 官方不为 Tahoe 构建 x86_64 bottle，这里直接引用上游官方发布包。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # Electron app 全部走 @rpath 自包含加载。不声明的话 --build-bottle 会把 @rpath
  # install name 改写成更长的通用路径，Electron Framework 的 load command header
  # 已满装不下，报 "Updated load commands do not fit in the header"（CI 实测）。
  preserve_rpath

  # Electron app：zip 465MB / 解压约 1.07GB（3442 个文件），Cellar 拷贝再加一份，
  # 磁盘峰值约 2.5GB，留足余量
  def pre_install
    required_mb = 3072
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 WorkBuddy #{version}（Intel x86_64）"
  end

  def install
    # zip 里原本有 __MACOSX 垃圾目录，brew 过滤后只剩唯一顶层目录 WorkBuddy.app，
    # 于是 staging 会下降进 app 内部（11.1 的变体）：CWD 就是 app 根。
    # 双分支兼容「已下降」与「未下降」两种布局。
    if File.exist?("Contents/Info.plist")
      (prefix/"WorkBuddy.app").install Dir["*"]
    else
      prefix.install Dir["**/WorkBuddy.app"].fetch(0)
    end

    # dylib id 治理：app 里有三类「brew 修不动」的 dylib id——
    #   1. Chromium ANGLE 库的相对路径 id（./libEGL.dylib / ./libGLESv2.dylib）；
    #   2. @loader_path 形态 id（libffmpeg.dylib）——preserve_rpath 只保 @rpath，
    #      其余 @ 形态仍会被 brew 改写；
    #   3. QimeiSDKMac.framework 等绝对路径 id（上游构建产物）。
    # brew --build-bottle 会把上述 id 统一改写成 ~80 字符的 /usr/local/opt 绝对路径，
    # header 已满的文件直接崩（CI 实测 "Updated load commands do not fit in the header"）。
    # 预先把全部非 @rpath 的 dylib id 统一改写为 @rpath/<basename>：dylib id 只是加载
    # 身份，没有任何 load command 按旧 id 引用，改写无副作用；配合上面的 preserve_rpath
    # 让链接修复完全无操作。改写过的文件必须 ad-hoc 重签，否则 dyld 会因签名失效拒载。
    (prefix/"WorkBuddy.app").find do |file|
      next unless file.file?

      # Mach-O magic 预过滤（十六进制比较，见 MACH_O_MAGICS 注释）
      next unless MACH_O_MAGICS.include?(file.read(4).to_s.unpack1("H8"))

      begin
        macho = MachO.open(file.to_s)
      rescue MachO::MachOError, EOFError
        next
      end

      slices = macho.respond_to?(:machos) ? macho.machos.select(&:dylib?) : [macho].select(&:dylib?)
      next if slices.empty?
      next unless slices.any? { |s| !s.dylib_id.start_with?("@rpath", "/usr/lib/swift") }

      new_id = "@rpath/#{File.basename(slices.first.dylib_id)}"
      MachO::Tools.change_dylib_id(file.to_s, new_id)
      system "/usr/bin/codesign", "--force", "--sign", "-", file
    end

    # CLI 启动入口：workbuddy == open -a <Cellar 里的 app>
    (bin/"workbuddy").write <<~EOS
      #!/bin/bash
      exec /usr/bin/open -a "#{prefix}/WorkBuddy.app" "$@"
    EOS
  end

  def post_install
    plist = prefix/"WorkBuddy.app/Contents/Info.plist"
    executable = Utils.safe_popen_read("/usr/libexec/PlistBuddy",
                                       "-c", "Print CFBundleExecutable", plist).strip
    binary = prefix/"WorkBuddy.app/Contents/MacOS"/executable

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", binary.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{binary} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检：Info.plist 只有三段，公式版本是四段（构建号），做前缀比对兜底确认原料没拿错
    plist_version = Utils.safe_popen_read("/usr/libexec/PlistBuddy",
                                          "-c", "Print CFBundleShortVersionString", plist).strip
    if plist_version != version.to_s && !version.to_s.start_with?("#{plist_version}.")
      opoo "版本自检未通过：期望 #{version}（或其三段前缀），实际 #{plist_version}"
    end

    ohai "WorkBuddy #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      WorkBuddy 已安装为 Intel(x86_64) 原生应用，直接取自官方 zip 包（不重新编译）。

      启动方式：
        workbuddy                # 本包提供的命令行入口
        open -a "#{prefix}/WorkBuddy.app"

      app 装在 Cellar 里，Spotlight/Launchpad 找不到它。想进启动台可手动软链：
        ln -s "#{prefix}/WorkBuddy.app" /Applications/WorkBuddy.app
      （升级后软链目标随 keg 更新，无需重建）

      与手动安装的 WorkBuddy 互斥：/Applications 里若已有同名 app，
      brew 的软链会失败，二选一即可（数据都在 ~/Library/Application Support，互不影响）。
    EOS
  end

  test do
    app = prefix/"WorkBuddy.app"
    plist = app/"Contents/Info.plist"
    executable = Utils.safe_popen_read("/usr/libexec/PlistBuddy",
                                       "-c", "Print CFBundleExecutable", plist).strip

    assert_path_exists app/"Contents/MacOS"/executable
    assert_match "x86_64", shell_output("/usr/bin/file -b #{app}/Contents/MacOS/#{executable}")

    # Info.plist 三段版本必须是公式四段版本的前缀
    plist_version = Utils.safe_popen_read("/usr/libexec/PlistBuddy",
                                          "-c", "Print CFBundleShortVersionString", plist).strip
    assert_match(/^#{Regexp.escape(plist_version)}/, version.to_s)
  end
end
