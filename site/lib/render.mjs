const COPY = {
  en: {
    locale: "en",
    title: "bemly/tahoe",
    subtitle: "The Package Manager for Intel Macs",
    support: "Homebrew packages for Intel (x86_64) Macs running macOS 26 (Tahoe) and later.",
    language: "Language",
    theme: "Theme",
    system: "System",
    light: "Light",
    dark: "Dark",
    browse: "Browse packages",
    search: "Search packages",
    installTitle: "Install bemly/tahoe",
    installIntro: "Add this third-party tap to Homebrew, then install packages by their fully qualified name.",
    installNote: "If the same package is already installed from homebrew/core, uninstall that copy first. Formulae and casks with the same token cannot coexist across taps.",
    whyTitle: "Why bemly/tahoe?",
    whyLead: "Homebrew no longer publishes Intel bottles for macOS 26. This tap keeps Intel Macs on a bottle-first path.",
    whyPrebuilt: "Upstream macOS amd64 packages are repackaged whenever they exist. Source-only software and the same-name dependency stack are built once on a macOS 26 Intel CI runner.",
    whyDelivery: "Formulae are distributed as tahoe bottles through GHCR. Desktop apps and input methods are mirrored as casks to this repository's GitHub Releases.",
    packagesTitle: "Homebrew Packages",
    packagesLead: "This site lists only the formulae and casks available from bemly/tahoe. It does not include homebrew/core or any other tap.",
    formulaDesc: "Formulae provide command-line tools, libraries and services. Install them with brew install and the full bemly/tahoe/ name.",
    caskDesc: "Casks provide desktop applications and input methods. Install them with brew install --cask and the full bemly/tahoe/ name.",
    allPackages: "All packages",
    formulae: "Formulae",
    casks: "Casks",
    formula: "Formula",
    cask: "Cask",
    totalPackages: "Packages",
    bottled: "Tahoe bottles",
    quickInstall: "Quick install",
    quickInstallDesc: "A few commonly used packages from this tap. Every command uses the fully qualified name.",
    requirementsTitle: "Requirements",
    requirementsLead: "Designed for Intel Macs that cannot use Homebrew's current Apple Silicon bottle workflow.",
    cpu: "CPU",
    cpuValue: "Intel x86_64",
    os: "Operating system",
    osValue: "macOS 26 Tahoe or later",
    exceptions: "Exceptions",
    exceptionsValue: "opencode and ripgrep are dual-architecture; afm is an Apple Silicon-only cask. Universal casks are marked on their detail pages.",
    resourcesTitle: "Resources",
    documentation: "Documentation",
    documentationDesc: "Installation instructions, package notes and same-name migration guidance.",
    source: "Source repository",
    sourceDesc: "Formula and cask definitions, update watchers and bottle workflows.",
    issues: "Issues and discussions",
    issuesDesc: "Report a packaging problem or ask a question on GitHub.",
    footer: "Maintained by Bemly. Not affiliated with Homebrew.",
    designCredit: "Visual design based on",
    generated: "Metadata generated",
    packageIndexTitle: "Package index",
    packageIndexLead: "All packages provided by the bemly/tahoe tap, generated directly from Formula/ and Casks/.",
    formulaIndexLead: "Command-line tools, libraries and services provided by the bemly/tahoe tap.",
    caskIndexLead: "Desktop applications and input methods provided by the bemly/tahoe tap.",
    searchPlaceholder: "Search name, description, version or dependency",
    all: "All",
    bottledOnly: "Bottled",
    architecture: "Architecture",
    anyArchitecture: "Any architecture",
    intel: "Intel",
    appleSilicon: "Apple Silicon",
    universal: "Universal / dual-arch",
    reset: "Reset",
    showing: "Showing",
    of: "of",
    packages: "packages",
    noResults: "No packages match your filters.",
    package: "Package",
    version: "Version",
    type: "Type",
    description: "Description",
    installCommand: "Install command",
    homepage: "Homepage",
    license: "License",
    revision: "Revision",
    binaryPackage: "Binary package",
    available: "Available",
    notApplicable: "Not applicable",
    tap: "Tap",
    dependencies: "Dependencies",
    dependency: "Dependency",
    kind: "Kind",
    sourceKind: "Source",
    runtime: "Runtime",
    build: "Build",
    test: "Test",
    noLinkage: "No linkage",
    system: "System",
    core: "homebrew/core",
    thisTap: "bemly/tahoe",
    noDependencies: "No declared dependencies.",
    conflicts: "Conflicts with",
    autoUpdates: "This cask can update itself outside Homebrew. Use brew upgrade --greedy to include it in upgrades.",
    mirrored: "The install artifact is mirrored to this repository's GitHub Releases.",
    upstream: "Upstream / mirrored artifact",
    formulaCode: "Formula code",
    caskCode: "Cask code",
    kegOnly: "Keg-only",
    scheduledDeprecation: "Deprecation scheduled for",
    scheduledDisable: "Disable scheduled for",
    deprecated: "Deprecated",
    disabled: "Disabled",
    notFound: "Page not found",
    notFoundDesc: "The package or page you requested is not part of bemly/tahoe.",
    backHome: "Back to the homepage",
    copy: "Copy to clipboard",
    copied: "Copied",
    searchLabel: "Search this tap",
    skip: "Skip to content",
  },
  zh: {
    locale: "zh-CN",
    title: "bemly/tahoe",
    subtitle: "专为 Intel Mac 打造的 Package Manager",
    support: "为运行 macOS 26（Tahoe）及更高版本的 Intel（x86_64）Mac 提供 Homebrew 软件包。",
    language: "语言",
    theme: "主题",
    system: "跟随系统",
    light: "浅色",
    dark: "深色",
    browse: "浏览软件包",
    search: "搜索软件包",
    installTitle: "安装 bemly/tahoe",
    installIntro: "将这个第三方 tap 添加到 Homebrew，然后使用完整名称安装软件包。",
    installNote: "如果已从 homebrew/core 安装同名软件，请先卸载 Core 版本。同名公式或 cask 不能跨 tap 共存。",
    whyTitle: "为什么选择 bemly/tahoe？",
    whyLead: "Homebrew 从 macOS 26 起不再发布 Intel 瓶。本 tap 让 Intel Mac 继续走“预编译优先”的安装路线。",
    whyPrebuilt: "上游有 macOS amd64 预编译包时直接重打包；仅有源码的软件和同名依赖栈，则在 macOS 26 Intel CI runner 上一次性构建。",
    whyDelivery: "公式通过 GHCR 以 tahoe 瓶分发；桌面应用和输入法作为 cask 镜像到本仓库的 GitHub Releases。",
    packagesTitle: "Homebrew 软件包",
    packagesLead: "本站只列出 bemly/tahoe 提供的公式与 cask，不包含 homebrew/core 或其他 tap 的软件包。",
    formulaDesc: "公式提供命令行工具、库和服务。使用 brew install 加上完整的 bemly/tahoe/ 名称安装。",
    caskDesc: "Cask 提供桌面应用和输入法。使用 brew install --cask 加上完整的 bemly/tahoe/ 名称安装。",
    allPackages: "全部软件包",
    formulae: "公式",
    casks: "Cask",
    formula: "公式",
    cask: "Cask",
    totalPackages: "软件包",
    bottled: "Tahoe 瓶",
    quickInstall: "快速安装",
    quickInstallDesc: "本 tap 中几个常用软件包。所有命令均使用完整名称。",
    requirementsTitle: "系统要求",
    requirementsLead: "面向无法使用 Homebrew 当前 Apple Silicon 瓶工作流的 Intel Mac。",
    cpu: "处理器",
    cpuValue: "Intel x86_64",
    os: "操作系统",
    osValue: "macOS 26 Tahoe 或更高版本",
    exceptions: "例外",
    exceptionsValue: "opencode 与 ripgrep 支持双架构；afm 是仅 Apple Silicon 的 cask。通用 cask 会在详情页标注。",
    resourcesTitle: "相关资源",
    documentation: "使用文档",
    documentationDesc: "安装说明、软件包备注和同名迁移指南。",
    source: "源代码仓库",
    sourceDesc: "公式与 cask 定义、更新检查器和制瓶工作流。",
    issues: "问题与讨论",
    issuesDesc: "在 GitHub 报告打包问题或提问。",
    footer: "由 Bemly 维护，与 Homebrew 官方无隶属关系。",
    designCredit: "视觉设计参考",
    generated: "元数据生成时间",
    packageIndexTitle: "软件包目录",
    packageIndexLead: "bemly/tahoe tap 提供的全部软件包，直接从 Formula/ 与 Casks/ 生成。",
    formulaIndexLead: "bemly/tahoe tap 提供的命令行工具、库和服务。",
    caskIndexLead: "bemly/tahoe tap 提供的桌面应用和输入法。",
    searchPlaceholder: "搜索名称、说明、版本或依赖",
    all: "全部",
    bottledOnly: "已有瓶",
    architecture: "架构",
    anyArchitecture: "全部架构",
    intel: "Intel",
    appleSilicon: "Apple Silicon",
    universal: "通用 / 双架构",
    reset: "重置",
    showing: "显示",
    of: "/",
    packages: "个软件包",
    noResults: "没有符合筛选条件的软件包。",
    package: "软件包",
    version: "版本",
    type: "类型",
    description: "说明",
    installCommand: "安装命令",
    homepage: "主页",
    license: "许可证",
    revision: "修订号",
    binaryPackage: "二进制瓶",
    available: "可用",
    notApplicable: "不适用",
    tap: "Tap",
    dependencies: "依赖",
    dependency: "依赖",
    kind: "类型",
    sourceKind: "来源",
    runtime: "运行时",
    build: "构建",
    test: "测试",
    noLinkage: "不链接",
    system: "系统",
    core: "homebrew/core",
    thisTap: "bemly/tahoe",
    noDependencies: "未声明依赖。",
    conflicts: "冲突项",
    autoUpdates: "此 cask 可在 Homebrew 之外自行更新。使用 brew upgrade --greedy 可在升级时包含它。",
    mirrored: "安装包已镜像到本仓库的 GitHub Releases。",
    upstream: "上游 / 镜像安装包",
    formulaCode: "公式源码",
    caskCode: "Cask 源码",
    kegOnly: "仅保留在 Cellar",
    scheduledDeprecation: "计划弃用日期",
    scheduledDisable: "计划禁用日期",
    deprecated: "已弃用",
    disabled: "已禁用",
    notFound: "页面不存在",
    notFoundDesc: "请求的软件包或页面不属于 bemly/tahoe。",
    backHome: "返回首页",
    copy: "复制到剪贴板",
    copied: "已复制",
    searchLabel: "搜索本 tap",
    skip: "跳到正文",
  },
};

