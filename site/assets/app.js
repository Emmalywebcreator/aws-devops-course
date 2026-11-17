// Course site client script. Learner state lives ONLY in this browser's localStorage.
// No accounts, no server, no API calls. If storage is blocked, everything still renders; progress just isn't saved.
(function () {
  "use strict";
  const KEY = "adp.progress.v1";
  const dataEl = document.getElementById("site-data");
  const site = dataEl ? JSON.parse(dataEl.textContent) : { modules: [], diagnostic: { items: [] } };
  const modules = site.modules || [];
  const diag = site.diagnostic || { items: [] };

  // ---------- storage (never throws) ----------
  const load = () => {
    try {
      const v = JSON.parse(window.localStorage.getItem(KEY) || "null");
      return v && v.version === 1 ? v : { version: 1, diagnostic: null, done: {} };
    } catch (e) { return { version: 1, diagnostic: null, done: {} }; }
  };
  const save = (state) => { try { window.localStorage.setItem(KEY, JSON.stringify(state)); return true; } catch (e) { return false; } };

  const cmp = (a, b) => { const [ap, an] = a.split(".").map(Number); const [bp, bn] = b.split(".").map(Number); return ap - bp || an - bn; };
  const byId = (id) => modules.find((m) => m.id === id && m.inNav);
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  // ---------- placement rule (assessments/gate-rules.md §1.3 and §1.4) ----------
  function place(answers) {
    const qs = diag.items.filter((i) => i.type === "question");
    const ts = diag.items.filter((i) => i.type === "task");
    const score = qs.filter((i) => answers[i.id] === "pass").length;
    const tasksAll = ts.every((i) => answers[i.id] === "pass");
    const failedModules = [...new Set(diag.items.filter((i) => answers[i.id] !== "pass").map((i) => i.module))].sort(cmp);

    if (score >= diag.skipScore && tasksAll) {
      return { score, total: qs.length, tasksAll, start: null, route: "next-phase", path: [], review: failedModules };
    }
    const start = failedModules[0]; // exactly one: lowest-numbered module with a wrong/failed item
    const phase = start.split(".")[0];
    const ids = [...new Set([
      ...diag.items.map((i) => i.module),
      ...modules.filter((m) => m.phase === `phase-${phase}`).map((m) => m.id),
    ])].filter((id) => id.split(".")[0] === phase).sort(cmp);
    const path = ids.filter((id) => cmp(id, start) >= 0).map((id) => {
      const tested = diag.items.some((i) => i.module === id);
      const status = id === start || failedModules.includes(id) || !tested ? "do" : "debug-lab-only";
      return { id, status };
    });
    return { score, total: qs.length, tasksAll, start, route: "module", path, review: [] };
  }

  const describe = (r) => {
    if (!r) return "";
    if (r.route === "next-phase") {
      return `<p class="callout-title">Skip Phase 0 — start Phase 1.</p><p>Score ${r.score}/${r.total}, all tasks passed.` +
        (r.review.length ? ` Before Phase 1, read the Concepts of: ${r.review.map(esc).join(", ")}.` : "") + `</p>`;
    }
    const m = byId(r.start);
    const startLink = m ? `<a href="${esc(m.url)}">${esc(m.id)} ${esc(m.title)}</a>` : `${esc(r.start)} <span class="muted">(not published yet)</span>`;
    const rows = r.path.map((p) => {
      const mm = byId(p.id);
      const name = mm ? `<a href="${esc(mm.url)}">${esc(p.id)} ${esc(mm.title)}</a>` : `${esc(p.id)} <span class="muted">(not published yet)</span>`;
      return `<li>${name} — ${p.status === "do" ? "do the whole module" : "debugging lab only"}</li>`;
    }).join("");
    return `<p class="callout-title">Start at module ${startLink}</p><p>Score ${r.score}/${r.total}; tasks ${r.tasksAll ? "all passed" : "not all passed"}.</p>` +
      `<p>Your path (then the Phase 0 capstone and exit gate — see <a href="${esc(diag.gateRulesUrl)}">gate rules</a>):</p><ol>${rows}</ol>`;
  };

  // ---------- sidebar: path summary + per-module status ----------
  function renderNav(state) {
    const r = state.diagnostic && state.diagnostic.result;
    const statusOf = {};
    if (r) for (const p of r.path) statusOf[p.id] = p.status;
    document.querySelectorAll("[data-module-id]").forEach((li) => {
      const id = li.getAttribute("data-module-id");
      const s = li.querySelector(".status");
      li.classList.remove("is-done", "is-todo", "is-lab");
      let label = "";
      if (state.done[id]) { li.classList.add("is-done"); label = "done"; }
      else if (statusOf[id] === "do") { li.classList.add("is-todo"); label = "to do"; }
      else if (statusOf[id] === "debug-lab-only") { li.classList.add("is-lab"); label = "lab only"; }
      if (s) s.textContent = label;
    });
    const mini = document.getElementById("your-path-mini");
    if (mini) {
      if (r) {
        const m = r.start && byId(r.start);
        mini.innerHTML = r.route === "next-phase"
          ? "Your result: <strong>start Phase 1</strong>"
          : `Your start: <strong>${m ? `<a href="${esc(m.url)}">${esc(r.start)}</a>` : esc(r.start)}</strong>`;
        mini.hidden = false;
      } else { mini.hidden = true; }
    }
  }

  // ---------- module page: mark complete ----------
  function wireDone(state) {
    document.querySelectorAll("[data-mark-done]").forEach((btn) => {
      const id = btn.getAttribute("data-mark-done");
      const paint = () => { btn.textContent = state.done[id] ? `Module ${id} complete ✓ (undo)` : `Mark module ${id} complete`; };
      paint();
      btn.addEventListener("click", () => {
        if (state.done[id]) delete state.done[id]; else state.done[id] = true;
        if (!save(state)) btn.insertAdjacentHTML("afterend", ' <span class="small muted">(Couldn\'t save — browser storage is blocked.)</span>');
        paint(); renderNav(state);
      });
    });
  }

  // ---------- entry diagnostic page ----------
  function wireDiagnostic(state) {
    const app = document.getElementById("diagnostic-app");
    if (!app) return;
    const ready = document.getElementById("diag-ready");
    const keyP = document.getElementById("diag-key");
    const form = document.getElementById("diag-form");
    const out = document.getElementById("diag-result");
    const show = (r) => { out.innerHTML = describe(r); out.hidden = !r; };

    ready.addEventListener("change", () => { keyP.hidden = !ready.checked; form.hidden = !ready.checked; });

    if (state.diagnostic) {
      const a = state.diagnostic.answers || {};
      for (const [k, v] of Object.entries(a)) { const el = form.querySelector(`input[name="${CSS.escape(k)}"][value="${v}"]`); if (el) el.checked = true; }
      ready.checked = true; keyP.hidden = false; form.hidden = false;
      show(state.diagnostic.result);
    }

    form.addEventListener("submit", (ev) => {
      ev.preventDefault();
      const answers = {};
      for (const it of diag.items) {
        const el = form.querySelector(`input[name="${CSS.escape(it.id)}"]:checked`);
        answers[it.id] = el ? el.value : "fail"; // unanswered counts as wrong/failed (gate-rules §1.1)
      }
      const result = place(answers);
      state.diagnostic = { answers, result, takenAt: new Date().toISOString() };
      const ok = save(state);
      show(result);
      if (!ok) out.insertAdjacentHTML("beforeend", '<p class="small">Your browser blocked storage, so this result won\'t be remembered.</p>');
      renderNav(state);
      out.scrollIntoView({ behavior: "smooth", block: "nearest" });
    });

    document.getElementById("diag-reset").addEventListener("click", () => {
      state.diagnostic = null; save(state); form.reset(); show(null); renderNav(state);
    });
  }

  // ---------- home page path panel ----------
  function renderHome(state) {
    const el = document.getElementById("your-path");
    if (!el) return;
    if (state.diagnostic && state.diagnostic.result) { el.innerHTML = describe(state.diagnostic.result); el.hidden = false; }
  }

  window.adpPlace = place; // exposed for tests
  const state = load();
  renderNav(state);
  wireDone(state);
  wireDiagnostic(state);
  renderHome(state);
})();
