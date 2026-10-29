// Every page is reachable from the home page in three clicks or fewer, and none is orphaned.
// Links inside the "More" sheet cost two clicks (open the sheet, then the link).
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const DIST = process.argv[2] ?? 'dist';
const MAX = 3;
const SKIP = /^\/(en\/)?(404(\.html)?|map\/|dev\/.*)$/; // error pages, the old map address, preview-only pages

const walk = (dir) => readdirSync(dir).flatMap((n) => {
  const p = join(dir, n);
  return statSync(p).isDirectory() ? walk(p) : p.endsWith('.html') ? [p] : [];
});
const route = (file) => '/' + relative(DIST, file).replace(/\\/g, '/').replace(/index\.html$/, '');
const pages = new Map(walk(DIST).map((f) => [route(f), f]));

const edges = new Map();
for (const [r, f] of pages) {
  const html = readFileSync(f, 'utf8');
  const sheetAt = html.indexOf('id="more-sheet"');
  const sheetEnd = sheetAt < 0 ? -1 : html.indexOf('data-backnote', sheetAt); // the sheet is followed by the back-button note
  const out = new Map();
  for (const m of html.matchAll(/<a\b[^>]*\bhref="([^"#?]*)[^"]*"/g)) {
    let href = m[1];
    if (!href || /^[a-z]+:/i.test(href) || href.startsWith('//')) continue;
    href = new URL(href, 'http://x' + r).pathname;
    if (!pages.has(href)) continue;
    const cost = sheetAt >= 0 && m.index > sheetAt && m.index < sheetEnd ? 2 : 1;
    out.set(href, Math.min(out.get(href) ?? Infinity, cost));
  }
  edges.set(r, out);
}

// Shortest click counts from the home page (costs are 1 or 2, so a small Dijkstra is enough).
const dist = new Map([['/', 0]]);
const queue = ['/'];
while (queue.length) {
  queue.sort((a, b) => dist.get(a) - dist.get(b));
  const r = queue.shift();
  for (const [to, c] of edges.get(r) ?? []) {
    const d = dist.get(r) + c;
    if (d < (dist.get(to) ?? Infinity)) { dist.set(to, d); queue.push(to); }
  }
}

let bad = 0;
const hist = {};
for (const r of pages.keys()) {
  if (SKIP.test(r)) continue;
  const d = dist.get(r);
  if (d === undefined) { bad++; console.log(`orphan: ${r}`); continue; }
  hist[d] = (hist[d] ?? 0) + 1;
  if (d > MAX) { bad++; console.log(`${d} clicks: ${r}`); }
}
console.log(`click depth: ${Object.entries(hist).map(([d, n]) => `${n} page(s) at ${d}`).join(', ')}`);
if (bad) process.exit(1);