const REPOSITORY_URL = "https://github.com/Bemly/homebrew-tahoe";
const HOMEBREW_URL = "https://brew.sh";

export function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function safeUrl(value) {
  if (!value) return "";
  try {
    const url = new URL(value);
    return ["https:", "http:"].includes(url.protocol) ? url.href : "";
  } catch {
    return "";
  }
}

function routeUrl(config, lang, route = "") {
  return `${config.basePath}${lang === "zh" ? "zh/" : ""}${route}`;
}

function canonicalUrl(config, lang, route = "") {
  return `${config.siteUrl}${routeUrl(config, lang, route)}`;
}

function packageDescription(pkg, lang) {
  return lang === "zh" ? pkg.descZh : pkg.desc;
}

function typeLabel(pkg, copy) {
  return pkg.type === "formula" ? copy.formula : copy.cask;
}

function architectureValue(pkg) {
  if (pkg.architectures.length === 2) return "universal";
  return pkg.architectures[0] ?? "universal";
}

function architectureLabel(pkg, copy) {
  const value = architectureValue(pkg);
  if (value === "universal") return copy.universal;
  return value === "arm64" ? copy.appleSilicon : copy.intel;
}

function installCommand(pkg) {
  return pkg.type === "formula"
    ? `brew install ${pkg.fullName}`
    : `brew install --cask ${pkg.fullName}`;
}

