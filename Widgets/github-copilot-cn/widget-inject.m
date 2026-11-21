// GyWidgetCN.dylib —— Gemini 娘挂件的 WKWebView 注入库（Tauri / GitHub Copilot 桌面版）。
// 与上游 CopilotCN.dylib 同一 hook 手法（swizzle WKWebView initWithFrame:configuration:），
// 但只追加一条 WKUserScript（页内 DOM 宠物，见 gy/pet.js），不碰上游翻译逻辑。
//
// 装载顺序由启动器（launcher.c）设的 DYLD_INSERT_LIBRARIES 绝对路径列表保证：本库在前。
// 构造函数里做三件事：
//   1. 用 dladdr 拿本 dylib 自身路径 → 推出包内 Resources/CopilotCN；
//   2. setenv COPILOT_CN_DIR 指向用户数据目录，并把包内 runtime/ 与 gy/pet.js
//      同步过去（每次启动覆盖，升级后词典/宠物跟着换）。上游 CopilotCN.dylib 随后读同一目录。
//      运行时文件放用户目录而非 bundle：往签名过的 bundle 里写文件会破坏签名封印。
//   3. swizzle WKWebView initWithFrame:configuration:，追加宠物的 WKUserScript。
// 子进程也会载入本库（启动器设的是绝对路径，继承后仍有效），GyIsMainApp 挡住，无副作用。
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

static NSString *gBundleDir = nil;
static NSString *gDataDir = nil;
static NSString *gPetSource = nil;
static id (*gOrigInit)(id, SEL, CGRect, WKWebViewConfiguration *);

static void GyLog(NSString *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:ap];
  va_end(ap);
  NSLog(@"[gyWidgetCN] %@", msg);
}

static BOOL GyIsMainApp(void) {
  char buf[4096];
  uint32_t size = sizeof(buf);
  if (_NSGetExecutablePath(buf, &size) != 0) return NO;
  NSString *exe = [NSString stringWithUTF8String:buf];
  // 只认真主进程（补丁包里官方主二进制被改名为 github-real，github 位置是启动器）。
  // **不要**用 mainBundle.bundleIdentifier 兜底：bundle 内的 helper
  // （git-credential-copilot 等）bundle id 同样是 com.github.githubapp，会误判成主程序，
  // 进而与主进程并发覆盖用户目录的词典/宠物（实测 remove/copy 竞态报错）。
  // 主二进制名字由 build.sh 自己改名控制，不依赖上游命名稳定。
  return [exe hasSuffix:@"/Contents/MacOS/github"] || [exe hasSuffix:@"/Contents/MacOS/github-real"];
}

// 每次启动都用包内版本覆盖用户目录的运行时文件：这些是包自带的只读数据
// （词典/翻译脚本/宠物 payload），升级后必须跟着换，否则旧词典会一直留着。
// 用户自己的数据在 dumps/queue/日志与宠物的 localStorage 里，不受影响。
// 覆盖走「同目录临时文件 + rename」原子替换：直接 remove+copy 会有窗口期让
// 正在读词典的进程读到缺失文件，多实例并发时还会互相踩。
static void GySyncFile(NSString *src, NSString *dst) {
  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:src]) {
    GyLog(@"missing bundle file %@", src);
    return;
  }
  [fm createDirectoryAtPath:[dst stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES attributes:nil error:NULL];
  NSString *tmp = [dst stringByAppendingFormat:@".tmp-%d", getpid()];
  NSError *err = nil;
  if (![fm copyItemAtPath:src toPath:tmp error:&err]) {
    GyLog(@"copy failed %@ -> %@: %@", src, tmp, err.localizedDescription);
    return;
  }
  if (rename(tmp.fileSystemRepresentation, dst.fileSystemRepresentation) != 0) {
    GyLog(@"rename failed %@ -> %@: %s", tmp, dst, strerror(errno));
    [fm removeItemAtPath:tmp error:NULL];
  }
}

static void GyAttach(WKWebViewConfiguration *cfg) {
  if (!cfg || !gPetSource.length) return;
  WKUserContentController *ucc = cfg.userContentController;
  if (!ucc) {
    ucc = [[WKUserContentController alloc] init];
    cfg.userContentController = ucc;
  }
  WKUserScript *us = [[WKUserScript alloc] initWithSource:gPetSource
                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                       forMainFrameOnly:YES];
  [ucc addUserScript:us];
}

static id GyInitWithFrameConfig(id self, SEL _cmd, CGRect frame, WKWebViewConfiguration *cfg) {
  @try {
    GyAttach(cfg);
  } @catch (NSException *e) {
    GyLog(@"attach exception: %@", e);
  }
  return gOrigInit(self, _cmd, frame, cfg);
}

__attribute__((constructor))
static void GyCtor(void) {
  @autoreleasepool {
    if (!GyIsMainApp()) return;
    Dl_info info;
    if (!dladdr((void *)&GyCtor, &info) || !info.dli_fname) return;
    gBundleDir = [[NSString stringWithUTF8String:info.dli_fname] stringByDeletingLastPathComponent];
    gDataDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/CopilotCN"];
    setenv("COPILOT_CN_DIR", gDataDir.UTF8String, 1);

    for (NSString *name in @[@"dict.json", @"translator.js", @"bridge.js", @"collector.js", @"menu.json"]) {
      GySyncFile([gBundleDir stringByAppendingPathComponent:
                     [@"runtime/" stringByAppendingString:name]],
                 [gDataDir stringByAppendingPathComponent:name]);
    }
    NSString *petDst = [gDataDir stringByAppendingPathComponent:@"gy/pet.js"];
    GySyncFile([gBundleDir stringByAppendingPathComponent:@"gy/pet.js"], petDst);
    gPetSource = [NSString stringWithContentsOfFile:petDst encoding:NSUTF8StringEncoding error:NULL];
    GyLog(@"injected pid=%d bundle=%@ data=%@ pet=%lu bytes",
          getpid(), gBundleDir, gDataDir, (unsigned long)gPetSource.length);

    Method m = class_getInstanceMethod(NSClassFromString(@"WKWebView"),
                                       @selector(initWithFrame:configuration:));
    if (!m) {
      GyLog(@"WKWebView not found, abort");
      return;
    }
    gOrigInit = (void *)method_getImplementation(m);
    method_setImplementation(m, (IMP)GyInitWithFrameConfig);
  }
}
