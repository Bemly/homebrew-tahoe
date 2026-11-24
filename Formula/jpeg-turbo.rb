class JpegTurbo < Formula
  desc "JPEG image codec that aids compression and decompression"
  homepage "https://www.libjpeg-turbo.org/"
  url "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.2.1/libjpeg-turbo-3.2.1.dmg", using: :nounzip
  sha256 "10cf9233f771089166da8f0d6cd014294ebae93e1212ef033fbc548dc622ce74"
  license all_of: [
    "IJG", # libjpeg API library and programs
    "Zlib", # libjpeg-turbo SIMD source code
    "BSD-3-Clause", # TurboJPEG API library and programs
  ]
  compatibility_version 1

  head "https://github.com/libjpeg-turbo/libjpeg-turbo.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # These conflict with `jpeg`, which is now keg-only.
  link_overwrite "bin/cjpeg", "bin/djpeg", "bin/jpegtran", "bin/rdjpgcom", "bin/wrjpgcom"
  link_overwrite "include/jconfig.h", "include/jerror.h", "include/jmorecfg.h", "include/jpeglib.h"
  link_overwrite "lib/libjpeg.dylib", "lib/libjpeg.so", "lib/libjpeg.a", "lib/pkgconfig/libjpeg.pc"
  link_overwrite "share/man/man1/cjpeg.1", "share/man/man1/djpeg.1", "share/man/man1/jpegtran.1",
                 "share/man/man1/rdjpgcom.1", "share/man/man1/wrjpgcom.1"

  deny_network_access!

  def install
    dmg = Dir["*.dmg"].fetch(0)
    pkg = nil
    sevenzip = Utils.safe_popen_read("which", "7zz").strip
    if !sevenzip.isEmpty
      system sevenzip, "x", "-y", "-o#{buildpath}/dmg", dmg
      pkg = Dir[buildpath/"dmg/**/*.pkg"].fetch(0)
    else
      mount = buildpath/"mnt"
      mount.mkpath
      begin
        system "hdiutil", "attach", "-nobrowse", "-readonly", "-mountpoint", mount.to_s, dmg
        pkg = Dir[mount/"*.pkg"].fetch(0)
      ensure
        Utils.safe_popen_read("hdiutil", "detach", mount.to_s)
      end
    end
    system "pkgutil", "--expand-full", pkg, buildpath/"pkg"
    payload = Dir[buildpath/"pkg/*.pkg/Payload"].fetch(0)
    root = Pathname(payload)/"opt/libjpeg-turbo"
    bin_src = root/"bin"
    lib_src = root/"lib"

    machos = Dir[bin_src/"*", lib_src/"*.dylib", lib_src/"*.a"].reject do |file|
      File.symlink?(file) || File.basename(file) == "uninstall"
    end
    machos.each do |file|
      system "lipo", "-thin", "x86_64", file, "-o", "#{file}.thin"
      File.rename("#{file}.thin", file)
    end

    MachO::Tools.change_dylib_id(lib_src/"libjpeg.62.4.0.dylib", "@rpath/libjpeg.62.4.0.dylib")
    MachO::Tools.change_dylib_id(lib_src/"libturbojpeg.0.5.0.dylib", "@rpath/libturbojpeg.0.5.0.dylib")
    Dir[bin_src/"*", lib_src/"*.dylib"].each do |file|
      next if File.symlink?(file) || File.basename(file) == "uninstall"
      MachO::Tools.change_rpath(file, "/opt/libjpeg-turbo/lib", rpath.to_s)
    end

    bin.install Dir[bin_src/"*"].reject { |file| File.basename(file) == "uninstall" }
    include.install Dir[root/"include/*"]
    lib.install Dir[lib_src/"*"]
    man1.install Dir[root/"man/man1/*"]
    (share/"java").install root/"classes/turbojpeg-jna.jar"
    docs = Pathname(payload)/"Library/Documentation/libjpeg-turbo"
    doc.install docs/"README.md"
    doc.install docs/"LICENSE.md"

    inreplace [lib/"pkgconfig/libjpeg.pc", lib/"pkgconfig/libturbojpeg.pc",
               lib/"cmake/libjpeg-turbo/libjpeg-turboConfig.cmake",
               lib/"cmake/libjpeg-turbo/libjpeg-turboTargets.cmake",
               lib/"cmake/libjpeg-turbo/libjpeg-turboTargets-release.cmake"],
              "/opt/libjpeg-turbo", opt_prefix.to_s

    machos.each do |file|
      next if file.end_with?(".a")
      relative = Pathname(file).relative_path_from(root)
      system "codesign", "--force", "--sign", "-", prefix/relative
    end
  end

  test do
    system bin/"jpegtran", "-crop", "1x1",
                           "-transpose",
                           "-perfect",
                           "-outfile", "out.jpg",
                           test_fixtures("test.jpg")
    assert_path_exists testpath/"out.jpg"
  end
end
