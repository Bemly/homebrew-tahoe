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
// 版本来源两种（CheckConfig 二选一）：
//   - brew 流：formulae.brew.sh 的 versions.stable 判新（gh / fastfetch）；
//   - 自定义流 customRelease：brew 未收录软件的上游自有更新接口（WorkBuddy），
//     接口直接给版本号、下载直链、sha256。
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

    init(formula: String,
         formulaPath: String = "Formula",
         isCask: Bool = false,
         brewName: String? = nil,
         asset: ((String) -> String)? = nil,
         downloadURL: ((String) -> String)? = nil,
         checksumsURL: ((String) -> String)? = nil,
         customRelease: (() -> UpstreamRelease?)? = nil) {
        self.formula = formula
        self.formulaPath = formulaPath
        self.isCask = isCask
        self.brewName = brewName
        self.asset = asset
        self.downloadURL = downloadURL
        self.checksumsURL = checksumsURL
        self.customRelease = customRelease
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

/// 公式当前版本：优先 version 行（本 tap 公式不写，保留兼容），
/// 回退 url 行内第一处 [^0-9]点分段数字（与 brew 从 URL 扫描版本对应）。
/// 支持任意段数：2.99.0（gh）、2.68.1（fastfetch）、5.4.7.37521366（workbuddy）。
func currentVersion(in content: String) -> String? {
    if let m = firstMatch(#"(?m)^[ \t]*version "([^"]+)""#, in: content),
       let r = Range(m.range(at: 1), in: content) {
        return String(content[r])
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

// MARK: - 公式改写

private func fullRange(_ s: String) -> NSRange {
    NSRange(s.startIndex..<s.endIndex, in: s)
}

private func isURLDefinitionLine(_ line: String) -> Bool {
    line.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix(#"url ""#)
}

/// 改写公式：第一条 url 行整条替换为 newURL、version 行（如有）同步为新版本、
/// 主 sha256 行替换、摘除失效的 bottle do...end 块。
/// url 必须整条替换而非替换版本号子串——部分上游产物文件名带构建哈希
/// （如 WorkBuddy-darwin-x64-<ver>-<hash>.dmg），哈希每次部署都变。
/// version 行只有部分公式需要显式声明（brew 从 URL 扫不出正确版本时，如 node 的
/// darwin-x64.tar.gz 会扫出 "64"），有则必须同步，否则 url 与 version 脱节。
func rewriteFormula(_ content: String, newURL: String, newVersion: String,
                    sha: String) -> (content: String, bottleStale: Bool) {
    let shaLine = try! NSRegularExpression(pattern: #"^([ \t]*)sha256 "[0-9a-f]{64}""#)
    let versionLine = try! NSRegularExpression(pattern: #"^([ \t]*)version "[^"]+""#)
    let bottleStart = try! NSRegularExpression(pattern: #"^[ \t]*bottle do[ \t]*$"#)
    let blockEnd = try! NSRegularExpression(pattern: #"^[ \t]*end[ \t]*$"#)

    var result: [String] = []
    var bottleStale = false
    var skipping = false
    var urlReplaced = false
    var versionReplaced = false

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
        // 主 sha256 行（瓶块行是 sha256 cellar: ... 形态，天然不匹配）
        if let m = shaLine.firstMatch(in: replaced, range: fullRange(replaced)) {
            let indent = (replaced as NSString).substring(with: m.range(at: 1))
            replaced = "\(indent)sha256 \"\(sha)\""
        }
        // 只替换第一条 url 定义行（resource 块若有自己的 url 不受影响）
        if !urlReplaced, isURLDefinitionLine(replaced) {
            let indent = String(replaced.prefix(while: { $0 == " " || $0 == "\t" }))
            replaced = "\(indent)url \"\(newURL)\""
            urlReplaced = true
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
    return (result.joined(separator: "\n"), bottleStale)
}

// MARK: - 单包检查主流程

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

    // 2. 上游版本与下载直链（自定义来源优先，否则走 brew）
    let upstream: UpstreamRelease
    if let custom = config.customRelease {
        guard let release = custom() else {
            fail("无法从自定义更新接口获取 \(config.formula) 的版本信息")
        }
        upstream = release
        print("上游版本 : \(upstream.version)（自定义更新接口）")
    } else {
        guard let brewName = config.brewName,
              config.asset != nil,
              let urlTemplate = config.downloadURL else {
            fail("CheckConfig 配置不完整：需要 customRelease 或 brew 三件套（brewName/asset/downloadURL）")
        }
        // brew 的 versions.stable 是判据：这是 brew 上的版本号，不是上游 GitHub 的最新版
        let apiURL = "https://formulae.brew.sh/api/formula/\(brewName).json"
        let (httpCode, body) = curlHTTP(apiURL)
        if httpCode == 404 {
            // TODO(brew-missing)：brew 没有收录且未接 customRelease 的软件，无法判新。
            // 需要为该软件适配版本来源（照抄 workbuddy.swift 接上游自有接口），
            // 适配前先明确报告并停在这里（登记于 AGENTS.md 第 12 节待办）。
            print("brew 上没有 \(brewName)（formulae.brew.sh 404），跳过（TODO：适配版本来源）")
            emit("status=brew-missing")
            emit("current_version=\(current)")
            return
        }
        guard httpCode == 200,
              let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
              let versions = json["versions"] as? [String: Any],
              let stable = versions["stable"] as? String, !stable.isEmpty else {
            fail("无法从 formulae.brew.sh 获取 \(brewName) 的 stable 版本（HTTP \(httpCode.map(String.init) ?? "请求失败")）")
        }
        print("brew 版本 : \(stable)")
        upstream = UpstreamRelease(version: stable, downloadURL: urlTemplate(stable), sha256: nil)
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

    // cask：把安装包上传到本仓 Release，url 取 Release 资产地址（而非上游 COS 直链）
    var finalURL = downloadURL
    if config.isCask {
        let tagName = "\(config.formula)-\(stable)"
        let assetName = URL(fileURLWithPath: downloadURL).lastPathComponent
        let repo = ProcessInfo.processInfo.environment["GITHUB_REPOSITORY"] ?? "Bemly/homebrew-tahoe-intel"
        guard let zipPath = curlDownload(downloadURL) else {
            fail("下载 \(config.formula) 发布包失败，无法上传 Release")
        }
        // 校验已算好的 sha 与文件一致（防御性）
        if let fileHash = sha256(ofFile: zipPath), fileHash != sha {
            fail("文件 sha256 不一致：期望 \(sha)，实算 \(fileHash)")
        }
        let gh = which("gh")
        if let gh {
            let repoFlag = "--repo"
            let createArgs = ["release", "create", tagName, zipPath,
                              repoFlag, repo, "--generate-notes", "--title", "\(config.formula) \(stable)"]
            let (cStatus, cOut) = run(gh, createArgs)
            if cStatus != 0 {
                // 同名 tag 已存在（重复运行）→ 改为覆盖上传资产
                let uploadArgs = ["release", "upload", tagName, zipPath, repoFlag, repo, "--clobber"]
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

        // 清理该 cask 的旧版 Release：只保留本次发布的 tagName，其余 <formula>-* 全删。
        // 删除单个失败只警告不阻断（旧 release 残留只占空间，不影响安装走新版）。
        deleteOldCaskReleases(repo: repo, formula: config.formula, keepTag: tagName)
    }

    // 6. 改写公式/cask
    let (newContent, bottleStale) = rewriteFormula(content, newURL: finalURL,
                                                   newVersion: stable, sha: sha)
    do {
        try newContent.write(toFile: formulaFile, atomically: true, encoding: .utf8)
    } catch {
        fail("写回 \(formulaFile) 失败：\(error)")
    }
    if bottleStale {
        print("已摘除失效的 bottle 块（其 sha256 属于旧版本），需重跑 bottle workflow 重建 GHCR 瓶")
    }

    // 7. 改后自检（注意：原始字符串 #"..."# 里 \(...) 不是插值，这里必须用普通字符串）
    guard newContent.contains("url \"\(finalURL)\"") else { fail("url 未成功更新到 \(finalURL)") }
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
    guard let data = listOut.data(using: .utf8),
          let tags = (try? JSONSerialization.jsonObject(with: data)) as? [String] else {
        print("::warning::解析 Release 列表失败，跳过旧版清理")
        return
    }

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
