// sitemap.xml: home, assessments and nav-listed modules only. Never solutions.
// Needs an absolute base URL (site.url, from env); without one, it is skipped and the build warns.
export const data = {
  layout: false,
  eleventyExcludeFromCollections: true,
  permalink: (d) => (d.site.url ? "/sitemap.xml" : false),
};

export function render(d) {
  const urls = [
    "/",
    ...(d.collections.assessments || []).map((p) => p.url),
    ...(d.collections.modules || []).filter((m) => m.inNav).map((m) => m.url),
  ].filter((u) => !/(^|\/)solutions\//.test(u));
  const body = urls.map((u) => `  <url><loc>${d.site.url}${u}</loc></url>`).join("\n");
  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${body}\n</urlset>\n`;
}
