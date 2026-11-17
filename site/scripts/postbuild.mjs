// Post-build guards. Any failure exits 1 so a bad build never deploys.
//  1. No hardcoded localhost or old GitHub Pages base path in site code/config, or in built links.
//  2. No server-side state: no api/ or middleware, no Vercel functions/crons.
//  3. Solutions pages carry noindex and are absent from the sitemap.
import fs from "node:fs";
import path from "node:path";

const OUT = "_site";
const failures = [];
const fail = (m) => failures.push(m);

const walk = (dir) => fs.existsSync(dir)
  ? fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
      const p = path.join(dir, e.name);
      return e.isDirectory() ? walk(p) : [p];
    })
  : [];

const BANNED = [/localhost/i, /127\.0\.0\.1/, /\/aws_devops_course(\/|\b)/, /github\.io/i];

// 1a. site source + config (course content may legitimately mention localhost — e.g. kubectl port-forward — so content is not scanned)
const sources = [...walk("site").filter((f) => !f.includes(`${path.sep}scripts${path.sep}`)), "eleventy.config.js", "vercel.json", "package.json"];
for (const f of sources) {
  const text = fs.readFileSync(f, "utf8");
  for (const re of BANNED) if (re.test(text)) fail(`${f}: contains ${re}`);
}

// 1b. built links/attributes (href, src, action, canonical/meta content)
const ATTR = /\b(?:href|src|action|content)\s*=\s*"([^"]*)"/gi;
for (const f of walk(OUT).filter((f) => f.endsWith(".html") || f.endsWith(".xml") || f.endsWith(".txt"))) {
  const text = fs.readFileSync(f, "utf8");
  const values = f.endsWith(".html") ? [...text.matchAll(ATTR)].map((m) => m[1]) : [text];
  for (const v of values) for (const re of BANNED) if (re.test(v)) fail(`${f}: link/attribute contains ${re}: ${v.slice(0, 80)}`);
}

// 2. no server-side state
for (const p of ["api", "middleware.js", "middleware.ts", "functions", "netlify"]) if (fs.existsSync(p)) fail(`server-side path present: ${p}`);
const vercel = JSON.parse(fs.readFileSync("vercel.json", "utf8"));
for (const k of ["functions", "crons"]) if (k in vercel) fail(`vercel.json declares "${k}"`);
if (JSON.stringify(vercel.rewrites || []).includes("/api")) fail("vercel.json rewrites to /api");

// 3. solutions: noindex + not in sitemap
const solutionPages = walk(OUT).filter((f) => /[\\/]solutions[\\/]/.test(f) && f.endsWith(".html"));
for (const f of solutionPages) {
  if (!/<meta name="robots" content="noindex, nofollow">/.test(fs.readFileSync(f, "utf8"))) fail(`${f}: missing noindex meta`);
}
const sitemap = path.join(OUT, "sitemap.xml");
if (fs.existsSync(sitemap) && /\/solutions\//.test(fs.readFileSync(sitemap, "utf8"))) fail("sitemap.xml lists a solutions page");

if (failures.length) {
  console.error(`\n[postbuild] ${failures.length} check(s) FAILED:`);
  for (const m of failures) console.error(`  ✗ ${m}`);
  process.exit(1);
}
console.log(`[postbuild] OK — ${solutionPages.length} solution pages noindex; no localhost/old base path; no server-side state.`);