function copyable(command, copy) {
  return `<div class="copyable install-command"><figure class="highlight"><pre><code class="language-bash" data-lang="bash">${escapeHtml(command)}</code></pre></figure></div>`;
}

function controls(config, lang, copy) {
  const options = [
    ["system", copy.system],
    ["light", copy.light],
    ["dark", copy.dark],
  ].map(([value, label]) => `<option value="${value}">${escapeHtml(label)}</option>`).join("");
  return `
    <div id="header-controls">
      <a class="header-browse" href="${routeUrl(config, lang, "packages/")}">${escapeHtml(copy.browse)}</a>
      <label class="hidden" for="language">${escapeHtml(copy.language)}</label>
      <select id="language" name="language" title="${escapeHtml(copy.language)}" aria-label="${escapeHtml(copy.language)}">
        <option value="en"${lang === "en" ? " selected" : ""}>English</option>
        <option value="zh"${lang === "zh" ? " selected" : ""}>简体中文</option>
      </select>
      <label class="hidden" for="theme">${escapeHtml(copy.theme)}</label>
      <select id="theme" name="theme" title="${escapeHtml(copy.theme)}" aria-label="${escapeHtml(copy.theme)}">${options}</select>
    </div>`;
}

function pageShell(config, lang, route, title, description, body, options = {}) {
  const copy = COPY[lang];
  const canonical = canonicalUrl(config, lang, route);
  const alternate = canonicalUrl(config, lang === "en" ? "zh" : "en", route);
  const home = routeUrl(config, lang);
  const mainClass = options.mainClass ?? "default";
  const structuredData = {
    "@context": "https://schema.org",
    "@type": options.schemaType ?? "WebPage",
    name: title,
    description,
    url: canonical,
    inLanguage: copy.locale,
    isPartOf: { "@type": "WebSite", name: copy.title, url: canonicalUrl(config, lang) },
  };
  return `<!DOCTYPE html>
<html lang="${copy.locale}" data-theme="system">
<head>
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; connect-src 'self'; font-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'none'; form-action 'none'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'">
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeHtml(description)}">
  <link rel="canonical" href="${escapeHtml(canonical)}">
  <link rel="alternate" hreflang="en" href="${escapeHtml(canonicalUrl(config, "en", route))}">
  <link rel="alternate" hreflang="zh-CN" href="${escapeHtml(canonicalUrl(config, "zh", route))}">
  <link rel="alternate" hreflang="x-default" href="${escapeHtml(canonicalUrl(config, "en", route))}">
  <meta property="og:title" content="${escapeHtml(title)}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta property="og:url" content="${escapeHtml(canonical)}">
  <meta property="og:type" content="website">
  <meta name="twitter:card" content="summary">
  <link rel="icon" href="${config.basePath}assets/homebrew.svg" type="image/svg+xml">
  <link rel="stylesheet" href="${config.basePath}assets/brew.css" media="screen">
  <link rel="stylesheet" href="${config.basePath}assets/site.css" media="screen">
  <script type="application/ld+json">${JSON.stringify(structuredData).replaceAll("<", "\\u003c")}</script>
  <script>
    (function () {
      var choice = "system";
      try { choice = localStorage.getItem("tahoe-theme") || "system"; } catch (error) {}
      var dark = choice === "dark" || (choice === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);
      document.documentElement.dataset.theme = dark ? "dark" : "light";
      document.documentElement.dataset.themeChoice = choice;
    })();
  </script>
</head>
<body>
  <a class="skip-link" href="#content">${escapeHtml(copy.skip)}</a>
  <div id="wrap">
    <header id="header">
      <div id="brand">
        <img alt="Homebrew" src="${config.basePath}assets/homebrew.svg" width="128" height="128">
        <h1><a href="${home}">${escapeHtml(copy.title)}</a></h1>
      </div>
      <p id="subtitle"><strong>${escapeHtml(copy.subtitle)}</strong></p>
      <p class="support-note header-support">${escapeHtml(copy.support)}</p>
      ${controls(config, lang, copy)}
    </header>
    <main id="content">
      <div id="${mainClass}">${body}</div>
    </main>
  </div>
  <aside><a href="${REPOSITORY_URL}"><img id="forkme" src="${config.basePath}assets/forkme.svg" alt="Fork on GitHub"></a></aside>
  <script src="${config.basePath}assets/app.js" defer></script>
</body>
</html>`;
}

