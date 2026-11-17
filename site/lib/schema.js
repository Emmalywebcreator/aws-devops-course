// Front-matter schema from /templates/module-frontmatter.md (12 keys).
// This is the *schema* (key names + format rules), not module metadata:
// every value the site shows comes from each module's own front-matter.

const isStr = (v) => typeof v === "string" && v.trim().length > 0;

export const REQUIRED_KEYS = [
  "phase", "moduleId", "title", "goal", "timeEstimate", "costEstimate",
  "costAssumptions", "lastVerified", "prerequisites", "hasDebuggingLab",
  "hasTeardown", "toolsPinned",
];

const FORBIDDEN_VERSION = /(latest|~>|>=|<=|\^|\*|^main$|^master$)/i;
// MAJOR.MINOR-only values are floating pins, except for keys ending in "MinorVersion"
// (documented exception in templates/module-frontmatter.md).
const MINOR_ONLY = /^v?\d+\.\d+$/;

export const RULES = {
  phase: (v) => (isStr(v) && /^phase-[0-3]$/.test(v)) || 'must be "phase-0" … "phase-3"',
  moduleId: (v) => (isStr(v) && /^[0-3]\.\d+$/.test(v)) || 'must be a quoted string like "0.1"',
  title: (v) => isStr(v) || "must be a non-empty string",
  goal: (v) => (isStr(v) && /\.$/.test(v.trim())) || "must be one sentence ending in a full stop",
  timeEstimate: (v) => (isStr(v) && /^\d+(\.\d+)?(-\d+(\.\d+)?)?h$/.test(v)) || 'must look like "8-10h" or "3h"',
  costEstimate: (v) => (isStr(v) && /^(\$0|<\$\d+(\.\d+)?|~\$\d+(\.\d+)?)$/.test(v)) || 'must be "$0", "<$N" or "~$N"',
  costAssumptions: (v) => isStr(v) || 'must be a string (or "none" when costEstimate is "$0")',
  lastVerified: (v) =>
    v === null || v instanceof Date || (isStr(v) && /^\d{4}-\d{2}-\d{2}$/.test(v)) || "must be YYYY-MM-DD or null",
  prerequisites: (v) =>
    (Array.isArray(v) && v.every((x) => isStr(x) && /^[0-3]\.\d+$/.test(x))) || 'must be a list of quoted module IDs, e.g. ["0.0"]',
  hasDebuggingLab: (v) => typeof v === "boolean" || "must be true or false",
  hasTeardown: (v) => typeof v === "boolean" || "must be true or false",
  toolsPinned: (v) => {
    if (v === null || typeof v !== "object" || Array.isArray(v)) return "must be a map of tool → version";
    const bad = Object.entries(v).filter(([k, ver]) =>
      !isStr(ver) || FORBIDDEN_VERSION.test(ver) || (MINOR_ONLY.test(ver) && !k.endsWith("MinorVersion")));
    return bad.length === 0 || `unpinned or non-string versions: ${bad.map(([k]) => k).join(", ")}`;
  },
};

// Returns { problems: [string], fm: object } for one module's data.
export function validate(data) {
  const problems = [];
  for (const key of REQUIRED_KEYS) {
    if (!(key in data)) { problems.push(`missing required key "${key}"`); continue; }
    const ok = RULES[key](data[key]);
    if (ok !== true) problems.push(`"${key}" ${ok}`);
  }
  if (data.costAssumptions === "none" && data.costEstimate && data.costEstimate !== "$0") {
    problems.push('"costAssumptions" is "none" but "costEstimate" is not "$0"');
  }
  return problems;
}

export const hasCostAndTeardown = (d) =>
  RULES.costEstimate(d.costEstimate) === true &&
  RULES.costAssumptions(d.costAssumptions) === true &&
  d.hasTeardown === true;

export const compareIds = (a, b) => {
  const [ap, an] = String(a).split(".").map(Number);
  const [bp, bn] = String(b).split(".").map(Number);
  return ap - bp || an - bn;
};

export const formatDate = (v) => {
  if (v instanceof Date) return v.toISOString().slice(0, 10);
  return typeof v === "string" ? v : null;
};
