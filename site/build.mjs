import { cp, mkdir, readdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadPackages } from "./lib/metadata.mjs";
import {
  renderHome,
  renderNotFound,
  renderPackageDetail,
  renderPackageIndex,
  renderRobots,
  renderSitemap,
  setPackageLinkInventory,
} from "./lib/render.mjs";

const siteDirectory = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(siteDirectory, "..");

function argument(name, fallback) {
  const index = process.argv.indexOf(`--${name}`);
  return index >= 0 ? process.argv[index + 1] : fallback;
}

function normalizeBasePath(value) {
  const trimmed = value.trim() || "/";
  return `/${trimmed.replace(/^\/+|\/+$/g, "")}${trimmed === "/" ? "" : "/"}`;
}

function validatePackages(packages) {
  const errors = [];
  const seen = new Set();
  for (const pkg of packages) {
    const key = `${pkg.type}:${pkg.token}`;
    if (seen.has(key)) errors.push(`Duplicate package: ${key}`);
    seen.add(key);
    for (const field of ["token", "fullName", "desc", "homepage", "version", "sourcePath"]) {
      if (!pkg[field]) errors.push(`${key} is missing ${field}`);
    }
    if (!pkg.names.length) errors.push(`${key} has no display name`);
    if (!pkg.architectures.length) errors.push(`${key} has no architecture metadata`);
    if (!/^[a-z0-9][a-z0-9._+@-]*$/i.test(pkg.token)) errors.push(`${key} has an unsafe token`);
    if (pkg.url && !/^https?:\/\//.test(pkg.url)) errors.push(`${key} has an invalid artifact URL`);
  }
  if (errors.length) throw new Error(`Package metadata validation failed:\n${errors.join("\n")}`);
}

async function writeOutput(output, files) {
  for (const [relativePath, content] of Object.entries(files)) {
    const destination = path.join(output, relativePath);
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, content);
  }
}

async function build() {
  const output = path.resolve(root, argument("output", "_site"));
  if (output === root || !output.startsWith(`${root}${path.sep}`)) throw new Error("Output must stay inside the repository");
  const config = {
    basePath: normalizeBasePath(argument("base-path", process.env.BASE_PATH ?? "/")),
    siteUrl: (argument("site-url", process.env.SITE_URL ?? "https://bemly.github.io/homebrew-tahoe")).replace(/\/+$/, ""),
  };
  const packages = await loadPackages(root);
  validatePackages(packages);
  setPackageLinkInventory(packages);
  const generatedAt = new Date().toISOString();
  const files = {
    ...renderHome(config, packages, generatedAt),
    ...renderPackageIndex(config, packages, generatedAt, "all"),
    ...renderPackageIndex(config, packages, generatedAt, "formula"),
    ...renderPackageIndex(config, packages, generatedAt, "cask"),
    ...renderNotFound(config),
    "sitemap.xml": renderSitemap(config, packages, generatedAt),
    "robots.txt": renderRobots(config),
    "packages.json": `${JSON.stringify({ generatedAt, tap: "bemly/tahoe", packages }, null, 2)}\n`,
    ".nojekyll": "",
  };
  for (const pkg of packages) Object.assign(files, renderPackageDetail(config, pkg, generatedAt));

  await rm(output, { recursive: true, force: true });
  await mkdir(output, { recursive: true });
  await writeOutput(output, files);
  await cp(path.join(siteDirectory, "assets"), path.join(output, "assets"), { recursive: true });

  const existing = await readdir(output, { recursive: true });
  const formulae = packages.filter((pkg) => pkg.type === "formula").length;
  const casks = packages.length - formulae;
  console.log(`Built ${packages.length} packages (${formulae} formulae, ${casks} casks) into ${output}`);
  console.log(`Generated ${existing.filter((entry) => String(entry).endsWith(".html")).length} HTML pages.`);
}

build().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
