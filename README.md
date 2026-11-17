# AWS DevOps Engineering Course

Static site for the phased aws-devops-platform course, built with Eleventy from `/phases`, `/assessments` and `/solutions`. The original single-page course (`index.html`) is still served at `/legacy/`.

## Deploy on Vercel

1. Push this folder to a GitHub repository (or run `deploy.ps1`).
2. In Vercel: **Add New → Project → Import** the repository.
3. Framework preset: **Other**. Build settings come from `vercel.json` (`npm run build`, output `_site`). Optional env var: `SITE_URL` (production base URL; previews use `VERCEL_URL` automatically).
4. Deploy. Every later `git push` to `main` redeploys automatically.

## Updating the course

Edit module content under `/phases` (with front-matter per `/templates/module-frontmatter.md`), commit and push. Run `npm ci && npm run build` locally to see build warnings.

## Notes

- Learner progress (checklists, completed parts, planner) is stored in each visitor's browser (`localStorage`), not on a server.
- Fonts load from Google Fonts; everything else is in `index.html`.
