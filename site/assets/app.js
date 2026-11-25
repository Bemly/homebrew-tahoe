(() => {
  const root = document.documentElement;
  const scriptPath = new URL(document.currentScript.src).pathname;
  const basePath = scriptPath.replace(/assets\/app\.js$/, "");
  const language = document.documentElement.lang.startsWith("zh") ? "zh" : "en";
  const copyLabel = language === "zh" ? "复制到剪贴板" : "Copy to clipboard";
  const copiedLabel = language === "zh" ? "已复制" : "Copied";

  const themeSelect = document.querySelector("#theme");
  const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

  function applyTheme(choice) {
    const dark = choice === "dark" || (choice === "system" && systemTheme.matches);
    root.dataset.theme = dark ? "dark" : "light";
    root.dataset.themeChoice = choice;
    if (themeSelect) themeSelect.value = choice;
  }

  applyTheme(root.dataset.themeChoice || "system");
  themeSelect?.addEventListener("change", () => {
    const choice = themeSelect.value;
    try {
      localStorage.setItem("tahoe-theme", choice);
    } catch (error) {}
    applyTheme(choice);
  });
  const onSystemThemeChange = () => {
    if (root.dataset.themeChoice === "system") applyTheme("system");
  };
  if (systemTheme.addEventListener) systemTheme.addEventListener("change", onSystemThemeChange);
  else systemTheme.addListener(onSystemThemeChange);

  const languageSelect = document.querySelector("#language");
  languageSelect?.addEventListener("change", () => {
    let route = window.location.pathname.slice(basePath.length);
    if (route.startsWith("zh/")) route = route.slice(3);
    const prefix = basePath + (languageSelect.value === "zh" ? "zh/" : "");
    window.location.assign(`${prefix}${route}${window.location.search}${window.location.hash}`);
  });

  async function copyText(text) {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return;
    }
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.append(textarea);
    textarea.select();
    document.execCommand("copy");
    textarea.remove();
  }

  for (const element of document.querySelectorAll(".copyable")) {
    const code = element.querySelector("code");
    if (!code) continue;
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = "⧉";
    button.setAttribute("aria-label", copyLabel);
    button.title = copyLabel;
    button.addEventListener("click", async () => {
      const text = code.textContent.trim().replace(/^\$\s*/, "");
      try {
        await copyText(text);
        button.textContent = "✓";
        button.setAttribute("aria-label", copiedLabel);
        window.setTimeout(() => {
          button.textContent = "⧉";
          button.setAttribute("aria-label", copyLabel);
        }, 1200);
      } catch (error) {}
    });
    element.append(button);
  }

  const browser = document.querySelector(".package-browser");
  if (!browser) return;

  const search = browser.querySelector("#package-search");
  const type = browser.querySelector("#type-filter");
  const architecture = browser.querySelector("#arch-filter");
  const reset = browser.querySelector("#reset-filters");
  const chips = [...browser.querySelectorAll("[data-filter]")];
  const rows = [...browser.querySelectorAll("#package-table tbody tr")].filter((row) => row.id !== "no-results");
  const noResults = browser.querySelector("#no-results");
  const count = browser.querySelector("#package-count");
  const params = new URLSearchParams(window.location.search);
  const mode = browser.dataset.mode;
  let filter = params.get("type") || "all";
  if (!["all", "formula", "cask", "bottled"].includes(filter)) filter = "all";
  if (mode !== "all" && !["all", "bottled"].includes(filter)) filter = "all";

  if (search) search.value = params.get("search") || "";
  if (type) type.value = ["all", "formula", "cask"].includes(filter) ? filter : "all";
  if (architecture) architecture.value = params.get("arch") || "all";

  function updateUrl() {
    const query = new URLSearchParams();
    if (search?.value) query.set("search", search.value);
    if (filter !== "all" && filter !== mode) query.set("type", filter);
    if (architecture?.value && architecture.value !== "all") query.set("arch", architecture.value);
    const next = `${window.location.pathname}${query.size ? `?${query}` : ""}${window.location.hash}`;
    window.history.replaceState(null, "", next);
  }

  function updateChips() {
    for (const chip of chips) {
      const active = chip.dataset.filter === filter;
      chip.classList.toggle("active", active);
      chip.setAttribute("aria-pressed", String(active));
    }
    if (type) type.value = ["all", "formula", "cask"].includes(filter) ? filter : "all";
  }

  function applyFilters() {
    const query = (search?.value || "").trim().toLocaleLowerCase();
    const selectedArchitecture = architecture?.value || "all";
    let visible = 0;
    for (const row of rows) {
      const typeMatches = filter === "all"
        || (filter === "bottled" && row.dataset.bottle === "true")
        || row.dataset.type === filter;
      const architectureMatches = selectedArchitecture === "all"
        || row.dataset.arch === selectedArchitecture
        || row.dataset.arch === "universal";
      const searchMatches = !query || row.dataset.search.includes(query);
      const show = typeMatches && architectureMatches && searchMatches;
      row.hidden = !show;
      if (show) visible += 1;
    }
    if (noResults) noResults.hidden = visible !== 0;
    if (count) {
      const zh = language === "zh";
      count.textContent = zh
        ? `显示 ${visible} / ${rows.length} 个软件包`
        : `Showing ${visible} of ${rows.length} packages`;
    }
    updateChips();
    updateUrl();
  }

  search?.addEventListener("input", applyFilters);
  architecture?.addEventListener("change", applyFilters);
  type?.addEventListener("change", () => {
    filter = type.value;
    applyFilters();
  });
  reset?.addEventListener("click", () => {
    filter = "all";
    if (search) search.value = "";
    if (architecture) architecture.value = "all";
    applyFilters();
    search?.focus();
  });
  for (const chip of chips) {
    chip.addEventListener("click", () => {
      filter = chip.dataset.filter;
      applyFilters();
    });
  }

  document.addEventListener("keydown", (event) => {
    const target = event.target;
    const editing = target instanceof HTMLElement && (["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName) || target.isContentEditable);
    if (event.key === "/" && !editing) {
      event.preventDefault();
      search?.focus();
    }
    if (event.key === "Escape" && document.activeElement === search && search.value) {
      search.value = "";
      applyFilters();
    }
  });

  applyFilters();
})();