function stats(packages, copy) {
  const items = [
    [packages.length, copy.totalPackages],
    [packages.filter((pkg) => pkg.type === "formula").length, copy.formulae],
    [packages.filter((pkg) => pkg.type === "cask").length, copy.casks],
    [packages.filter((pkg) => pkg.hasBottle).length, copy.bottled],
  ];
  return `<div class="tap-stats">${items.map(([value, label]) => `<div class="tap-stat"><strong>${value}</strong><span>${escapeHtml(label)}</span></div>`).join("")}</div>`;
}

function packageCard(pkg, config, lang, copy) {
  const href = routeUrl(config, lang, `${pkg.type}/${encodeURIComponent(pkg.token)}/`);
  const status = pkg.disabled ? copy.disabled : pkg.deprecated ? copy.deprecated : "";
  return `<article class="package-card">
    <div class="package-card-heading"><a href="${href}">${escapeHtml(pkg.token)}</a><span class="version-badge">${escapeHtml(pkg.version)}</span></div>
    <p>${escapeHtml(packageDescription(pkg, lang))}</p>
    <div class="package-card-meta"><span>${escapeHtml(typeLabel(pkg, copy))}</span><span>${escapeHtml(architectureLabel(pkg, copy))}</span>${status ? `<span class="status-badge">${escapeHtml(status)}</span>` : ""}</div>
    <code>${escapeHtml(installCommand(pkg))}</code>
  </article>`;
}

