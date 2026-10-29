// Converts the glossary tables in the style guide into src/data/glossary.json.
// Run when the style guide changes: node scripts/glossary-from-style-guide.mjs <style_guide.md> <out.json>
import { readFile, writeFile } from 'node:fs/promises';

const HEADER = '| id | English | العربي | صيغ أخرى | القرار | تعريف عربي | English definition | ملاحظة |';
const [, , src, out] = process.argv;
const lines = (await readFile(src, 'utf8')).split('\n');

const terms = [];
const errors = [];
let section = null;
let inTable = false;

for (const [i, line] of lines.entries()) {
  const h = line.match(/^### (3\.[1-9]\d*)\b/);
  if (h) { section = h[1]; inTable = false; continue; }
  if (/^##? /.test(line)) { section = null; inTable = false; continue; }
  if (!section) continue;
  if (line.trim() === HEADER) { inTable = true; continue; }
  if (!inTable) continue;
  if (/^\|\s*-/.test(line)) continue;
  if (!line.startsWith('|')) { inTable = false; continue; }

  const cells = line.slice(1, line.lastIndexOf('|')).split('|').map((c) => c.trim());
  if (cells.length !== 8) { errors.push(`line ${i + 1}: expected 8 cells, got ${cells.length}`); continue; }
  const [id, en, ar, other, decision, defAr, defEn] = cells;
  const term = {
    id: id.replace(/`/g, ''),
    en,
    ar,
    variants: other === '—' ? [] : other.split('،').map((s) => s.trim()).filter(Boolean),
    decision,
    def: { ar: defAr, en: defEn },
  };
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(term.id)) errors.push(`line ${i + 1}: bad id "${term.id}"`);
  if (!['ع', 'إ', 'ع+إ'].includes(decision)) errors.push(`line ${i + 1}: bad decision "${decision}"`);
  for (const [k, v] of Object.entries({ en, ar, defAr, defEn })) if (!v || v === '—') errors.push(`line ${i + 1}: empty ${k}`);
  terms.push(term);
}

const seen = new Set();
for (const t of terms) { if (seen.has(t.id)) errors.push(`duplicate id ${t.id}`); seen.add(t.id); }

if (errors.length) { console.error(errors.join('\n')); process.exit(1); }
await writeFile(out, JSON.stringify(terms, null, 2) + '\n');
console.log(`${terms.length} terms written to ${out}`);
