require "digest"

class LlamaCpp < Formula
  desc "LLM inference in C/C++ with the Bemly ToshGEMM fork"
  homepage "https://github.com/Bemly/llama.cpp"
  url "https://github.com/Bemly/llama.cpp/archive/6a6de2cd34a5244916a8032b5d830eaaf0fd4c49.tar.gz"
  sha256 "cbc6b6f9ab7273f5e0690764b43edf54f1a96dc5ecc56387804c39bc8cbe7122"
  version "2026.11.24-6a6de2cd"
  license "MIT"
  compatibility_version 1

  # The fork's hybrid memory caller passes a replay argument that the recurrent constructor does not accept.
  patch do
    file "Patches/llama.cpp/recurrent-constructor.diff"
  end

  depends_on "bemly/tahoe/cmake" => :build
  depends_on "bemly/tahoe/ninja" => :build
  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def merge_metal_source(source)
    source = Pathname(source)
    metal_root = buildpath/"ggml/src/ggml-metal"
    headers = [metal_root/"kernels/common.h"]
    source_text = source.read
    {
      "dequantize.h" => "kernels/dequantize.h",
      "quantize.h" => "kernels/quantize.h",
      "fa_common.metal" => "kernels/fa_common.metal",
      "fa_vec_common.metal" => "kernels/fa_vec_common.metal",
    }.each do |include_name, relative_path|
      headers << metal_root/relative_path if source_text.include?("#include \"#{include_name}\"")
    end

    merged = (headers + [source]).map { |path| path.read }.join("\n")
    merged = merged.lines.reject do |line|
      line.match?(/^\s*#include "(?:common\.h|dequantize\.h|quantize\.h|fa_common\.metal|fa_vec_common\.metal)"\s*$/) ||
        line.match?(/^\s*#pragma once\s*$/)
    end.join

    common = (buildpath/"ggml/src/ggml-common.h").read
    implementation = (metal_root/"ggml-metal-impl.h").read
    merged.gsub!(/^\s*__embed_ggml-common.h__\s*$/) { common + "\n" }
    merged.gsub!(/^\s*#include "ggml-metal-impl.h"\s*$/) { implementation + "\n" }
    merged
  end

  def install
    # The fork's embedded FA symbols are missing from the static archive; ship per-kind metallibs instead.
    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DBUILD_SHARED_LIBS=OFF
      -DLLAMA_OPENSSL=OFF
      -DLLAMA_BUILD_TESTS=OFF
      -DLLAMA_BUILD_TOOLS=ON
      -DLLAMA_BUILD_EXAMPLES=ON
      -DLLAMA_BUILD_SERVER=ON
      -DLLAMA_BUILD_APP=OFF
      -DLLAMA_BUILD_UI=OFF
      -DGGML_METAL=ON
      -DGGML_METAL_EMBED_LIBRARY=OFF
      -DGGML_NATIVE=OFF
      -DTOSH_ENABLE_DYNAMIC_MOE=ON
      -DGGML_SSE42=ON
      -DGGML_AVX=ON
      -DGGML_AVX2=ON
      -DGGML_FMA=ON
      -DGGML_F16C=ON
      -DGGML_BMI2=ON
      -DGGML_AVX_VNNI=OFF
      -DGGML_AVX512=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args,
           "-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0"
    system "cmake", "--build", "build", "--target", "llama-server", "llama-bench", "llama-perplexity"

    %w[llama-server llama-bench llama-perplexity].each do |binary|
      (libexec/"bin").install buildpath/"build/bin/#{binary}"
      bin.install_symlink libexec/"bin/#{binary}" => binary
    end

    kernels = libexec/"bin/kernels"
    kernels.mkpath
    kernel_dir = buildpath/"ggml/src/ggml-metal/kernels"
    merged_dir = buildpath/"metal-merged"
    merged_dir.mkpath
    metal_sources = Dir[kernel_dir/"*.metal"].reject do |source|
      %w[fa_common.metal fa_vec_common.metal].include?(File.basename(source))
    end
    odie "llama.cpp Metal kernels were not generated" if metal_sources.empty?
    metal_sources.each do |source|
      name = File.basename(source, ".metal")
      merged = merged_dir/"#{name}.metal"
      merged.write(merge_metal_source(source))
      air = kernels/"#{name}.air"
      metallib = kernels/"#{name}.metallib"
      system "xcrun", "metal", "-O3", "-mmacosx-version-min=14.0", "-std=metal3.1",
             "-DGGML_METAL_HAS_BF16",
             "-I", "ggml/src", "-I", "ggml/src/ggml-metal",
             "-c", merged, "-o", air
      system "xcrun", "metallib", air, "-o", metallib
      air.unlink
      fingerprint = kernels/"fingerprint"
      fingerprint.write("") unless fingerprint.exist?
      File.open(fingerprint, "a") do |file|
        file.puts "#{name} #{Digest::SHA256.file(merged.to_s).hexdigest}"
      end
    end
  end

  test do
    assert_match "version:", shell_output("#{bin}/llama-server --version 2>&1")
  end
end