export function renderHome(config, packages, generatedAt) {
  const render = (lang) => {
    const copy = COPY[lang];
    const featuredTokens = ["gh", "node", "ffmpeg", "antigravity", "workbuddy", "qwen-ime"];
    const featured = featuredTokens.map((token) => packages.find((pkg) => pkg.token === token)).filter(Boolean);
    const body = `<div id="information"><ul>
      <li><section class="group row">
        <h2 id="install">${escapeHtml(copy.installTitle)}</h2>
        ${copyable("brew tap bemly/tahoe", copy)}
        <div class="col-1"><p>${escapeHtml(copy.installIntro)}</p><p><a href="${routeUrl(config, lang, "packages/")}">${escapeHtml(copy.browse)}</a></p></div>
        <div class="col-2"><p>${escapeHtml(copy.installNote)}</p></div>
      </section></li>
      <li><section class="group row">
        <h2 id="question">${escapeHtml(copy.whyTitle)}</h2>
        <div class="col-1"><p>${escapeHtml(copy.whyLead)}</p><p>${escapeHtml(copy.whyPrebuilt)}</p></div>
        <div class="col-2 example-panel"><p>${escapeHtml(copy.whyDelivery)}</p>${copyable("brew install bemly/tahoe/gh\nbrew install --cask bemly/tahoe/workbuddy", copy)}</div>
      </section></li>
      <li><section class="group row">
        <h2 id="homebrew-formulae">${escapeHtml(copy.packagesTitle)}</h2>
        <div class="col-1 package-copy"><p>${escapeHtml(copy.packagesLead)}</p><p>${escapeHtml(copy.formulaDesc)}</p><p>${escapeHtml(copy.caskDesc)}</p></div>
        <div class="col-2 package-summary">${stats(packages, copy)}</div>
        <div class="docs-grid">
          <a class="doc-card" href="${routeUrl(config, lang, "formula/")}"><h3>${escapeHtml(copy.formulae)}</h3><p>${escapeHtml(copy.formulaIndexLead)}</p></a>
          <a class="doc-card" href="${routeUrl(config, lang, "cask/")}"><h3>${escapeHtml(copy.casks)}</h3><p>${escapeHtml(copy.caskIndexLead)}</p></a>
          <a class="doc-card" href="${routeUrl(config, lang, "packages/")}"><h3>${escapeHtml(copy.allPackages)}</h3><p>${escapeHtml(copy.packageIndexLead)}</p></a>
        </div>
        <div class="quick-install"><h3>${escapeHtml(copy.quickInstall)}</h3><p>${escapeHtml(copy.quickInstallDesc)}</p><div class="package-grid">${featured.map((pkg) => packageCard(pkg, config, lang, copy)).join("")}</div></div>
      </section></li>
      <li><section class="group row">
        <h2 id="requirements">${escapeHtml(copy.requirementsTitle)}</h2>
        <div class="col-1"><p>${escapeHtml(copy.requirementsLead)}</p><p><strong>${escapeHtml(copy.cpu)}:</strong> ${escapeHtml(copy.cpuValue)}<br><strong>${escapeHtml(copy.os)}:</strong> ${escapeHtml(copy.osValue)}</p></div>
        <div class="col-2"><p><strong>${escapeHtml(copy.exceptions)}:</strong> ${escapeHtml(copy.exceptionsValue)}</p></div>
      </section></li>
      <li><section class="group row">
        <h2 id="resources">${escapeHtml(copy.resourcesTitle)}</h2>
        <div class="docs-grid">
          <a class="doc-card" href="${REPOSITORY_URL}#readme"><h3>${escapeHtml(copy.documentation)}</h3><p>${escapeHtml(copy.documentationDesc)}</p></a>
          <a class="doc-card" href="${REPOSITORY_URL}"><h3>${escapeHtml(copy.source)}</h3><p>${escapeHtml(copy.sourceDesc)}</p></a>
          <a class="doc-card" href="${REPOSITORY_URL}/issues"><h3>${escapeHtml(copy.issues)}</h3><p>${escapeHtml(copy.issuesDesc)}</p></a>
        </div>
      </section></li>
      <footer class="group row credits"><p>${escapeHtml(copy.footer)}<br>${escapeHtml(copy.designCredit)} <a href="${HOMEBREW_URL}">Homebrew</a>.<br>${escapeHtml(copy.generated)}: ${escapeHtml(generatedAt)}</p></footer>
    </ul></div>`;
    return pageShell(config, lang, "", `${copy.title}: ${copy.subtitle}`, copy.support, body, { mainClass: "site-home", schemaType: "WebSite" });
  };
  return { "index.html": render("en"), "zh/index.html": render("zh") };
}

