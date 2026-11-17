// Eleventy config for the course site.
// Content source of truth: /phases, /assessments, /solutions (never copied or edited by the site).
// Module metadata comes ONLY from each module.md's front-matter (CLAUDE.md "Front-matter contract").
import fs from "node:fs";
import path from "node:path";
import markdownItAnchor from "markdown-it-anchor";
import { validate, hasCostAndTeardown, compareIds, formatDate } from "./site/lib/schema.js";
import site from "./site/_data/site.js";

const MODULE_GLOB = "phases/phase-*/*/module.md";
const ENTRY_DIAGNOSTIC = "assessments/phase-0-entry.md";
const GATE_RULES = "assessments/gate-rules.md";

// ---------- build warnings (never silent) ----------
let warnings = [];
const warn = (file, message) => warnings.push({ file, message });

// ---------- helpers ----------
const rel = (inputPath) => inputPath.replace(/^\.\//, "");

// Default Eleventy permalink rule, reused to rewrite relative .md links.
export const urlForFile = (file) => "/" + rel(file).replace(/\.md$/, "/");

// GitHub-style heading ids so existing in-content anchors (#part-2-the-phase-0-exit-gate) work.
export const slugify = (s) =>
  String(s).trim().toLowerCase().replace(/<[^>]+>/g, "").replace(/[^\p{L}\p{N}\s_-]/gu, "").replace(/\s/g, "-");

const kindOf = (inputPath) => {
  const p = rel(inputPath || "");
  if (/(^|\/)solutions\//.test(p)) return "solution";
  if (/^phases\/phase-\d\/[^/]+\/module\.md$/.test(p)) return "module";
  if (p.startsWith("assessments/")) return "assessment";
  return "page";
};

const firstHeading = (inputPath) => {
  try {
    const m = fs.readFileSync(inputPath, "utf8").match(/^#\s+(.+)$/m);
    return m ? m[1].trim() : null;
  } catch { return null; }
};

// Identity derived from the folder: used only to label warnings and to check
// front-matter against the folder (phases/phase-N/NN-slug/module.md).
const folderIdentity = (inputPath) => {
  const m = rel(inputPath).match(/^phases\/(phase-(\d))\/(\d+)-[^/]+\/module\.md$/);
  return m ? { phase: m[1], moduleId: `${m[2]}.${Number(m[3])}` } : {};
};

// ---------- entry diagnostic structure (headings convention) ----------
// Reads the item → module mapping from headings like "### Q1 → 0.0 · The root user"
// and "### Task 1 → 0.0 · …". Answers are NOT read (learners self-grade with the key).
const parseDiagnostic = () => {
  const text = fs.readFileSync(ENTRY_DIAGNOSTIC, "utf8");
  const items = [];
  for (const m of text.matchAll(/^###\s+(Q\d+|Task\s+\d+)\s+→\s+(\d\.\d+)\s+·\s+(.+)$/gm)) {
    const label = m[1].replace(/\s+/g, " ");
    items.push({ id: label.startsWith("Q") ? label : label.replace("Task ", "T"), label, type: label.startsWith("Q") ? "question" : "task", module: m[2], topic: m[3].trim() });
  }
  const questions = items.filter((i) => i.type === "question").length;
  const tasks = items.filter((i) => i.type === "task").length;
  const keyFile = "solutions/assessments/phase-0-entry-key.md";
  return {
    items,
    questions,
    tasks,
    // Placement rule, gate-rules.md §1.3: score ≥ skipScore of `questions` AND all tasks pass → next phase.
    skipScore: 10,
    keyUrl: fs.existsSync(keyFile) ? urlForFile(keyFile) : null,
    entryUrl: urlForFile(ENTRY_DIAGNOSTIC),
    gateRulesUrl: urlForFile(GATE_RULES),
  };
};

const readDiagnostic = () => {
  const d = parseDiagnostic();
  if (d.questions !== 12 || d.tasks !== 3) {
    warn(ENTRY_DIAGNOSTIC, `expected 12 questions and 3 tasks in "### Qn → <id> · …" / "### Task n → <id> · …" headings, found ${d.questions} and ${d.tasks}`);
  }
  return d;
};

const listPhases = () => fs.readdirSync("phases").filter((d) => /^phase-\d$/.test(d)).sort()
  .map((phase) => ({ phase, label: `Phase ${phase.split("-")[1]}` }));

export default function (eleventyConfig) {
  // ---- what is (and isn't) content ----
  for (const p of [
    "README.md", "CLAUDE.md", "AUDIT.md", "PROGRESS.md", "MAPPING.md", "index.html",
    "templates/**", ".claude/**", "node_modules/**", "_site/**", "site/lib/**", "site/scripts/**",
  ]) eleventyConfig.ignores.add(p);

  eleventyConfig.addPassthroughCopy({ "site/assets": "assets" });
  eleventyConfig.addPassthroughCopy({ "index.html": "legacy/index.html" }); // legacy single-page course, kept reachable

  // ---- markdown: no template engine inside content (modules contain ${{ }} and {% %} literally) ----
  eleventyConfig.amendLibrary("md", (md) => {
    md.use(markdownItAnchor, { slugify, tabIndex: false });
    const fallback = md.renderer.rules.link_open || ((t, i, o, e, self) => self.renderToken(t, i, o));
    md.renderer.rules.link_open = (tokens, idx, opts, env, self) => {
      const t = tokens[idx];
      const href = t.attrGet("href");
      const from = env?.page?.inputPath;
      if (href && from && !/^([a-z]+:|\/\/|#|\/)/i.test(href)) {
        const [file, hash] = href.split("#");
        if (/\.md$/.test(file)) {
          const target = path.posix.normalize(path.posix.join(path.posix.dirname(rel(from)), file));
          if (!fs.existsSync(target)) warn(rel(from), `link to missing file "${href}"`);
          t.attrSet("href", urlForFile(target) + (hash ? `#${hash}` : ""));
        }
      }
      return fallback(tokens, idx, opts, env, self);
    };
  });

  // ---- data available to every page ----
  eleventyConfig.addGlobalData("layout", "layouts/base.njk");
  eleventyConfig.addGlobalData("eleventyComputed", {
    kind: (d) => kindOf(d.page?.inputPath),
    robots: (d) => (kindOf(d.page?.inputPath) === "solution" ? "noindex, nofollow" : "index, follow"),
    pageTitle: (d) => d.title || firstHeading(d.page?.inputPath) || "aws-devops-platform course",
  });
  eleventyConfig.addGlobalData("diagnostic", readDiagnostic);
  eleventyConfig.addGlobalData("phases", listPhases);

  // ---- collections ----
  eleventyConfig.addCollection("modules", (api) => {
    const seen = new Map();
    const records = api.getFilteredByGlob(MODULE_GLOB).map((item) => {
      const file = rel(item.inputPath);
      const d = item.data;
      const folder = folderIdentity(item.inputPath);
      const problems = validate(d);
      if (d.phase && folder.phase && d.phase !== folder.phase) problems.push(`"phase" is "${d.phase}" but the file is in ${folder.phase}/`);
      if (d.moduleId && folder.moduleId && d.moduleId !== folder.moduleId) problems.push(`"moduleId" is "${d.moduleId}" but the folder number implies "${folder.moduleId}"`);
      const id = typeof d.moduleId === "string" ? d.moduleId : folder.moduleId;
      if (seen.has(id)) problems.push(`duplicate moduleId "${id}" (also ${seen.get(id)})`);
      seen.set(id, file);
      const verifiedDate = formatDate(d.lastVerified);
      if ("lastVerified" in d && d.lastVerified === null) problems.push(`"lastVerified" is null — not yet verified`);
      const costOk = hasCostAndTeardown(d);
      if (!costOk) problems.push("cost/teardown front-matter missing or incomplete — module hidden from nav");
      for (const p of problems) warn(file, p);
      return {
        file,
        url: item.url,
        id,
        phase: typeof d.phase === "string" ? d.phase : folder.phase,
        title: typeof d.title === "string" ? d.title : null,
        goal: typeof d.goal === "string" ? d.goal : null,
        timeEstimate: d.timeEstimate ?? null,
        costEstimate: d.costEstimate ?? null,
        costAssumptions: d.costAssumptions ?? null,
        hasTeardown: d.hasTeardown === true,
        hasDebuggingLab: d.hasDebuggingLab === true,
        prerequisites: Array.isArray(d.prerequisites) ? d.prerequisites : [],
        toolsPinned: d.toolsPinned && typeof d.toolsPinned === "object" ? d.toolsPinned : {},
        verified: "lastVerified" in d ? (verifiedDate ? { state: "verified", date: verifiedDate } : d.lastVerified === null ? { state: "unverified" } : { state: "unknown" }) : { state: "unknown" },
        frontMatterOk: problems.length === 0,
        inNav: costOk && typeof d.moduleId === "string" && typeof d.title === "string",
        labsDir: fs.existsSync(path.join(path.dirname(file), "labs")) ? path.dirname(file) + "/labs" : null,
      };
    });
    // prerequisites must point at existing modules (warn while modules are still being written)
    const ids = new Set(records.map((r) => r.id));
    for (const r of records) for (const p of r.prerequisites) if (!ids.has(p)) warn(r.file, `prerequisite "${p}" has no module yet`);
    return records.sort((a, b) => compareIds(a.id, b.id));
  });

  eleventyConfig.addCollection("assessments", (api) => api.getFilteredByGlob("assessments/*.md"));

  // ---- filters ----
  eleventyConfig.addFilter("navModules", (modules, phase) => (modules || []).filter((m) => m.phase === phase && m.inNav));
  eleventyConfig.addFilter("hiddenCount", (modules, phase) => (modules || []).filter((m) => m.phase === phase && !m.inNav).length);
  eleventyConfig.addFilter("moduleFor", (modules, inputPath) => (modules || []).find((m) => m.file === rel(inputPath)));
  eleventyConfig.addFilter("json", (v) => JSON.stringify(v ?? null).replace(/</g, "\\u003c"));
  eleventyConfig.addFilter("labsUrl", (dir, repo) => (dir && repo?.treeUrl ? `${repo.treeUrl}/${dir}` : null));

  // ---- warnings: reset per build, print a summary, write a machine-readable report ----
  eleventyConfig.on("eleventy.before", () => { warnings = []; });
  eleventyConfig.on("eleventy.after", ({ dir, results }) => {
    // diagnostic items must route to modules that exist (warn while Phase 0 is being written)
    const diag = parseDiagnostic();
    const moduleIds = new Set(
      fs.readdirSync("phases").flatMap((p) => (/^phase-\d$/.test(p) ? fs.readdirSync(path.join("phases", p)) : []).map((m) => {
        const n = m.match(/^(\d+)-/); return n ? `${p.split("-")[1]}.${Number(n[1])}` : null;
      })).filter(Boolean),
    );
    for (const m of new Set(diag.items.map((i) => i.module))) {
      if (!moduleIds.has(m)) warn(ENTRY_DIAGNOSTIC, `diagnostic routes to module ${m}, which has no folder under /phases yet`);
    }
    if (!site.url) warn("sitemap.xml", "no absolute base URL (SITE_URL / VERCEL_URL unset) — sitemap.xml and canonical links skipped");
    const out = path.join(dir.output, "build-warnings.json");
    fs.writeFileSync(out, JSON.stringify({ generatedAt: new Date().toISOString(), count: warnings.length, warnings }, null, 2));
    if (warnings.length) {
      console.warn(`\n[course-site] ${warnings.length} build warning(s):`);
      for (const w of warnings) console.warn(`  ⚠ ${w.file}: ${w.message}`);
      console.warn(`[course-site] full list: ${out}\n`);
    } else {
      console.log("[course-site] no build warnings");
    }
  });

  return {
    dir: { input: ".", includes: "site/_includes", data: "site/_data", output: "_site" },
    markdownTemplateEngine: false,
    htmlTemplateEngine: "njk",
    templateFormats: ["md", "njk", "11ty.js"],
  };
}
