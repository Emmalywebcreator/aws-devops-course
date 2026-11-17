// robots.txt. Solutions are NOT disallowed here on purpose: a disallowed page is never crawled,
// so its noindex (meta + X-Robots-Tag header) would never be seen. noindex is what keeps them out of search.
export const data = { layout: false, eleventyExcludeFromCollections: true, permalink: "/robots.txt" };

export function render(d) {
  return `User-agent: *\nAllow: /\n${d.site.url ? `Sitemap: ${d.site.url}/sitemap.xml\n` : ""}`;
}