function searchText(pkg) {
  return [pkg.token, ...pkg.names, pkg.desc, pkg.descZh, pkg.version, ...pkg.license, ...pkg.dependencies.map((dependency) => dependency.name)].join(" ").toLocaleLowerCase();
}

function packageRow(pkg, config, lang, copy) {
  const href = routeUrl(config, lang, `${pkg.type}/${encodeURIComponent(pkg.token)}/`);
  const status = pkg.disabled ? "disabled" : pkg.deprecated ? "deprecated" : "";
  return `<tr data-search="${escapeHtml(searchText(pkg))}" data-type="${pkg.type}" data-arch="${architectureValue(pkg)}" data-bottle="${pkg.hasBottle ? "true" : "false"}"${status ? ` class="${status}"` : ""}>
    <th scope="row"><a href="${href}"${status ? ` class="${status}"` : ""}>${escapeHtml(pkg.token)}</a></th>
    <td class="version-data">${escapeHtml(pkg.version)}${pkg.revision ? `<small>_${pkg.revision}</small>` : ""}</td>
    <td><span class="type-badge ${pkg.type}">${escapeHtml(typeLabel(pkg, copy))}</span></td>
    <td>${escapeHtml(packageDescription(pkg, lang))}</td>
  </tr>`;
}

function filterControls(config, lang, copy, mode) {
  const typeOptions = mode === "all" ? `<label><span class="hidden">${escapeHtml(copy.type)}</span><select id="type-filter"><option value="all">${escapeHtml(copy.all)}</option><option value="formula">${escapeHtml(copy.formulae)}</option><option value="cask">${escapeHtml(copy.casks)}</option></select></label>` : "";
  return `<div class="package-controls">
    <label class="package-search"><span class="hidden">${escapeHtml(copy.searchLabel)}</span><input id="package-search" type="search" autocomplete="off" placeholder="${escapeHtml(copy.searchPlaceholder)}" aria-label="${escapeHtml(copy.searchPlaceholder)}"></label>
    ${typeOptions}
    <label><span class="hidden">${escapeHtml(copy.architecture)}</span><select id="arch-filter"><option value="all">${escapeHtml(copy.anyArchitecture)}</option><option value="x86_64">${escapeHtml(copy.intel)}</option><option value="arm64">${escapeHtml(copy.appleSilicon)}</option><option value="universal">${escapeHtml(copy.universal)}</option></select></label>
    <button id="reset-filters" class="secondary-button" type="button">${escapeHtml(copy.reset)}</button>
  </div>
  <div class="filter-chips" role="group" aria-label="${escapeHtml(copy.type)}">
    <button type="button" data-filter="all" class="active">${escapeHtml(copy.all)}</button>
    ${mode === "all" ? `<button type="button" data-filter="formula">${escapeHtml(copy.formulae)}</button><button type="button" data-filter="cask">${escapeHtml(copy.casks)}</button>` : ""}
    ${mode !== "cask" ? `<button type="button" data-filter="bottled">${escapeHtml(copy.bottledOnly)}</button>` : ""}
  </div>`;
}

export function renderPackageIndex(config, packages, generatedAt, mode = "all") {
  const render = (lang) => {
    const copy = COPY[lang];
    const selected = mode === "all" ? packages : packages.filter((pkg) => pkg.type === mode);
    const title = mode === "all" ? copy.packageIndexTitle : mode === "formula" ? copy.formulae : copy.casks;
    const lead = mode === "all" ? copy.packageIndexLead : mode === "formula" ? copy.formulaIndexLead : copy.caskIndexLead;
    const route = mode === "all" ? "packages/" : `${mode}/`;
    const body = `<header class="page-heading"><p><a href="${routeUrl(config, lang)}">${escapeHtml(copy.title)}</a> / ${escapeHtml(title)}</p><h2>${escapeHtml(title)}</h2><p>${escapeHtml(lead)}</p></header>
      ${stats(packages, copy)}
      <section class="package-browser" data-mode="${mode}">
        ${filterControls(config, lang, copy, mode)}
        <p id="package-count" class="package-count" aria-live="polite">${escapeHtml(copy.showing)} ${selected.length} ${escapeHtml(copy.of)} ${selected.length} ${escapeHtml(copy.packages)}</p>
        <div class="wide-table"><table id="package-table"><thead><tr><th scope="col">${escapeHtml(copy.package)}</th><th scope="col">${escapeHtml(copy.version)}</th><th scope="col">${escapeHtml(copy.type)}</th><th scope="col">${escapeHtml(copy.description)}</th></tr></thead><tbody>${selected.map((pkg) => packageRow(pkg, config, lang, copy)).join("")}<tr id="no-results" hidden><td colspan="4">${escapeHtml(copy.noResults)}</td></tr></tbody></table></div>
      </section>
      <footer id="border-no-bottom">${escapeHtml(copy.generated)}: ${escapeHtml(generatedAt)}</footer>`;
    return pageShell(config, lang, route, `${title} · ${copy.title}`, lead, body, { mainClass: "package-index" });
  };
  const output = {};
  if (mode === "all") {
    output["packages/index.html"] = render("en");
    output["zh/packages/index.html"] = render("zh");
  } else {
    output[`${mode}/index.html`] = render("en");
    output[`zh/${mode}/index.html`] = render("zh");
  }
  return output;
}

