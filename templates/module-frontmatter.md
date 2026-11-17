# Module front-matter schema

Every `phases/phase-N/<NN-slug>/module.md` starts with this YAML block, **before** the `# Phase N · Module …` heading. The site reads these values from here and **never** from the module's prose. Rules for the site: see "Front-matter contract" in `/CLAUDE.md`.

The schema has **exactly 12 keys**. Do not add keys without agreeing a schema change first.

```yaml
---
phase: "phase-0"
moduleId: "0.1"
title: "Linux & the shell"
goal: "Read, run, and debug shell commands with confidence."
timeEstimate: "8-10h"
costEstimate: "$0"
costAssumptions: "none"
lastVerified: null
prerequisites: ["0.0"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  bash: "5.2.21"
---
```

## Keys

| Key | Type | Required | Format / rule | Example |
|---|---|---|---|---|
| `phase` | string | **required** | `phase-0` … `phase-3`. Must match the folder the file is in (`phases/<phase>/…`). | `"phase-0"` |
| `moduleId` | string | **required** | `"<phase digit>.<number>"`, **always quoted** (unquoted `0.1` is a YAML number and `0.10` would become `0.1`). The phase digit must match `phase`. Unique across the course. | `"0.1"` |
| `title` | string | **required** | The module title only, without the `Phase N · Module N.N —` prefix. Must match the `#` heading after that prefix. | `"Linux & the shell"` |
| `goal` | string | **required** | One sentence, ending in a full stop. Must match section 1 "Goal" of the module. | `"Read, run, and debug shell commands with confidence."` |
| `timeEstimate` | string | **required** | Hours as a range `"<min>-<max>h"` (ASCII hyphen, no spaces), or a single value `"<n>h"`. Decimals allowed (`"0.5-1h"`). Must match section 3. | `"8-10h"` |
| `costEstimate` | string | **required** | Expected total cost **if the learner follows teardown**, in USD: `"$0"`, `"<$<n>"` (upper bound) or `"~$<n>"` (approximate). Must match section 4 "Total if you follow teardown". | `"<$1"` |
| `costAssumptions` | string | **required** | One line giving the pricing basis: region, pricing model, free-tier assumption, pricing date, and the **if-you-skip-teardown $/day** figure. Use exactly `"none"` **only** when `costEstimate` is `"$0"` and nothing billable is created. | `"us-east-1, on-demand, no free tier, author's prices 2026-11-17 (not yet checked); skip teardown ≈ $0.39/day"` |
| `lastVerified` | date | **required key**, value may be `null` | `YYYY-MM-DD` (unquoted YAML date) = the date a human last ran **every** command in the module. `null` = not yet verified. Never put a drafting date here. Must match section 10. | `2026-12-03` or `null` |
| `prerequisites` | string[] | **required** (may be `[]`) | Module IDs (quoted strings, same format as `moduleId`) that must be complete first. A phase gate is expressed by its gate module's ID (e.g. `"0.6"` = Phase 0 exit gate, `"2.9"` = Phase 2 gate). Never list a later module (no forward references). | `["0.0"]` |
| `hasDebuggingLab` | boolean | **required** | `true` only if section 7 contains a runnable debugging lab with its broken-state setup **and** a solution file under `solutions/`. | `true` |
| `hasTeardown` | boolean | **required** | `true` only if section 9 has teardown commands **and** a confirmation command with expected empty output. A module that creates nothing billable still needs `true` if it creates anything at all (files, containers, repos). | `true` |
| `toolsPinned` | map (string → string) | **required** (may be `{}` only if the module uses no tools) | Tool name → **exact** version string, quoted. No `latest`, no ranges (`~>`, `>=`, `^`), no floating tags (`3.12`, `main`). Image tags and GitHub Actions use their exact pinned value. **One exception**, see below. Must match section 10 "Versions". | `{ awscli: "2.33.14", terraform: "1.17.2", "actions/checkout": "v7" }` |

### Exception: managed platforms versioned only by minor release

Some managed services let you choose only a `MAJOR.MINOR` version; the provider applies patch releases itself and you cannot pin them (example: the Kubernetes version of an Amazon EKS cluster — https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html). For these, and only these:

- the key **must end in `MinorVersion`** (e.g. `eksMinorVersion`), so the exception is visible in the key itself;
- the value is `"MAJOR.MINOR"` (e.g. `"1.36"`);
- section 10 "Last verified" must record the platform/patch version actually observed on the verification run (e.g. `kubectl version` server output).

Any other key with a `MAJOR.MINOR`-only value is a floating pin and fails validation.

## Validation rules the site build applies

- **Missing required key** → build **warning** naming the file and key. The page still builds.
- **Wrong type or format** (e.g. unquoted `moduleId`, `timeEstimate: "8 to 10 hours"`) → build **warning**.
- **`lastVerified: null`** → build **warning** ("not yet verified"); the page shows a visible "Not yet verified by a human" badge.
- **`hasTeardown: false` or `costEstimate`/`costAssumptions` missing** → build **warning**; the page shows a visible "cost/teardown missing" notice instead of the cost callout.
- **`prerequisites` naming an ID with no module** → build **warning** (allowed while modules are being written; never silent).
- **Duplicate `moduleId`**, or `phase`/`moduleId` not matching the folder → build **warning**.

Front-matter values must **agree with** the module's prose sections; the prose stays the human-readable source and the front-matter is its machine-readable summary. A mismatch is a `qa` finding.
