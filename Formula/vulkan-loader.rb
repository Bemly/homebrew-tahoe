class VulkanLoader < Formula
  desc "Vulkan ICD Loader"
  homepage "https://github.com/KhronosGroup/Vulkan-Loader"
  url "https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/vulkan-sdk-1.4.363.0.tar.gz"
  sha256 "941eff558fc74f248745fb7df367640cf89a8457f216dae498a74ae14b6ba6f7"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/KhronosGroup/Vulkan-Loader.git", branch: "main"

  livecheck do
    url :stable
    regex(/^vulkan-sdk[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "973b33d09459af757b5c53c6f6c66b3f5e5242c8d4c9c7ee4e829c2da82be602"
    sha256 cellar: :any, tahoe: "b1e2b6d493dff9ff5cd6dca1db6dc5adc667aa132158bbdd713dcf9e3cac1beb"
  end

  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  depends_on "vulkan-headers"

  on_linux do
    depends_on "libxrandr" => :build
    depends_on "libx11"
    depends_on "libxcb"
    depends_on "wayland"
  end

  deny_network_access!

  def install
    ENV.prepend_path "PATH", Formula["bemly/tahoe/cmake"].opt_bin
    system "cmake", "-S", ".", "-B", "build",
                    "-DVULKAN_HEADERS_INSTALL_DIR=#{formula_opt_prefix("vulkan-headers")}",
                    "-DCMAKE_INSTALL_INCLUDEDIR=#{formula_opt_include("vulkan-headers")}",
                    "-DCMAKE_INSTALL_SYSCONFDIR=#{etc}",
                    "-DFALLBACK_CONFIG_DIRS=#{etc}/xdg:/etc/xdg",
                    "-DFALLBACK_DATA_DIRS=#{HOMEBREW_PREFIX}/share:/usr/local/share:/usr/share",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <vulkan/vulkan_core.h>
      int main() {
        uint32_t version;
        vkEnumerateInstanceVersion(&version);
        return (version >= VK_API_VERSION_1_1) ? 0 : 1;
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-I#{formula_opt_include("vulkan-headers")}",
                   "-L#{lib}", "-lvulkan"
    system "./test"
  end
end