function dependencySource(dependency, copy) {
  if (dependency.tap === "bemly/tahoe") return copy.thisTap;
  if (dependency.tap === "core") return copy.core;
  return copy.system;
}

function dependencyLink(dependency, config, lang, copy) {
  const local = packagesForLinks.has(`${dependency.tap}:${dependency.name}`);
  if (dependency.tap === "bemly/tahoe" && local) {
    return `<a href="${routeUrl(config, lang, `formula/${encodeURIComponent(dependency.name)}/`)}">${escapeHtml(dependency.name)}</a>`;
  }
  if (dependency.tap === "core") {
    return `<a href="https://formulae.brew.sh/formula/${encodeURIComponent(dependency.name)}" rel="nofollow">${escapeHtml(dependency.name)}</a>`;
  }
  return escapeHtml(dependency.name);
}

let packagesForLinks = new Set();

function dependencyKind(dependency, copy) {
  return dependency.kind === "no-linkage" ? copy.noLinkage : copy[dependency.kind] ?? dependency.kind;
}

function detailRow(label, value) {
  return `<tr><th scope="row">${escapeHtml(label)}</th><td>${value}</td></tr>`;
}

export function renderPackageDetail(config, pkg, generatedAt) {
  const render = (lang) => {
    const copy = COPY[lang];
    const route = `${pkg.type}/${encodeURIComponent(pkg.token)}/`;
    const indexRoute = `${pkg.type}/`;
    const homepage = safeUrl(pkg.homepage);
    const artifact = safeUrl(pkg.url);
    const sourceUrl = `${REPOSITORY_URL}/blob/main/${pkg.sourcePath}`;
    const status = pkg.disabled ? copy.disabled : pkg.deprecated ? copy.deprecated : "";
    const notices = [];
    if (pkg.autoUpdates) notices.push(`<p class="notice">${escapeHtml(copy.autoUpdates)}</p>`);
    if (pkg.mirrored) notices.push(`<p class="notice">${escapeHtml(copy.mirrored)}</p>`);
    if (pkg.deprecationDate && !pkg.deprecated) notices.push(`<p class="notice">${escapeHtml(copy.scheduledDeprecation)}: <strong>${escapeHtml(pkg.deprecationDate)}</strong></p>`);
    if (pkg.disableDate && !pkg.disabled) notices.push(`<p class="notice">${escapeHtml(copy.scheduledDisable)}: <strong>${escapeHtml(pkg.disableDate)}</strong></p>`);
    const dependencies = pkg.dependencies.length
      ? `<table><thead><tr><th scope="col">${escapeHtml(copy.dependency)}</th><th scope="col">${escapeHtml(copy.kind)}</th><th scope="col">${escapeHtml(copy.sourceKind)}</th></tr></thead><tbody>${pkg.dependencies.map((dependency) => `<tr><td>${dependencyLink(dependency, config, lang, copy)}</td><td>${escapeHtml(dependencyKind(dependency, copy))}</td><td>${escapeHtml(dependencySource(dependency, copy))}</td></tr>`).join("")}</tbody></table>`
      : `<p>${escapeHtml(copy.noDependencies)}</p>`;
    const metadata = `<table class="no-stack package-metadata"><tbody>
      ${detailRow(copy.version, escapeHtml(pkg.version) + (pkg.revision ? ` <small>${escapeHtml(copy.revision)} ${pkg.revision}</small>` : ""))}
      ${detailRow(copy.type, escapeHtml(typeLabel(pkg, copy)))}
      ${detailRow(copy.architecture, escapeHtml(architectureLabel(pkg, copy)))}
      ${detailRow(copy.os, escapeHtml(pkg.macos.length ? pkg.macos.map((value) => value === "tahoe" ? "macOS 26 Tahoe" : value).join(", ") : "macOS 26 Tahoe"))}
      ${detailRow(copy.license, escapeHtml(pkg.license.length ? pkg.license.join(", ") : copy.notApplicable))}
      ${detailRow(copy.binaryPackage, escapeHtml(pkg.type === "formula" ? pkg.hasBottle ? `${copy.available} · tahoe` : copy.notApplicable : pkg.mirrored ? copy.available : copy.notApplicable))}
      ${detailRow(copy.tap, `<code>${escapeHtml(pkg.fullName)}</code>`)}
      ${pkg.kegOnly ? detailRow(copy.kegOnly, escapeHtml(typeof pkg.kegOnly === "string" ? pkg.kegOnly : copy.available)) : ""}
    </tbody></table>`;
    const body = `<header class="page-heading package-detail-heading"><p><a href="${routeUrl(config, lang, indexRoute)}">${escapeHtml(pkg.type === "formula" ? copy.formulae : copy.casks)}</a> / ${escapeHtml(pkg.token)}</p><h2${status ? ` class="${pkg.disabled ? "disabled" : "deprecated"}"` : ""}>${escapeHtml(pkg.token)}</h2>${status ? `<p class="status-badge">${escapeHtml(status)}</p>` : ""}</header>
      <div class="install"><span class="label">${escapeHtml(copy.installCommand)}:</span>${copyable(installCommand(pkg), copy)}</div>
      <p class="desc">${escapeHtml(packageDescription(pkg, lang))}</p>
      ${homepage ? `<p class="homepage"><a rel="nofollow" href="${escapeHtml(homepage)}">${escapeHtml(homepage)}</a></p>` : ""}
      ${notices.join("")}
      ${metadata}
      <h3>${escapeHtml(copy.dependencies)}</h3>${dependencies}
      ${pkg.conflicts.length ? `<h3>${escapeHtml(copy.conflicts)}</h3><ul>${pkg.conflicts.map((conflict) => `<li><code>${escapeHtml(conflict)}</code></li>`).join("")}</ul>` : ""}
      <h3>${escapeHtml(copy.resources)}</h3><ul class="resource-list">
        <li>${escapeHtml(pkg.type === "formula" ? copy.formulaCode : copy.caskCode)}: <a href="${sourceUrl}" target="_blank" rel="noopener"><code>${escapeHtml(pkg.sourcePath)}</code></a></li>
        ${artifact ? `<li>${escapeHtml(copy.upstream)}: <a href="${escapeHtml(artifact)}" target="_blank" rel="noopener">${escapeHtml(pkg.url)}</a></li>` : ""}
        <li><a href="${routeUrl(config, lang, "packages/")}">${escapeHtml(copy.allPackages)}</a></li>
      </ul>
      <footer id="border-no-bottom">${escapeHtml(copy.generated)}: ${escapeHtml(generatedAt)}</footer>`;
    return pageShell(config, lang, route, `${pkg.token} · ${copy.title}`, packageDescription(pkg, lang), body);
  };
  return { [`${pkg.type}/${pkg.token}/index.html`]: render("en"), [`zh/${pkg.type}/${pkg.token}/index.html`]: render("zh") };
}

