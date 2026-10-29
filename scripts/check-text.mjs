// Fails when a lesson component tag or its name leaks into the text a reader sees or prints,
// e.g. "<UiLabel>Max window</UiLabel>" shown literally on a reference card.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const root = process.argv[2] ?? 'dist';
const TAGS = 'UiLabel|MenuPath|En|Kbd|Callout|ImageSpec|Figure|Methods|BeforeAfter|YouTube|LessonComplete|IcaGameTeaser|FilterDemo|RerefDemo|EpochRejectDemo';
const LEAK = new RegExp(`&lt;\\/?(?:${TAGS})\\b|<\\/?(?:${TAGS})\\b|\\buiLabel\\b`);
const pages = [];
const walk = (d) => { for (const f of readdirSync(d)) { const p = join(d, f); if (statSync(p).isDirectory()) walk(p); else if (p.endsWith('.html')) pages.push(p); } };
walk(root);
const bad = [];
for (const p of pages) {
  if (/[\\/]dev[\\/]/.test(p)) continue;
  const html = readFileSync(p, 'utf8').replace(/<script\b[\s\S]*?<\/script>|<style\b[\s\S]*?<\/style>/g, '');
  const m = html.match(LEAK);
  if (m) bad.push(`${p}: …${html.slice(Math.max(0, m.index - 40), m.index + 60).replace(/\s+/g, ' ')}…`);
}
if (bad.length) { console.error(`component tags in visible text (${bad.length} pages):\n  ` + bad.slice(0, 20).join('\n  ')); process.exit(1); }
console.log(`visible text: no component tags in ${pages.length} pages`);
