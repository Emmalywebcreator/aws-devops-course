// /modules.json — machine-readable module manifest built from front-matter (for tooling and debugging).
export const data = { layout: false, eleventyExcludeFromCollections: true, permalink: "/modules.json" };

export function render(d) {
  return JSON.stringify(d.collections.modules || [], null, 2);
}