export function renderNotFound(config) {
  const render = (lang) => {
    const copy = COPY[lang];
    const body = `<h2>${escapeHtml(copy.notFound)}</h2><p>${escapeHtml(copy.notFoundDesc)}</p><p><a href="${routeUrl(config, lang)}">${escapeHtml(copy.backHome)}</a></p>`;
    return pageShell(config, lang, "404.html", `${copy.notFound} · ${copy.title}`, copy.notFoundDesc, body);
  };
  return { "404.html": render("en"), "zh/404.html": render("zh") };
}

export function renderSitemap(config, packages, generatedAt) {
  const routes = ["", "packages/", "formula/", "cask/", ...packages.map((pkg) => `${pkg.type}/${encodeURIComponent(pkg.token)}/`)];
  const urls = ["en", "zh"].flatMap((lang) => routes.map((route) => canonicalUrl(config, lang, route)));
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.map((url) => `<url><loc>${escapeHtml(url)}</loc><lastmod>${escapeHtml(generatedAt.slice(0, 10))}</lastmod></url>`).join("\n")}\n</urlset>\n`;
}

export function renderRobots(config) {
  return `User-agent: *\nAllow: /\nSitemap: ${config.siteUrl}${config.basePath}sitemap.xml\n`;
}

export function setPackageLinkInventory(packages) {
  packagesForLinks = new Set(packages.map((pkg) => `${pkg.type === "formula" ? "bemly/tahoe" : "bemly/tahoe"}:${pkg.token}`));
}
