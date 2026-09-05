// updater/UpdaterCore.swift
//
// 批量版本检查的共享核心。各包的 <name>.swift（与 Formula/<name>.rb 一一同名）是
// 唯一含 @main 入口的文件，只声明自己的上游配置；全部逻辑集中在本文件。
//
// 运行方式（CI 与本地一致）：
//   swiftc updater/UpdaterCore.swift updater/<name>.swift -o /tmp/check-<name> && /tmp/check-<name>
// 两个实测结论（勿改回）：
//   1. 解释器模式 `swift Core.swift <name>.swift` 会静默跳过第二个文件的顶层代码
//      （exit 0 但什么都不做），不能用；
//   2. swiftc 只允许 main.swift 含裸的顶层代码，所以各包入口用 @main 结构体。
//
// 版本来源四种（CheckConfig 四选一，优先级 customRelease > raw > github > brew）：
//   - brew 流：formulae.brew.sh 的 versions.stable 判新。url/sha 两种给法：
//       a) 模板式：downloadURL/asset/checksumsURL 指向上游产物与汇总清单
//          （gh / fastfetch / node 家族，sha 走 checksums.txt）；
//       b) 全量式：只给 brewName，url 与 sha256 直取 JSON 的 urls.stable.url
//          / .checksum——这两个值就是 core 公式 url 行指向的真实上游直链与
//          其 sha256（Homebrew 维护），随上游换镜像自动跟随，免维护模板
//          （qemu 及其依赖树，2026-09-03 起）。
//   - raw 流：源 tap 仓库的公式 raw 文本（如 anomalyco/homebrew-tap 的
//     <name>.rb），核心按 GoReleaser 结构解析 version + Intel mac 的 url/sha256
//     （opencode / sst / torpedo，2026-09-04 起）。不消耗 GitHub API 限额
//     （走 raw.githubusercontent.com），sha 直接取自源文件，无需下载。
//     置 rawDualArch 即双架构 raw（opencode）：mac 的 intel/arm 双块各取各的
//     url/sha，走 runRawDualCheck（改写公式内双 `if Hardware::CPU` 块）。
//   - github 流：直接跟踪 GitHub release（不在 brew core、又无自有更新接口的
//     软件，如 BrewUI）。版本判据是 releases/latest 的跳转目标 tag（HEAD 取
//     Location，不跟随、不消耗 GitHub API 限额）；剥离 tag 前缀（默认 "v"，
//     见 githubTagPrefix）即版本号，downloadURL 模板收版本号（与 brew 流一致）。
//   - 自定义流 customRelease：brew 未收录软件的上游自有更新接口（WorkBuddy），
//     接口直接给版本号、下载直链、sha256。
//
// 产物维度（与版本来源正交）：默认单产物；置 archArtifacts 即双架构产物
// （zcode / konsole），同一版本多份产物、各算各的 sha，走 runDualArchCheck
// （逐个 HEAD 探测 → 下载实算 → 改写 version 行 + 各 arch sha 行；url 行不动，
// 靠 #{version}/#{arch} 插值覆盖新版本）。双产物无 checksums 模板，
// 有更新时逐个下载实算；镜像（uploadRelease=true，konsole/zcode）下先双包
// 上传本仓 Release 再改写（url 插值须已指向本仓 Release，见 11.34）。
//
// 输出契约与旧版 scripts/check-updates.sh 一致（GITHUB_OUTPUT 键名不变）；
// brew 流查不到软件（API 404）时输出 status=brew-missing 并停（TODO 见 runCheck）。

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
import Foundation

/// 自定义版本来源的一次发布信息
struct UpstreamRelease {
    let version: String
    let downloadURL: String
    /// 上游直接给出的 sha256。仅当实测确认它对应 downloadURL 产物本身时才提供，
    /// 否则置 nil（回退本地实算）。WorkBuddy 的该值是 dmg 的 sha（zip 的不是！）。
    let sha256: String?
}

struct CheckConfig {
    /// 对应 Formula/<formula>.rb 或 Casks/<formula>.rb
    let formula: String
    /// 公式所在目录："Formula"（默认）或 "Casks"
    let formulaPath: String
    /// 是否为 cask（决定改写规则与是否上传 Release）
    let isCask: Bool
    /// brew 流：formulae.brew.sh 上的公式名
    let brewName: String?
    /// brew 流：版本 -> 资产文件名
    let asset: ((String) -> String)?
    /// brew 流：版本 -> 发布包直链（制瓶原料，公式 url 指向它）
    let downloadURL: ((String) -> String)?
    /// brew 流：版本 -> checksums 文件地址；上游不提供则置 nil（回退下载发布包本地计算）
    let checksumsURL: ((String) -> String)?
    /// 自定义流：上游自有更新接口（brew 未收录软件的版本来源）
    let customRelease: (() -> UpstreamRelease?)?
    /// raw 流：源 tap 仓库公式的 raw 地址（如
    /// https://raw.githubusercontent.com/anomalyco/homebrew-tap/master/opencode.rb），
    /// 核心按 GoReleaser 结构解析 version + Intel mac 的 url/sha256。
    let rawFormulaURL: String?
    /// brew 流：查 **cask** 版本（formulae.brew.sh/api/cask/）而非公式（api/formula/）。
    /// 用于 zcode 这类「在 core 里是 cask」的软件——版本字段是 .version 不是 .versions.stable。
    /// 注意：core 的 cask url 是 arm64 的，不能直接取，必须配合 downloadURL 模板给 x64 直链。
    let brewCask: Bool
    /// cask 专用：是否把发布包上传本仓 Release 并把 url 改写为 Release 地址。
    /// 直引上游 CDN 且链接稳定的 cask（如 zcode）置 false；链接带构建哈希、
    /// 每次部署都变的（workbuddy / doubao-ime）置 true 走镜像。
    let uploadRelease: Bool
    /// github 流：跟踪的仓库（"Owner/Repo"，如 "Homebrew/BrewUI"）。
    /// 版本判据是 releases/latest 的跳转目标 tag，不消耗 GitHub API 限额。
    let githubRepo: String?
    /// github 流：tag 前缀（默认 "v"：tag v0.2.1 → 版本 0.2.1）。
    /// 剥离后即版本号（downloadURL 模板收版本号）；tag 无此前缀则原样作版本。
    let githubTagPrefix: String?
    /// 双架构产物：URL token 列表（如 zcode ["arm64", "x64"]、
    /// konsole ["arm64", "x86_64"]），与 downloadURLForArch 配合。
    /// 置空 = 单产物（现有行为）。
    let archArtifacts: [String]?
    /// 双架构产物：(version, archToken) -> 下载直链。archArtifacts 非空时必填。
    /// token → cask sha 行 key 由 caskArchKey 显式映射
    ///（arm64/aarch64→arm，x64/x86_64/amd64→intel），未知 token 直接 fail。
    let downloadURLForArch: ((String, String) -> String)?

    /// raw 流：是否按双架构解析（mac 的 intel/arm 双块各取 url/sha，
    /// 改写公式内双 `if Hardware::CPU` 块）。默认单架构（只取 intel 段）。
    let rawDualArch: Bool

