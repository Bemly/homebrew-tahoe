// GitHub Copilot 桌面版补丁包的启动器（占用 CFBundleExecutable 的名字 github，
// 真正的官方主二进制被改名为 github-real，由本程序 exec 过去）。
//
// 为什么必须有这一层，而不能用 Info.plist 的 LSEnvironment 直接设
// DYLD_INSERT_LIBRARIES=@executable_path/../Resources/CopilotCN/*.dylib：
//   LSEnvironment 的环境会被**所有子进程继承**，而 @executable_path 在子进程里
//   按子进程自己的可执行文件路径展开 → 路径不存在 → dyld 直接 SIGABRT 杀掉子进程。
//   /tmp 探针实测：主进程注入成功，但 system() 起的普通子进程 child_rc=6（SIGABRT）、
//   无任何输出。Copilot 会大量 spawn git / shell / MCP 子进程，这条路会让功能全废。
//   改成启动器后由本程序算出**绝对路径**再 setenv，子进程继承到的路径真实存在，
//   dylib 照常载入（两个注入库都有主程序判定，非主进程直接 return，无副作用），
//   探针实测 child_rc=0、子进程正常输出。
//
// 注入失败绝不拦启动：dylib 缺失时照常 exec 官方二进制（界面回到英文，但能用）。
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <mach-o/dyld.h>

int main(int argc, char **argv) {
  char raw[PATH_MAX];
  uint32_t size = sizeof(raw);
  if (_NSGetExecutablePath(raw, &size) != 0) return 1;
  char self[PATH_MAX];
  if (!realpath(raw, self)) return 1;
  char *slash = strrchr(self, '/');
  if (!slash) return 1;
  *slash = '\0'; /* → Contents/MacOS */

  char target[PATH_MAX];
  snprintf(target, sizeof(target), "%s/github-real", self);

  char gy[PATH_MAX], cn[PATH_MAX], gyAbs[PATH_MAX], cnAbs[PATH_MAX], insert[PATH_MAX * 2 + 2];
  snprintf(gy, sizeof(gy), "%s/../Resources/CopilotCN/GyWidgetCN.dylib", self);
  snprintf(cn, sizeof(cn), "%s/../Resources/CopilotCN/CopilotCN.dylib", self);
  /* GyWidgetCN 必须在前：它的构造函数负责设 COPILOT_CN_DIR 并铺运行时文件。 */
  if (realpath(gy, gyAbs) && realpath(cn, cnAbs)) {
    snprintf(insert, sizeof(insert), "%s:%s", gyAbs, cnAbs);
    setenv("DYLD_INSERT_LIBRARIES", insert, 1);
  }

  char **args = calloc((size_t)argc + 1, sizeof(char *));
  if (!args) return 1;
  args[0] = target;
  for (int i = 1; i < argc; i++) args[i] = argv[i];
  execv(target, args);
  perror("execv github-real");
  return 3;
}
