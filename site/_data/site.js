// Site-wide values, all from the environment — nothing hardcoded.
// Vercel system env vars: https://vercel.com/docs/environment-variables/system-environment-variables
const env = process.env;

const withScheme = (host) => (host ? `https://${host.replace(/^https?:\/\//, "").replace(/\/$/, "")}` : "");

// Absolute base URL, used ONLY for sitemap.xml / robots.txt / canonical links.
// Order: explicit SITE_URL → production domain on production builds → this deployment's URL (previews).
// Empty on a plain local build: sitemap is then skipped with a build warning; all page links are root-relative anyway.
const url =
  (env.SITE_URL && env.SITE_URL.replace(/\/$/, "")) ||
  (env.VERCEL_ENV === "production" && withScheme(env.VERCEL_PROJECT_PRODUCTION_URL)) ||
  withScheme(env.VERCEL_URL) ||
  "";

// Where learners fetch lab files (break.sh etc.): the repo and branch this build came from.
const owner = env.VERCEL_GIT_REPO_OWNER || (env.GITHUB_REPOSITORY || "").split("/")[0] || "";
const slug = env.VERCEL_GIT_REPO_SLUG || (env.GITHUB_REPOSITORY || "").split("/")[1] || "";
const ref = env.VERCEL_GIT_COMMIT_REF || env.GITHUB_REF_NAME || "";
const provider = env.VERCEL_GIT_PROVIDER || (env.GITHUB_REPOSITORY ? "github" : "");
const treeUrl = provider === "github" && owner && slug && ref ? `https://github.com/${owner}/${slug}/tree/${ref}` : null;

export default {
  title: "aws-devops-platform course",
  url,
  environment: env.VERCEL_ENV || "local",
  repo: { owner, slug, ref, treeUrl },
};