    init(formula: String,
         formulaPath: String = "Formula",
         isCask: Bool = false,
         brewName: String? = nil,
         asset: ((String) -> String)? = nil,
         downloadURL: ((String) -> String)? = nil,
         checksumsURL: ((String) -> String)? = nil,
         customRelease: (() -> UpstreamRelease?)? = nil,
         rawFormulaURL: String? = nil,
         brewCask: Bool = false,
         uploadRelease: Bool = false,
         githubRepo: String? = nil,
         githubTagPrefix: String? = "v",
         archArtifacts: [String]? = nil,
         downloadURLForArch: ((String, String) -> String)? = nil,
         rawDualArch: Bool = false) {
        self.formula = formula
        self.formulaPath = formulaPath
        self.isCask = isCask
        self.brewName = brewName
        self.asset = asset
        self.downloadURL = downloadURL
        self.checksumsURL = checksumsURL
        self.customRelease = customRelease
        self.rawFormulaURL = rawFormulaURL
        self.brewCask = brewCask
        self.uploadRelease = uploadRelease
        self.githubRepo = githubRepo
        self.githubTagPrefix = githubTagPrefix
        self.archArtifacts = archArtifacts
        self.downloadURLForArch = downloadURLForArch
        self.rawDualArch = rawDualArch
    }
}

// MARK: - 输出协议（沿用 check-updates.sh 的 GITHUB_OUTPUT 契约）

private let githubOutput = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"]

func emit(_ line: String) {
    if let path = githubOutput, let handle = FileHandle(forWritingAtPath: path) {
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        handle.write((line + "\n").data(using: .utf8)!)
    } else {
        print(line)
    }
}

func fail(_ message: String) -> Never {
    print("::error::\(message)")
    exit(1)
}

// MARK: - 外部进程（curl / sha256，两条平台都自带，行为与旧脚本一致）

private func which(_ name: String) -> String? {
    let searchPath = ProcessInfo.processInfo.environment["PATH"]
        ?? "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    for dir in searchPath.split(separator: ":") {
        let candidate = "\(dir)/\(name)"
        if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }
    }
    return nil
}

private func run(_ launchPath: String, _ arguments: [String]) -> (status: Int32, stdout: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    let stdout = Pipe()
    process.standardOutput = stdout
    process.standardError = Pipe()  // 丢弃 curl 的进度/错误细节
    do { try process.run() } catch { return (127, "") }
    let data = stdout.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

/// GET 文本；-f 使 HTTP >= 400 走非零退出
func curlText(_ url: String) -> (status: Int32, body: String) {
    guard let curl = which("curl") else { return (127, "") }
    let (status, out) = run(curl, ["-fsSL", "--retry", "2", "--retry-delay", "3",
                                   "--max-time", "30", url])
    return (status, out)
}

/// GET JSON 对象；失败或非 JSON 返回 nil
func fetchJSON(_ url: String) -> [String: Any]? {
    let (status, body) = curlText(url)
    guard status == 0,
          let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any] else {
        return nil
    }
    return json
}

/// 不带 -f 的 GET，附 HTTP 状态码（最后一行）：用于区分 404 与网络故障
private func curlHTTP(_ url: String) -> (httpCode: Int?, body: String) {
    guard let curl = which("curl") else { return (nil, "") }
    let (status, out) = run(curl, ["-sS", "--retry", "2", "--retry-delay", "3",
                                   "--max-time", "30", "-w", "\n%{http_code}", url])
    var lines = out.components(separatedBy: "\n")
    let code = lines.popLast().flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    guard status == 0 || (code ?? 0) >= 400 else { return (nil, "") }
    return (code, lines.joined(separator: "\n"))
}

/// HEAD 探测资源可达性（等价 curl -fsI）
private func curlHeadOK(_ url: String) -> Bool {
    guard let curl = which("curl") else { return false }
    let (status, _) = run(curl, ["-fsI", "--retry", "2", "--retry-delay", "3",
                                 "--max-time", "30", url])
    return status == 0
}

