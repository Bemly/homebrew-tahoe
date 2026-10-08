class Cmake < Formula
  desc "Cross-platform make"
  homepage "https://www.cmake.org/"
  # 上游官方 macOS universal 预编译包（内含 x86_64 切片，file 实测），与 cmake.org
  # 同文件三方对账一致（sha256 双源实算相同）。
  # 主 url 用 Kitware GitHub release：全段都是全版本号，无版本目录段——
  # cmake.org 的 /v4.4/ 目录段会让检查器的 url 解析先命中 "4.4"（brew 自身扫描不受
  # 影响，实测 stable 仍为 4.4.4，故不写 version 行，写了判冗余）。
  url "https://github.com/Kitware/CMake/releases/download/v4.4.4/cmake-4.4.4-macos-universal.tar.gz"
  mirror "https://cmake.org/files/v4.4/cmake-4.4.4-macos-universal.tar.gz"
  mirror "http://cmake.org/files/v4.4/cmake-4.4.4-macos-universal.tar.gz"
  # cmake 在 core curl 的递归依赖树里（nghttp3 等构建要它），audit 强制要求至少一条
  # 明文 http 镜像（core 的 cmake 用 fresh-center 同例）；cmake.org 的 http 会 301
  # 到 https，同文件，brew 跟随跳转，纯为过审。
  sha256 "4b7b73704b1db9b374e5c9ab8e17ac6148b817b6396ee75cd94a852cbac9d305"
  license "BSD-3-Clause"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # 上游 universal 包内含 x86_64 切片，满足 Intel 要求。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    ohai "预检 cmake 安装环境（系统门槛由 depends_on 强制）"
  end

  # 上游 tar.gz 是单一顶层目录（cmake-<ver>-macos-universal/），brew 会下降进入，
  # 故直接用 CMake.app 相对路径（gh 同例，不加顶层前缀）。
  # .app 原样进 prefix（Modules 按可执行文件相对路径定位 ../share/cmake-<ver>，
  # 搬家安全）；CLI 只链系统库（otool 实测仅 /usr/lib + 系统 Frameworks），零依赖。
  def install
    prefix.install "CMake.app"
    %w[cmake ccmake cpack ctest].each do |tool|
      bin.install_symlink prefix/"CMake.app/Contents/bin"/tool
    end
    man1.install Dir[prefix/"CMake.app/Contents/man/man1/{cmake,ccmake,cpack,ctest}.1"]
    bash_completion.install Dir[prefix/"CMake.app/Contents/share/bash-completion/completions/{cmake,cpack,ctest}"]

    # 拆箱校验（brew 6 起 post_install 已废弃，校验挪进 install 尾部，见 11.37）：
    # file 认 x86_64 + --version 自检，走最终交付的 bin 软链。
    arch = Utils.safe_popen_read("file", "-b", (bin/"cmake").to_s)
    odie "期望 x86_64，实际：#{arch}" unless arch.include?("x86_64")
    ver = Utils.safe_popen_read((bin/"cmake").to_s, "--version")[/\d+\.\d+\.\d+/]
    odie "cmake --version 自检失败" if ver.blank?
    ohai "cmake #{ver}（#{arch.strip}）"
  end

  def caveats
    <<~EOS
      已链接 cmake / ccmake / cpack / ctest 到 PATH；
      CMake.app 本体在 #{opt_prefix}/CMake.app（GUI 可直接打开）。
      与 homebrew/core 的 cmake 同名不能共存，先 `brew uninstall cmake` 再装本版。
    EOS
  end

  test do
    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION #{version.major_minor})
      project(hello NONE)
      message(STATUS "hello from test")
    CMAKE
    system bin/"cmake", "-S", ".", "-B", "build"
    assert_path_exists testpath/"build/CMakeCache.txt"
  end
end
