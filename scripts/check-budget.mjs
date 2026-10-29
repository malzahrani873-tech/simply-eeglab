// Page-weight budget and external-resource check on the build output. Exits 1 on any violation.
import { readdir, readFile, stat } from 'node:fs/promises';
import { join, extname, dirname } from 'node:path';
import { gzipSync } from 'node:zlib';

const DIST = process.argv[2] ?? 'dist';
const BASE = (process.env.SITE_BASE ?? '/').replace(/\/?$/, '/');   // '/' on Cloudflare, '/<repo>/' on GitHub Pages
const PAGE_KB = 500, IMG_KB = 200, ICA_IMG_KB = 60, JS_FILE_KB = 10;   // KB, gzip; ICA images and per-file JS are stricter
const IMG_OK = new Set(['.webp', '.svg']);
const EXCEPT = [/^og\//, /^favicon/, /^apple-touch-icon/];   // not loaded by pages (social preview, icons)
// Written exception list: named files only (budget-exceptions.txt, one dist path per line).
import { existsSync, readFileSync } from 'node:fs';
const LISTED = new Set(existsSync('budget-exceptions.txt') ? readFileSync('budget-exceptions.txt', 'utf8').split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#')) : []);
const STRICT_JS = [[/(^|\/)continue-tab[.-]/, 2.5], [/(^|\/)map-links[.-]/, 2.5]];   // site-wide or home-page scripts, KB gzip
const errors = [], rows = [];
const kb = (b) => +(b / 1024).toFixed(1);
const gz = async (f) => gzipSync(await readFile(f), { level: 9 }).length;

async function* walk(d) {
  for (const e of await readdir(d, { withFileTypes: true })) {
    const p = join(d, e.name);
    if (e.isDirectory()) yield* walk(p); else yield p;
  }
}

// 1) Images: format and size
for await (const f of walk(DIST)) {
  const rel = f.slice(DIST.length + 1), ext = extname(f).toLowerCase();
  if (!['.png', '.jpg', '.jpeg', '.gif', '.avif', '.webp', '.svg'].includes(ext)) continue;
  if (EXCEPT.some((r) => r.test(rel)) || LISTED.has(rel)) continue;
  if (!IMG_OK.has(ext)) errors.push(`image format not allowed: ${rel}`);
  const size = (await stat(f)).size;
  const max = rel.startsWith('ica/') ? ICA_IMG_KB : IMG_KB;
  if (size > max * 1024) errors.push(`image over ${max}KB: ${rel} (${kb(size)}KB)`);
}

// 1b) Component JS files (Pagefind excluded), gzip
for await (const f of walk(DIST)) {
  const rel = f.slice(DIST.length + 1);
  if (!f.endsWith('.js') || rel.startsWith('pagefind/')) continue;
  const size = await gz(f);
  const max = STRICT_JS.find(([re]) => re.test(rel))?.[1] ?? JS_FILE_KB;
  if (size > max * 1024) errors.push(`JS file over ${max}KB gzip: ${rel} (${kb(size)}KB)`);
}

// 2) Pages: everything loaded on first view, gzip
const attr = (tag, name) => tag.match(new RegExp(`\\s${name}=(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`, 'i'))?.slice(1).find(Boolean);
for await (const f of walk(DIST)) {
  if (!f.endsWith('.html')) continue;
  const html = await readFile(f, 'utf8');
  let total = await gz(f);
  const seen = new Set(), cssFiles = [];
  for (const [tag] of html.matchAll(/<(script|link|img|iframe)\b[^>]*>/gi)) {
    const t = tag.toLowerCase();
    let url = attr(tag, 'src') ?? (t.startsWith('<link') && /stylesheet|preload|modulepreload/.test(attr(tag, 'rel') ?? '') ? attr(tag, 'href') : null);
    if (!url) continue;
    if (/^(https?:)?\/\//.test(url)) {               // no third-party resources in built HTML
      errors.push(`external resource in ${f.slice(DIST.length)}: ${url}`); continue;
    }
    if (t.startsWith('<img') && attr(tag, 'loading') === 'lazy') continue;   // lazy images are not part of first load
    const clean = url.split(/[?#]/)[0];
    const p = clean.startsWith(BASE) ? join(DIST, clean.slice(BASE.length)) : clean.startsWith('/') ? join(DIST, clean) : join(dirname(f), clean);
    if (seen.has(p)) continue; seen.add(p);
    try { total += /\.(webp|woff2)$/.test(p) ? (await stat(p)).size : await gz(p); }
    catch { errors.push(`missing file ${url} in ${f.slice(DIST.length)}`); continue; }
    if (p.endsWith('.css')) cssFiles.push(p);
  }
  // Fonts declared via @font-face (linked CSS and inline <style>): count all of them as the worst case,
  // since unicode-range means the browser may fetch only some.
  const cssTexts = [...html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/gi)].map((m) => [m[1], f]);
  for (const c of cssFiles) cssTexts.push([await readFile(c, 'utf8'), c]);
  for (const [css, from] of cssTexts) {
    for (const [, u] of css.matchAll(/url\(\s*['"]?([^'")]+\.woff2)['"]?\s*\)/gi)) {
      const fp = u.startsWith(BASE) ? join(DIST, u.slice(BASE.length)) : u.startsWith('/') ? join(DIST, u) : join(dirname(from), u);
      if (seen.has(fp)) continue; seen.add(fp);
      try { total += (await stat(fp)).size; } catch { errors.push(`missing font ${u}`); }
    }
  }
  // Files a page fetches from script on first view (e.g. the daily ICA component): the page declares them
  // with data-budget-include="dir/*.json dir/*.webp", and the largest match of each pattern is counted.
  for (const [, list] of html.matchAll(/data-budget-include="([^"]+)"/g)) {
    for (const pattern of list.trim().split(/\s+/)) {
      const dir = join(DIST, dirname(pattern));
      const re = new RegExp('^' + pattern.split('/').pop().replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*') + '$');
      let max = -1;
      try {
        for (const name of await readdir(dir)) {
          if (!re.test(name)) continue;
          const fp = join(dir, name);
          max = Math.max(max, /\.(webp|woff2)$/.test(name) ? (await stat(fp)).size : await gz(fp));
        }
      } catch {}
      if (max < 0) errors.push(`no file matches ${pattern} (declared in ${f.slice(DIST.length)})`);
      else total += max;
    }
  }
  rows.push([f.slice(DIST.length), kb(total)]);
  if (total > PAGE_KB * 1024) errors.push(`page over ${PAGE_KB}KB: ${f.slice(DIST.length)} (${kb(total)}KB)`);
}

rows.sort((a, b) => b[1] - a[1]).slice(0, 10).forEach(([p, s]) => console.log(`${String(s).padStart(7)} KB  ${p}`));
if (errors.length) { console.error('\nBudget violations:\n- ' + errors.join('\n- ')); process.exit(1); }
console.log(`\nAll ${rows.length} pages within budget.`);
