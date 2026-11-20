// GyWidgetCN.dylib —— Gemini 娘挂件的 WKWebView 注入库（Tauri / GitHub Copilot 桌面版）。
// 与上游 CopilotCN.dylib 同一 hook 手法（swizzle WKWebView initWithFrame:configuration:），
// 但只追加一条 WKUserScript（页内 DOM 宠物，见 gy/pet.js），不碰上游翻译逻辑。
//
// 装载顺序由 Info.plist 的 LSEnvironment DYLD_INSERT_LIBRARIES 保证：本库在前。
// 构造函数里做两件事：
//   1. 用 dladdr 拿本 dylib 自身路径 → 推出包内 Resources/CopilotCN；
//   2. setenv COPILOT_CN_DIR 指向用户数据目录，并把包内 runtime/ 与 gy/pet.js
//      复制过去（缺才补）。上游 CopilotCN.dylib 随后读同一个目录。
//      运行时文件放用户目录而非 bundle：往签名过的 bundle 里写文件会破坏签名封印。
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

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
  if ([exe hasSuffix:@"/Contents/MacOS/github"]) return YES;
  return [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.github.githubapp"];
}

static void GyCopyIfMissing(NSString *src, NSString *dst) {
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:dst]) return;
  [fm createDirectoryAtPath:[dst stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES attributes:nil error:NULL];
  NSError *err = nil;
  if (![fm copyItemAtPath:src toPath:dst error:&err]) {
    GyLog(@"copy failed %@ -> %@: %@", src, dst, err.localizedDescription);
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
      GyCopyIfMissing([gBundleDir stringByAppendingPathComponent:
                          [@"runtime/" stringByAppendingString:name]],
                      [gDataDir stringByAppendingPathComponent:name]);
    }
    NSString *petDst = [gDataDir stringByAppendingPathComponent:@"gy/pet.js"];
    GyCopyIfMissing([gBundleDir stringByAppendingPathComponent:@"gy/pet.js"], petDst);
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