/// 取 GitHub 仓库最新 release 的 tag：HEAD 请求 releases/latest，
/// 只读跳转目标的 Location（形如 .../releases/tag/v0.2.1），不跟随跳转、
/// 不调 GitHub API（不消耗 API 限额）。
/// 刻意保持匿名：不带 GH_TOKEN 认证（限流就等下次跑；反复跑只会更限）。
/// 失败重试 3 次；仍失败返回 nil（由调用方发 status=check-failed 明示，
/// 而不是静默跳过——见 runCheck）。
private func githubLatestTag(repo: String) -> String? {
    guard let curl = which("curl") else { return nil }
    let args = ["-fsSI", "--retry", "2", "--retry-delay", "3",
                "--max-time", "30",
                "https://github.com/\(repo)/releases/latest"]
    // 诊断用：最终失败时把最后一次 curl 退出码与输出规模打出来，
    // 否则 runner 上永远不知道是 DNS/限流/无 Location（2026-09-04 brewui 三连败）。
    var lastStatus: Int32 = -1
    var lastBytes = 0
    for attempt in 1...3 {
        let (status, out) = run(curl, args)
        lastStatus = status
        lastBytes = out.utf8.count
        if status == 0 {
            // 注意：runner 上 curl 吐出的响应头可能以纯 \r 分隔（无 \n，
            // 2026-09-04 brewui 实测：4888B 输出竟是"1 行"），只按 \n 切
            // 会永远找不到 Location——必须按全套换行符切分。
            for line in out.components(separatedBy: CharacterSet.newlines) {
                guard line.lowercased().hasPrefix("location:") else { continue }
                let loc = line.dropFirst("location:".count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                // 只认 .../releases/tag/<tag> 形态：某些仓库（如 rust-lang/rustup）
                // 的 releases/latest 跳到 /releases 列表页，末段是 "releases"——
                // 这种 Location 没有 tag，继续重试而不是拿垃圾版本去误报
                // （2026-09-05 实测；rustup-init 已改走 release-stable.toml）。
                if let tagRange = loc.range(of: "/tag/") {
                    let tag = loc[tagRange.upperBound...].split(separator: "/").first
                        .map(String.init) ?? ""
                    if !tag.isEmpty { return tag }
                }
            }
        }
        if attempt < 3 { _ = sleep(5) }
    }
    print("::warning::githubLatestTag(\(repo)) 3 次均失败（curl exit=\(lastStatus)，末次输出 \(lastBytes)B）")
    return nil
}

/// 下载到临时文件（发布包可能几百 MB，走文件不走管道）
private func curlDownload(_ url: String) -> String? {
    guard let curl = which("curl") else { return nil }
    let dest = FileManager.default.temporaryDirectory
        .appendingPathComponent("updater-\(UUID().uuidString)").path
    let (status, _) = run(curl, ["-fsSL", "--retry", "2", "--retry-delay", "3",
                                 "--max-time", "300", "-o", dest, url])
    guard status == 0 else { return nil }
    return dest
}

private func sha256(ofFile path: String) -> String? {
    let tool: (path: String, args: [String])?
    if let sha256sum = which("sha256sum") {          // Linux（coreutils）
        tool = (sha256sum, [path])
    } else if let shasum = which("shasum") {         // macOS 回退
        tool = (shasum, ["-a", "256", path])
    } else { return nil }
    let (status, out) = run(tool!.path, tool!.args)
    guard status == 0 else { return nil }
    return out.split(separator: "\n").first?.split(separator: " ").first.map(String.init)
}

// MARK: - 版本解析与比较

private func firstMatch(_ pattern: String, in string: String) -> NSTextCheckingResult? {
    let regex = try! NSRegularExpression(pattern: pattern)
    return regex.firstMatch(in: string, range: NSRange(string.startIndex..<string.endIndex, in: string))
}

/// 公式当前版本：优先公式级 version 行（本 tap 公式不写，保留兼容），
/// 回退 url 行内第一处 [^0-9]点分段数字（与 brew 从 URL 扫描版本对应）。
/// 支持任意段数：2.99.0（gh）、2.68.1（fastfetch）、5.4.7.37521366（workbuddy）。
/// 注意：必须跳过 fails_with 块内的 version 行——那是编译器版本号
/// （如 nghttp2 的 `fails_with :gcc do version "13"`），误取会导致恒判
/// newer-than-brew 而静默跳过更新（2026-09-05 实测）。
func currentVersion(in content: String) -> String? {
    let failsStart = try! NSRegularExpression(pattern: #"^[ \t]*fails_with\b.*\bdo[ \t]*$"#)
    let blockEnd = try! NSRegularExpression(pattern: #"^[ \t]*end[ \t]*$"#)
    let versionLine = try! NSRegularExpression(pattern: #"^[ \t]*version "([^"]+)""#)
    var failsDepth = 0
    for line in content.components(separatedBy: "\n") {
        let r = fullRange(line)
        if failsStart.firstMatch(in: line, range: r) != nil {
            failsDepth += 1
            continue
        }
        if failsDepth > 0 {
            if blockEnd.firstMatch(in: line, range: r) != nil { failsDepth -= 1 }
            continue
        }
        if let m = versionLine.firstMatch(in: line, range: r),
           let vr = Range(m.range(at: 1), in: line) {
            return String(line[vr])
        }
    }
    for line in content.components(separatedBy: "\n") {
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
        guard trimmed.hasPrefix(#"url ""#) else { continue }
        let s = String(trimmed)
        if let m = firstMatch(#"[^0-9]([0-9]+(?:\.[0-9]+)+)"#, in: s),
           let r = Range(m.range(at: 1), in: s) {
            return String(s[r])
        }
    }
    return nil
}

/// 等价 sort -V 的数字分段比较：负数 a<b，0 相等，正数 a>b。
/// 段数不等时不用 0 补齐——sort -V 里 1.2 < 1.2.0（前缀相等时较短的更小）。
func compareVersions(_ a: String, _ b: String) -> Int {
    let sa = a.split(separator: ".").map(String.init)
    let sb = b.split(separator: ".").map(String.init)
    for i in 0..<max(sa.count, sb.count) {
        guard i < sa.count, i < sb.count else {
            return sa.count < sb.count ? -1 : 1
        }
        let av = sa[i]
        let bv = sb[i]
        if av == bv { continue }
        if let ai = Int(av), let bi = Int(bv), ai != bi { return ai < bi ? -1 : 1 }
        return av < bv ? -1 : 1
    }
    return 0
}

// MARK: - raw 流解析（GoReleaser 结构，如 anomalyco/homebrew-tap）

/// 从源 tap 仓库的公式 raw 文本解析发布信息：`version "..."` +
/// `on_macos` 段内 `Hardware::CPU.intel?` 块后的第一组 url/sha256。
/// 三个约束（缺一返回 nil）：
///   1. 先截断 `on_linux` 段——linux 资产名也带 x64（如 opencode-linux-x64），
///      不截断会误取；
///   2. 只认 `Hardware::CPU.intel?` 标记后的 url（torpedo 的 arm 块在前，
///      intel 块在后，直接取第一个 url 会拿到 arm64 包）；
///   3. sha256 必须是 64 位 hex（源文件里只有一处，防御性校验）。
func parseGoReleaserRaw(_ text: String) -> UpstreamRelease? {
    guard let vm = firstMatch(#"(?m)^[ \t]*version\s+"([^"]+)""#, in: text),
          let vr = Range(vm.range(at: 1), in: text) else {
        return nil
    }
    let version = String(text[vr])
    // 只看 on_linux 之前的部分（即 on_macos 段）
    let macScope = text.components(separatedBy: "on_linux").first ?? text
    let pattern = #"Hardware::CPU\.intel\?.*?url\s+"([^"]+)".*?sha256\s+"([0-9a-fA-F]{64})""#
    guard let regex = try? NSRegularExpression(pattern: pattern,
                                               options: [.dotMatchesLineSeparators]),
          let m = regex.firstMatch(in: macScope, range: fullRange(macScope)),
          let ur = Range(m.range(at: 1), in: macScope),
          let sr = Range(m.range(at: 2), in: macScope) else {
        return nil
    }
    return UpstreamRelease(version: version,
                           downloadURL: String(macScope[ur]),
                           sha256: String(macScope[sr]).lowercased())
}

/// 双架构 raw 解析：version + mac 的 intel/arm 双块各取 url/sha256。
/// 约束与单架构流一致（先截 on_linux；intel 块与 arm 块各取标记后第一组；
/// sha 校验 64 位 hex），任一取不到返回 nil。
func parseGoReleaserRawDual(_ text: String) -> (
    version: String, intelURL: String, intelSHA: String,
    armURL: String, armSHA: String)? {
    guard let vm = firstMatch(#"(?m)^[ \t]*version\s+"([^"]+)""#, in: text),
          let vr = Range(vm.range(at: 1), in: text) else {
        return nil
    }
    let version = String(text[vr])
    let macScope = text.components(separatedBy: "on_linux").first ?? text
    func block(_ cpu: String) -> (String, String)? {
        let pattern = #"Hardware::CPU\."# + cpu + #"\?.*?url\s+"([^"]+)".*?sha256\s+"([0-9a-fA-F]{64})""#
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: [.dotMatchesLineSeparators]),
              let m = regex.firstMatch(in: macScope, range: fullRange(macScope)),
              let ur = Range(m.range(at: 1), in: macScope),
              let sr = Range(m.range(at: 2), in: macScope) else {
            return nil
        }
        return (String(macScope[ur]), String(macScope[sr]).lowercased())
    }
    guard let intel = block("intel"), let arm = block("arm") else { return nil }
    return (version, intel.0, intel.1, arm.0, arm.1)
}

// MARK: - 公式改写

private func fullRange(_ s: String) -> NSRange {
    NSRange(s.startIndex..<s.endIndex, in: s)
}

private func isURLDefinitionLine(_ line: String) -> Bool {
    line.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix(#"url ""#)
}

private func isMirrorDefinitionLine(_ line: String) -> Bool {
    line.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix(#"mirror ""#)
}

/// 改写公式：version 行（如有）同步为新版本、sha256 行替换、
/// 摘除失效的 bottle do...end 块。url 行两种处理：
///   - replaceURLLine=true（cask 镜像流：每次部署文件名都变，如 workbuddy）→
///     第一条 url 行整条替换为 newURL；
///   - replaceURLLine=false（默认：公式与直引 cask）→ 只在第一条 url 行内把
///     旧版本号替换为新版本（数字边界防误伤），保留 #{version}/#{arch} 插值；
///     行内本就没有旧版本号（纯插值 url）则不动该行——插值已覆盖新版本。
/// 双架构（archShas 非空）：额外按 key 改写 `sha256 arm:/intel:` 行，
/// 此时单 sha 参数忽略、url 行不动。找不到对应 key 的行直接 fail。
/// version 行只有部分公式需要显式声明（brew 从 URL 扫不出正确版本时，如 node 的
/// darwin-x64.tar.gz 会扫出 "64"），有则必须同步，否则 url 与 version 脱节。
func rewriteFormula(_ content: String, newURL: String, newVersion: String,
                    oldVersion: String, sha: String,
                    archShas: [(key: String, sha: String)]? = nil,
                    replaceURLLine: Bool = true) -> (content: String, bottleStale: Bool) {
    let shaLine = try! NSRegularExpression(pattern: #"^([ \t]*)sha256 "[0-9a-f]{64}""#)
    // 双架构 sha 行：首行 `sha256 arm: "..."` + 可能的换行延续 `intel: "..."`
    //（core 通行写法，sha256 只出现一次；注意延续行没有 sha256 前缀，
    // 且 key 与引号之间可能有多个对齐空格）。
    let archShaFirst = try! NSRegularExpression(pattern: #"^([ \t]*)sha256 ([A-Za-z0-9_]+):\s+"[0-9a-f]{64}""#)
    let archShaCont = try! NSRegularExpression(pattern: #"^([ \t]+)([A-Za-z0-9_]+):\s+"[0-9a-f]{64}""#)
    let versionLine = try! NSRegularExpression(pattern: #"^([ \t]*)version "[^"]+""#)
    let bottleStart = try! NSRegularExpression(pattern: #"^[ \t]*bottle do[ \t]*$"#)
    let blockEnd = try! NSRegularExpression(pattern: #"^[ \t]*end[ \t]*$"#)
    // 旧版本号子串替换（数字边界，与 check-updates.sh 时代一致）
    let oldVerPattern = try! NSRegularExpression(
        pattern: "(?<![0-9.])" + NSRegularExpression.escapedPattern(for: oldVersion) + "(?![0-9.])")

    var result: [String] = []
    var bottleStale = false
    var skipping = false
    var urlReplaced = false
    var versionReplaced = false
    var archMatched = Set<String>()
    var inArchSha = false

    for line in content.components(separatedBy: "\n") {
        if skipping {
            // bottle 块内容与 do/end 行都丢掉；遇到块内第一个 end 即结束
            if blockEnd.firstMatch(in: line, range: fullRange(line)) != nil { skipping = false }
            continue
        }
        if bottleStart.firstMatch(in: line, range: fullRange(line)) != nil {
            skipping = true
            bottleStale = true
            continue
        }

        var replaced = line
        // 双架构 sha 行（与单 sha 行互斥）：首行匹配，或缩进延续行且上一行
        // 也是 sha 行（防 `arch arm: "arm64"` 这类 DSL 行误伤——它的值不是 64 位 hex）。
        // 行内已知 key 逐个替换，`:\s+` 原样保留（不对齐空格不动，免得触发布局检查）。
        if let archShas = archShas {
            let isFirst = archShaFirst.firstMatch(in: replaced, range: fullRange(replaced)) != nil
            let isCont = inArchSha
                && archShaCont.firstMatch(in: replaced, range: fullRange(replaced)) != nil
            if isFirst || isCont {
                inArchSha = true
                for e in archShas {
                    let pat = try! NSRegularExpression(
                        pattern: "(?<![A-Za-z0-9_])("
                            + NSRegularExpression.escapedPattern(for: e.key)
                            + #")(:\s+)("[0-9a-f]{64}")"#)
                    let r = fullRange(replaced)
                    if pat.firstMatch(in: replaced, range: r) != nil {
                        replaced = pat.stringByReplacingMatches(
                            in: replaced, range: r, withTemplate: "$1$2\"\(e.sha)\"")
                        archMatched.insert(e.key)
                    }
                }
            } else {
                inArchSha = false
            }
        } else if let m = shaLine.firstMatch(in: replaced, range: fullRange(replaced)) {
            // 主 sha256 行（瓶块行是 sha256 cellar: ... 形态，天然不匹配）
            let indent = (replaced as NSString).substring(with: m.range(at: 1))
            replaced = "\(indent)sha256 \"\(sha)\""
        }
        // 只处理第一条 url 定义行（resource 块若有自己的 url 不受影响）
        if !urlReplaced, isURLDefinitionLine(replaced) {
            if replaceURLLine {
                let indent = String(replaced.prefix(while: { $0 == " " || $0 == "\t" }))
                replaced = "\(indent)url \"\(newURL)\""
            } else {
                let range = fullRange(replaced)
                if oldVerPattern.firstMatch(in: replaced, range: range) != nil {
                    replaced = oldVerPattern.stringByReplacingMatches(
                        in: replaced, range: range, withTemplate: newVersion)
                }
                // 行内无旧版本号（纯 #{version}/#{arch} 插值）：不动，插值已覆盖新版本
            }
            urlReplaced = true
        }
        // 镜像行（audit --strict 强制要求至少一个，见 11.28）：与 url 行同步做
        // 版本子串替换，保持可下载。只处理点分段格式（下划线变体如 curl 的
        // curl-8_22_0 不在此列——这类公式只保留点分段镜像，见各公式头注）；
        // 镜像流（replaceURLLine）下不动（cask 镜像 url 已整条换新）。
        if !replaceURLLine, isMirrorDefinitionLine(replaced) {
            let range = fullRange(replaced)
            if oldVerPattern.firstMatch(in: replaced, range: range) != nil {
                replaced = oldVerPattern.stringByReplacingMatches(
                    in: replaced, range: range, withTemplate: newVersion)
            }
        }
        // 顶层 version 行同步（公式级唯一 version；resource 块内 version 行不会被
        // 该正则命中，因为 resource 的 version 缩进在块内但正则只认行首空白+version，
        // 块内的同样匹配——因此用只换第一次的方式保护）
        if !versionReplaced, let m = versionLine.firstMatch(in: replaced, range: fullRange(replaced)) {
            let indent = (replaced as NSString).substring(with: m.range(at: 1))
            replaced = "\(indent)version \"\(newVersion)\""
            versionReplaced = true
        }
        result.append(replaced)
    }
    if let archShas = archShas {
        let missing = archShas.map { $0.key }.filter { !archMatched.contains($0) }
        if !missing.isEmpty {
            fail("改写失败：未找到 sha256 行 \(missing.joined(separator: ", "))")
        }
    }
    return (result.joined(separator: "\n"), bottleStale)
}

// MARK: - 单包检查主流程

/// cask arch token → sha256 行的 key（`sha256 arm:/intel:`）。
/// 未知 token 直接 fail（绝不静默错配）。
private func caskArchKey(for token: String) -> String {
    switch token {
    case "arm64", "aarch64": return "arm"
    case "x64", "x86_64", "amd64": return "intel"
    default: fail("未知架构 token：\(token)（caskArchKey 需显式登记）")
    }
}

/// 双架构检查主流程（zcode / konsole）：版本已定（stable），逐个产物
/// HEAD 探测 → 下载实算 → 改写 version 行 + 各 arch sha 行 + url 行版本子串替换。
/// url 行不动结构（#{version}/#{arch} 插值或字面版本号只换版本部分）；
/// 镜像模式（uploadRelease=true，konsole）下先把双包上传本仓 Release
///（tag `<formula>-<stable>`，资产名沿用上游 basename，旧快照清理），
/// 再改写——Release tag 与资产名都含字面版本号，子串替换即跟随。
func runDualArchCheck(config: CheckConfig, content: String, formulaFile: String,
                      current: String, stable: String) {
    guard let tokens = config.archArtifacts, !tokens.isEmpty,
          let tmpl = config.downloadURLForArch else {
        fail("双架构产物（\(config.formula)）必须提供 archArtifacts + downloadURLForArch")
    }
    let mirroring = config.uploadRelease

    // 4. 逐个 HEAD 探测（任一缺失即 upstream-missing，不误改公式）
    var urls: [(token: String, url: String)] = []
    for t in tokens {
        let u = tmpl(stable, t)
        urls.append((token: t, url: u))
        if !curlHeadOK(u) {
            print("::warning::新版本资源不可下载：\(u)")
            emit("status=upstream-missing")
            emit("current_version=\(current)")
            emit("new_version=\(stable)")
            return
        }
    }

    // 5. 逐个下载实算（双产物无 checksums 模板，始终实算；仅新版本时发生。
    //    暂存文件统一留到最后删——镜像模式上传要用，直引模式算完即无用。）
    var dls: [(key: String, url: String, sha: String, tmp: String)] = []
    for (t, u) in urls {
        let key = caskArchKey(for: t)
        print("下载 \(t) 发布包后本地计算 sha256")
        guard let tmp = curlDownload(u), let h = sha256(ofFile: tmp) else {
            fail("无法获取 \(u) 的 sha256")
        }
        guard h.range(of: #"^[0-9a-f]{64}$"#, options: .regularExpression) != nil else {
            fail("得到的 sha256 不合法：\(h)")
        }
        print("sha256（\(t) 实算）：\(h)")
        dls.append((key: key, url: u, sha: h, tmp: tmp))
    }
    let keyed = dls.map { (key: $0.key, sha: $0.sha) }

    // 5b. 双架构 + 镜像（konsole）：双包上传本仓 Release（tag `<formula>-<stable>`，
    //     资产名沿用上游 basename；旧快照按 workbuddy 模式清理）。
    //     url 行随后走版本子串替换——Release tag 与资产名都含字面版本号。
    if mirroring {
        let tagName = "\(config.formula)-\(stable)"
        let repo = ProcessInfo.processInfo.environment["GITHUB_REPOSITORY"] ?? "Bemly/homebrew-tahoe"
        guard let gh = which("gh") else {
            fail("双架构 + 镜像（\(config.formula)）需要 gh CLI 上传 Release")
        }
        var created = false
        for d in dls {
            // gh 以本地文件名做资产名：改成上游 basename（单包镜像流同例，见 11.16）。
            // 空格同步换成点（GitHub 存资产时会这么干，见本文件单包分支注释；
            // %20 先解码，wireshark 的 appcast 直链是编码形态）。
            let rawName = URL(fileURLWithPath: d.url).lastPathComponent
            let assetName = (rawName.removingPercentEncoding ?? rawName)
                .replacingOccurrences(of: " ", with: ".")
            let namedPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("updater-\(UUID().uuidString)")
                .appendingPathComponent(assetName).path
            do {
                try FileManager.default.createDirectory(
                    atPath: (namedPath as NSString).deletingLastPathComponent,
                    withIntermediateDirectories: true)
                try FileManager.default.moveItem(atPath: d.tmp, toPath: namedPath)
            } catch {
                fail("重命名待上传文件失败：\(error)")
            }
            if !created {
                let (cStatus, cOut) = run(gh, ["release", "create", tagName, namedPath,
                                               "--repo", repo, "--generate-notes",
                                               "--title", "\(config.formula) \(stable)"])
                if cStatus != 0 {
                    // 同名 tag 已存在（重复运行）→ 改为覆盖上传资产
                    let (uStatus, uOut) = run(gh, ["release", "upload", tagName, namedPath,
                                                   "--repo", repo, "--clobber"])
                    if uStatus != 0 { fail("上传 Release 失败：\(cOut)\n\(uOut)") }
                }
                created = true
            } else {
                let (uStatus, uOut) = run(gh, ["release", "upload", tagName, namedPath,
                                               "--repo", repo, "--clobber"])
                if uStatus != 0 { fail("上传 Release 失败：\(uOut)") }
            }
            print("已上传 Release 资产：\(assetName)")
            try? FileManager.default.removeItem(
                atPath: (namedPath as NSString).deletingLastPathComponent)
        }
        // 旧快照清理：只保留本次 tag（月度快照会堆积，不清不行；单包流同例）
        deleteOldCaskReleases(repo: repo, formula: config.formula, keepTag: tagName)
    } else {
        for d in dls { try? FileManager.default.removeItem(atPath: d.tmp) }
    }

    // 6. 改写 cask（version 行 + 双 sha 行 + url 行版本子串替换；
    //    镜像模式 url 行同样只换版本——Release tag 与资产名含字面版本号）
    let (newContent, bottleStale) = rewriteFormula(content, newURL: "",
                                                   newVersion: stable, oldVersion: current,
                                                   sha: "", archShas: keyed,
                                                   replaceURLLine: false)
    do {
        try newContent.write(toFile: formulaFile, atomically: true, encoding: .utf8)
    } catch {
        fail("写回 \(formulaFile) 失败：\(error)")
    }
    if bottleStale {
        print("已摘除失效的 bottle 块（其 sha256 属于旧版本），需重跑 bottle workflow 重建 GHCR 瓶")
    }

    // 7. 改后自检：arch 插值保留、双 sha 就位
    // （sha 行 key 与引号间的对齐空格原样保留；首行 `sha256 <key>:` 与换行延续
    // `<key>:` 两种形态都认，只验 key/sha 落位）
    guard newContent.contains("#{arch}") else { fail("url 的 arch 插值丢失") }
    for (k, h) in keyed {
        let pat = try! NSRegularExpression(
            pattern: "(?:sha256\\s+)?" + NSRegularExpression.escapedPattern(for: k)
                + ":\\s+\"" + h + "\"")
        guard pat.firstMatch(in: newContent, range: fullRange(newContent)) != nil else {
            fail("sha256 \(k) 未成功更新")
        }
    }

    print("公式已更新：\(current) -> \(stable)")
    emit("status=updated")
    emit("current_version=\(current)")
    emit("new_version=\(stable)")
    for (k, h) in keyed { emit("sha256_\(k)=\(h)") }
    emit("bottle_stale=\(bottleStale)")
}

/// 改写双架构 raw 公式：顶层 url/sha（Intel 段）与 `on_macos` 内
/// `if Hardware::CPU.arm?` 块的 url/sha 整条替换为源文件值，并摘除失效的 bottle 块。
/// 块作用域用缩进判定（标记行缩进为界，`end` 缩进 ≤ 标记才出块——块内
/// `def install...end` 缩进更深，不会误出块）。
/// url/sha 按"槽位内第一次出现"替换（intel 槽含顶层，arm 槽只在 arm 块内）；
/// 找不到对应行直接 fail。
func rewriteFormulaRawDual(_ content: String,
                           intelURL: String, intelSHA: String,
                           armURL: String, armSHA: String) -> (content: String, bottleStale: Bool) {
    let bottleStart = try! NSRegularExpression(pattern: #"^[ \t]*bottle do[ \t]*$"#)
    let blockEnd = try! NSRegularExpression(pattern: #"^[ \t]*end[ \t]*$"#)
    let marker = try! NSRegularExpression(pattern: #"^([ \t]*)if Hardware::CPU\.(intel|arm)\?"#)
    let urlLine = try! NSRegularExpression(pattern: #"^([ \t]*)url "[^"]+""#)
    let shaLine = try! NSRegularExpression(pattern: #"^([ \t]*)sha256 "[0-9a-f]{64}""#)

    var result: [String] = []
    var bottleStale = false
    var skipping = false
    // nil = 块外，"intel"/"arm" = 块内；附标记行缩进用于出块判定。
    // 槽位规则：arm 块内归 arm，其余（顶层 url/sha、intel 块内）归 intel——
    // 顶层必须是 Intel 段（brew readall 在 Linux 下验公式，顶层无 url 直接
    // 报 requires at least a URL；on_macos 包不住 Linux）。
    var mode: String? = nil
    var modeIndent = 0
    var doneURL = Set<String>()
    var doneSHA = Set<String>()

    func indentOf(_ line: String) -> Int {
        line.prefix(while: { $0 == " " || $0 == "\t" }).count
    }

    for line in content.components(separatedBy: "\n") {
        if skipping {
            if blockEnd.firstMatch(in: line, range: fullRange(line)) != nil { skipping = false }
            continue
        }
        if bottleStart.firstMatch(in: line, range: fullRange(line)) != nil {
            skipping = true
            bottleStale = true
            continue
        }

        var replaced = line
        if let m = marker.firstMatch(in: replaced, range: fullRange(replaced)) {
            mode = (replaced as NSString).substring(with: m.range(at: 2))
            modeIndent = indentOf(replaced)
        } else if mode != nil, blockEnd.firstMatch(in: replaced, range: fullRange(replaced)) != nil,
                  indentOf(replaced) <= modeIndent {
            mode = nil
        } else {
            let slot = (mode == "arm") ? "arm" : "intel"
            if !doneURL.contains(slot),
               let m = urlLine.firstMatch(in: replaced, range: fullRange(replaced)) {
                let indent = (replaced as NSString).substring(with: m.range(at: 1))
                replaced = "\(indent)url \"\(slot == "intel" ? intelURL : armURL)\""
                doneURL.insert(slot)
            } else if !doneSHA.contains(slot),
                      let m = shaLine.firstMatch(in: replaced, range: fullRange(replaced)) {
                let indent = (replaced as NSString).substring(with: m.range(at: 1))
                replaced = "\(indent)sha256 \"\(slot == "intel" ? intelSHA : armSHA)\""
                doneSHA.insert(slot)
            }
        }
        result.append(replaced)
    }
    let missingURL = ["intel", "arm"].filter { !doneURL.contains($0) }
    let missingSHA = ["intel", "arm"].filter { !doneSHA.contains($0) }
    if !missingURL.isEmpty || !missingSHA.isEmpty {
        fail("改写失败：未找到 \(missingURL.map { $0 + " url" }.joined(separator: ", "))"
            + "\(missingSHA.map { $0 + " sha256" }.joined(separator: ", ")) 行")
    }
    return (result.joined(separator: "\n"), bottleStale)
}

/// 双架构 raw 检查主流程（opencode）：版本已定，双 url 逐个 HEAD 探测 →
/// 改写公式内双块 → 自检。sha 直接取自源文件（已校验归属，无需下载）。
func runRawDualCheck(config: CheckConfig, content: String, formulaFile: String,
                     current: String,
                     dual: (version: String, intelURL: String, intelSHA: String,
                            armURL: String, armSHA: String)) {
    let stable = dual.version
    if current == stable {
        print("已是最新，无需更新。")
        emit("status=up-to-date")
        emit("current_version=\(current)")
        return
    }
    if compareVersions(current, stable) > 0 {
        print("本地版本(\(current)) 比 上游版本(\(stable)) 更新，保持不动。")
        emit("status=newer-than-brew")
        emit("current_version=\(current)")
        return
    }
    print("发现新版本 : \(current) -> \(stable)")

    for u in [dual.intelURL, dual.armURL] {
        if !curlHeadOK(u) {
            print("::warning::新版本资源不可下载：\(u)")
            emit("status=upstream-missing")
            emit("current_version=\(current)")
            emit("new_version=\(stable)")
            return
        }
    }

    let (newContent, bottleStale) = rewriteFormulaRawDual(
        content, intelURL: dual.intelURL, intelSHA: dual.intelSHA,
        armURL: dual.armURL, armSHA: dual.armSHA)
    do {
        try newContent.write(toFile: formulaFile, atomically: true, encoding: .utf8)
    } catch {
        fail("写回 \(formulaFile) 失败：\(error)")
    }
    if bottleStale {
        print("已摘除失效的 bottle 块（其 sha256 属于旧版本），需重跑 bottle workflow 重建 GHCR 瓶")
    }

    guard newContent.contains("url \"\(dual.intelURL)\""),
          newContent.contains("url \"\(dual.armURL)\""),
          newContent.contains("sha256 \"\(dual.intelSHA)\""),
          newContent.contains("sha256 \"\(dual.armSHA)\"") else {
        fail("双架构 url/sha 未成功更新")
    }

    print("公式已更新：\(current) -> \(stable)")
    emit("status=updated")
    emit("current_version=\(current)")
    emit("new_version=\(stable)")
    emit("sha256_intel=\(dual.intelSHA)")
    emit("sha256_arm=\(dual.armSHA)")
    emit("bottle_stale=\(bottleStale)")
}

func runCheck(_ config: CheckConfig) {
    let formulaFile = "\(config.formulaPath)/\(config.formula).rb"
    guard let content = try? String(contentsOfFile: formulaFile, encoding: .utf8) else {
        fail("找不到文件：\(formulaFile)（须在仓库根目录运行）")
    }

    // 1. 本地版本
    guard let current = currentVersion(in: content) else {
        fail("无法从 \(formulaFile) 解析当前版本号")
    }
    print("本地版本 : \(current)")

    // 2. 上游版本与下载直链（优先级：自定义接口 > 源仓库 raw > github > brew）
    let upstream: UpstreamRelease
    if let custom = config.customRelease {
        guard let release = custom() else {
            fail("无法从自定义更新接口获取 \(config.formula) 的版本信息")
        }
        upstream = release
        print("上游版本 : \(upstream.version)（自定义更新接口）")
    } else if let rawURL = config.rawFormulaURL {
        let (status, body) = curlText(rawURL)
        guard status == 0, !body.isEmpty else {
            fail("无法从源仓库 raw 获取 \(config.formula) 的版本信息：\(rawURL)")
        }
        // 双架构 raw（opencode）：双块解析后分流，全程不再走单产物路径
        if config.rawDualArch {
            guard let dual = parseGoReleaserRawDual(body) else {
                fail("无法从源仓库 raw 解析 \(config.formula) 的双架构版本信息：\(rawURL)")
            }
            print("上游版本 : \(dual.version)（源仓库 raw，双架构）")
            runRawDualCheck(config: config, content: content, formulaFile: formulaFile,
                            current: current, dual: dual)
            return
        }
        guard let release = parseGoReleaserRaw(body) else {
            fail("无法从源仓库 raw 获取 \(config.formula) 的版本信息：\(rawURL)")
        }
        upstream = release
        print("上游版本 : \(upstream.version)（源仓库 raw）")
    } else if let repo = config.githubRepo {
        // github 流：releases/latest 跳转目标 tag 判新（不消耗 GitHub API 限额）。
        // tag 前缀（默认 "v"）剥离后即版本号，downloadURL 模板收版本号。
        // tag 取不到（限流/断网）时发 check-failed 明示——绝不能静默跳过，
        // 否则 workflow 会把它当"无需更新"吃掉（2026-09-04 brewui 实测）。
        guard let tag = githubLatestTag(repo: repo), !tag.isEmpty else {
            print("::warning::无法获取 \(repo) 的最新 release tag（限流或网络故障），跳过")
            emit("status=check-failed")
            emit("current_version=\(current)")
            return
        }
        var tagVersion = tag
        if let prefix = config.githubTagPrefix, !prefix.isEmpty,
           tagVersion.hasPrefix(prefix) {
            tagVersion = String(tagVersion.dropFirst(prefix.count))
        }
        guard let template = config.downloadURL else {
            fail("github 流（\(repo)）必须提供 downloadURL 模板")
        }
        upstream = UpstreamRelease(version: tagVersion,
                                   downloadURL: template(tagVersion),
                                   sha256: nil)
        print("上游版本 : \(upstream.version)（github release tag \(tag)）")
    } else {
        guard let brewName = config.brewName else {
            fail("CheckConfig 配置不完整：需要 customRelease、rawFormulaURL、githubRepo 或 brew 流（至少提供 brewName）")
        }
        // 变量名避开外层的 stable / downloadURL（第 4 步之后还要用）
        let resolvedVersion: String
        let resolvedURL: String
        let hintSHA: String?

        if config.brewCask {
            // cask 流：软件在 core 里是 cask（如 zcode），版本字段是 .version 而非
            // .versions.stable。core 的 cask url 是 arm64 的，绝不能直接取 urls——
            // 必须由 downloadURL 模板给出 x64 直链；sha 同样不能用 core 那份
            // （属于另一个架构的包），置 nil 让核心回退下载实算。
            let apiURL = "https://formulae.brew.sh/api/cask/\(brewName).json"
            let (httpCode, body) = curlHTTP(apiURL)
            if httpCode == 404 {
                print("brew 上没有 cask \(brewName)（formulae.brew.sh 404），跳过")
                emit("status=brew-missing")
                emit("current_version=\(current)")
                return
            }
            guard httpCode == 200,
                  let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
                  let caskVersion = json["version"] as? String, !caskVersion.isEmpty else {
                fail("无法从 formulae.brew.sh 获取 cask \(brewName) 的版本（HTTP \(httpCode.map(String.init) ?? "请求失败")）")
            }
            print("brew cask 版本 : \(caskVersion)")
            if config.archArtifacts != nil {
                // 双架构：逐个 url 由 downloadURLForArch 给（见 runDualArchCheck），
                // 此处只需版本，单 downloadURL 模板不需要（resolvedURL 会被双分支忽略）
                resolvedVersion = caskVersion
                resolvedURL = ""
            } else {
                guard let template = config.downloadURL else {
                    fail("cask 流（\(brewName)）必须提供 downloadURL 模板：core 的 url 是 arm64 的，不能直接使用")
                }
                resolvedVersion = caskVersion
                resolvedURL = template(caskVersion)
            }
            hintSHA = nil
        } else {
            // brew 的 versions.stable 是判据：这是 brew 上的版本号，不是上游 GitHub 的最新版
            let apiURL = "https://formulae.brew.sh/api/formula/\(brewName).json"
            let (httpCode, body) = curlHTTP(apiURL)
            if httpCode == 404 {
                // TODO(brew-missing)：brew 没有收录且未接 customRelease/raw 流的软件，无法判新。
                // 需要为该软件适配版本来源（源 tap 仓库 raw 接 rawFormulaURL，见
                // opencode.swift；或照抄 workbuddy.swift 接上游自有接口），
                // 适配前先明确报告并停在这里（登记于 AGENTS.md 第 12 节待办）。
                print("brew 上没有 \(brewName)（formulae.brew.sh 404），跳过（TODO：适配版本来源）")
                emit("status=brew-missing")
                emit("current_version=\(current)")
                return
            }
            guard httpCode == 200,
                  let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
                  let versions = json["versions"] as? [String: Any],
                  let formulaVersion = versions["stable"] as? String, !formulaVersion.isEmpty else {
                fail("无法从 formulae.brew.sh 获取 \(brewName) 的 stable 版本（HTTP \(httpCode.map(String.init) ?? "请求失败")）")
            }
            print("brew 版本 : \(formulaVersion)")
            // 全量式：JSON 的 urls.stable.url / .checksum 就是 core 公式 url 行指向的
            // 真实上游直链与其 sha256；模板式（downloadURL 闭包）仍优先，兼容老用法。
            let stableEntry = (json["urls"] as? [String: Any])?["stable"] as? [String: Any]
            if let template = config.downloadURL {
                resolvedURL = template(formulaVersion)
            } else if let jsonURL = stableEntry?["url"] as? String, !jsonURL.isEmpty {
                resolvedURL = jsonURL
            } else {
                fail("无法确定 \(brewName) 的上游下载直链（JSON 缺 urls.stable.url 且未提供 downloadURL 模板）")
            }
            resolvedVersion = formulaVersion
            hintSHA = stableEntry?["checksum"] as? String
        }

        upstream = UpstreamRelease(version: resolvedVersion,
                                   downloadURL: resolvedURL,
                                   sha256: hintSHA)
    }
    let stable = upstream.version

    // 3. 版本比较
    if current == stable {
        print("已是最新，无需更新。")
        emit("status=up-to-date")
        emit("current_version=\(current)")
        return
    }
    if compareVersions(current, stable) > 0 {
        print("本地版本(\(current)) 比 上游版本(\(stable)) 更新，保持不动。")
        emit("status=newer-than-brew")
        emit("current_version=\(current)")
        return
    }
    print("发现新版本 : \(current) -> \(stable)")

    // 双架构产物（zcode / konsole）：同一版本多份产物，分流处理后返回
    if config.archArtifacts != nil {
        runDualArchCheck(config: config, content: content, formulaFile: formulaFile,
                         current: current, stable: stable)
        return
    }

    // 4. HEAD 探测新版本资源是否可下载（几乎不产生流量）
    let downloadURL = upstream.downloadURL
    if !curlHeadOK(downloadURL) {
        print("::warning::新版本资源不可下载：\(downloadURL)")
        emit("status=upstream-missing")
        emit("current_version=\(current)")
        emit("new_version=\(stable)")
        return
    }

    // 5. 计算 sha256：上游直接给出的（实测确认归属）> checksums.txt（~2KB）> 下载发布包实算
    var sha = ""
    if let hint = upstream.sha256,
       hint.range(of: #"^[0-9a-f]{64}$"#, options: .regularExpression) != nil {
        sha = hint
        print("sha256（上游接口直接给出）：\(sha)")
    }
    if sha.isEmpty, let checksumsURL = config.checksumsURL?(stable) {
        let (status, text) = curlText(checksumsURL)
        if status == 0 {
            // 等价 awk -v f="$asset" '$2==f {print $1}'
            let asset = config.asset?(stable) ?? ""
            for line in text.components(separatedBy: "\n") {
                let fields = line.split(separator: " ", omittingEmptySubsequences: true)
                if fields.count >= 2, fields[1] == asset {
                    sha = String(fields[0])
                    break
                }
            }
            if !sha.isEmpty { print("sha256（取自 checksums.txt，仅 2KB）：\(sha)") }
        }
    }
    if sha.isEmpty {
        print("checksums 不可用，回退：下载发布包后本地计算 sha256")
        guard let tmp = curlDownload(downloadURL), let hash = sha256(ofFile: tmp) else {
            fail("无法获取 \(downloadURL) 的 sha256")
        }
        try? FileManager.default.removeItem(atPath: tmp)
        sha = hash
    }
    guard sha.range(of: #"^[0-9a-f]{64}$"#, options: .regularExpression) != nil else {
        fail("得到的 sha256 不合法：\(sha)")
    }

    // cask：把安装包上传到本仓 Release，url 取 Release 资产地址（而非上游 COS 直链）。
    // 仅 uploadRelease=true 的 cask 走这条路（链接带构建哈希、每次部署都变的那些）；
    // 直引上游 CDN 且链接稳定的 cask（zcode）置 false，url 保持上游直链。
    var finalURL = downloadURL
    if config.isCask && config.uploadRelease {
        let tagName = "\(config.formula)-\(stable)"
        // GitHub 会把资产名里的空格改成点（如 "checkra1n beta 0.12.4.dmg" 存成
        // "checkra1n.beta.0.12.4.dmg"，2026-09-05 实测）：上传用名与 cask URL
        // 必须同步做这个替换，否则 URL 404。单/双架构两条路都要换；
        // 先解 %20（appcast/URL 编码形态的下载直链，lastPathComponent 拿到的是
        // 字面 %20，不解就传上去，资产名就烂了）。
        let assetName = (URL(fileURLWithPath: downloadURL).lastPathComponent
            .removingPercentEncoding ?? URL(fileURLWithPath: downloadURL).lastPathComponent)
            .replacingOccurrences(of: " ", with: ".")
        let repo = ProcessInfo.processInfo.environment["GITHUB_REPOSITORY"] ?? "Bemly/homebrew-tahoe"
        guard let zipPath = curlDownload(downloadURL) else {
            fail("下载 \(config.formula) 发布包失败，无法上传 Release")
        }
        // 校验已算好的 sha 与文件一致（防御性）
        if let fileHash = sha256(ofFile: zipPath), fileHash != sha {
            fail("文件 sha256 不一致：期望 \(sha)，实算 \(fileHash)")
        }
        // gh 用本地文件名做资产名：必须先把 curl 的随机临时文件名
        // （updater-<UUID>）改成上游资产名，否则 Release 里资产名与 cask url
        // 对不上、下载 404（2026-09-04 实测，doubao 首发即因此 404）。
        let namedPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("updater-\(UUID().uuidString)")
            .appendingPathComponent(assetName).path
        do {
            try FileManager.default.createDirectory(
                atPath: (namedPath as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true)
            try FileManager.default.moveItem(atPath: zipPath, toPath: namedPath)
        } catch {
            fail("重命名待上传文件失败：\(error)")
        }
        let gh = which("gh")
        if let gh {
            let repoFlag = "--repo"
            let createArgs = ["release", "create", tagName, namedPath,
                              repoFlag, repo, "--generate-notes", "--title", "\(config.formula) \(stable)"]
            let (cStatus, cOut) = run(gh, createArgs)
            if cStatus != 0 {
                // 同名 tag 已存在（重复运行）→ 改为覆盖上传资产
                let uploadArgs = ["release", "upload", tagName, namedPath, repoFlag, repo, "--clobber"]
                let (uStatus, uOut) = run(gh, uploadArgs)
                if uStatus != 0 {
                    fail("上传 Release 失败：\(cOut)\n\(uOut)")
                }
            }
            finalURL = "https://github.com/\(repo)/releases/download/\(tagName)/\(assetName)"
            print("已上传 Release 资产：\(finalURL)")
        } else {
            print("::warning::未找到 gh CLI，跳过 Release 上传（本地测试时正常）；url 回退为上游直链")
        }
        try? FileManager.default.removeItem(atPath: zipPath)
        try? FileManager.default.removeItem(
            atPath: (namedPath as NSString).deletingLastPathComponent)

        // 清理该 cask 的旧版 Release：只保留本次发布的 tagName，其余 <formula>-* 全删。
        // 删除单个失败只警告不阻断（旧 release 残留只占空间，不影响安装走新版）。
        deleteOldCaskReleases(repo: repo, formula: config.formula, keepTag: tagName)
    }

    // 6. 改写公式/cask（镜像流整条换 url；其余只做版本子串替换，保插值）
    let (newContent, bottleStale) = rewriteFormula(content, newURL: finalURL,
                                                   newVersion: stable, oldVersion: current,
                                                   sha: sha,
                                                   replaceURLLine: config.uploadRelease)
    do {
        try newContent.write(toFile: formulaFile, atomically: true, encoding: .utf8)
    } catch {
        fail("写回 \(formulaFile) 失败：\(error)")
    }
    if bottleStale {
        print("已摘除失效的 bottle 块（其 sha256 属于旧版本），需重跑 bottle workflow 重建 GHCR 瓶")
    }

    // 7. 改后自检（注意：原始字符串 #"..."# 里 \(...) 不是插值，这里必须用普通字符串）
    if config.uploadRelease {
        guard newContent.contains("url \"\(finalURL)\"") else { fail("url 未成功更新到 \(finalURL)") }
    } else {
        // 字面 url（版本号替换后应与 finalURL 一致），或插值 url（#{version}，
        // version 行已同步则自动指向新版）
        let literalOK = newContent.contains("url \"\(finalURL)\"")
        let interpOK = newContent.contains("#{version}")
        guard literalOK || interpOK else { fail("url 未成功更新到 \(finalURL)") }
    }
    guard newContent.contains("sha256 \"\(sha)\"") else { fail("sha256 未成功更新") }

    print("公式已更新：\(current) -> \(stable)")
    emit("status=updated")
    emit("current_version=\(current)")
    emit("new_version=\(stable)")
    emit("sha256=\(sha)")
    emit("bottle_stale=\(bottleStale)")
}

/// 清理某 cask 的旧版 GitHub Release：只保留 keepTag，其余 tagName 形如 "<formula>-*" 的旧 release 全删。
/// 用于 workbuddy 等走 Release 分发的 cask——每次发新版后把旧 release 清掉，避免旧资产堆积。
private func deleteOldCaskReleases(repo: String, formula: String, keepTag: String) {
    guard let gh = which("gh") else { return }

    // gh release list 默认只回前 30 个，给足上限；--json 拿 tagName 列表
    let (listStatus, listOut) = run(gh, ["release", "list", "--repo", repo,
                                         "--exclude-drafts", "--limit", "100", "--json", "tagName"])
    guard listStatus == 0 else {
        print("::warning::列出 Release 失败，跳过旧版清理")
        return
    }
    // 注意：`gh release list --json tagName` 回的是对象数组
    // [{"tagName":"..."}]，不是字符串数组——直接 as? [String] 恒失败
    // （2026-09-04 实测：旧版清理从未真正跑起来过），必须先取 tagName 字段。
    guard let data = listOut.data(using: .utf8),
          let items = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
        print("::warning::解析 Release 列表失败，跳过旧版清理")
        return
    }
    let tags = items.compactMap { $0["tagName"] as? String }

    let prefix = "\(formula)-"
    for tag in tags {
        guard tag != keepTag, tag.hasPrefix(prefix) else { continue }
        print("清理旧版 Release：\(tag)")
        let (delStatus, _) = run(gh, ["release", "delete", tag, "--repo", repo, "--yes"])
        if delStatus == 0 {
            print("已删除旧版 Release：\(tag)")
        } else {
            print("::warning::删除旧版 Release \(tag) 失败，跳过（不影响发版结果）。")
        }
    }
}
