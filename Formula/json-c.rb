class JsonC < Formula
  desc "JSON parser for C"
  homepage "https://github.com/json-c/json-c/wiki"
  url "https://s3.amazonaws.com/json-c_releases/releases/json-c-0.19.tar.gz"
  sha256 "37ad0249902e301bd9052bf712e511fcc6acff4ecaad4b5900aad9ce564e26de"
  license "MIT"
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  head "https://github.com/json-c/json-c.git", branch: "master"

  livecheck do
    url :head
    regex(/^json-c[._-](\d+(?:\.\d+)+)(?:[._-]\d{6,8})?$/i)
  end


  depends_on "cmake" => :build

  deny_network_access!

  def install
    # We pass `BUILD_APPS=OFF` since any built apps are never installed. See:
    #   https://github.com/json-c/json-c/blob/master/apps/CMakeLists.txt#L119-L121
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_APPS=OFF", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~'EOS'
      #include <stdio.h>
      #include <json-c/json.h>

      int main() {
        json_object *obj = json_object_new_object();
        json_object *value = json_object_new_string("value");
        json_object_object_add(obj, "key", value);
        printf("%s\n", json_object_to_json_string(obj));
        return 0;
      }
    EOS

    system ENV.cc, "-I#{include}", "test.c", "-L#{lib}", "-ljson-c", "-o", "test"
    assert_equal '{ "key": "value" }', shell_output("./test").chomp
  end
end
