// Builds src/data/plugins.json from the plugin guide (both language sections).
// Usage: node scripts/plugins-from-guide.mjs _specs/plugins_guide.md
import { readFileSync, writeFileSync } from 'node:fs';

const src = readFileSync(process.argv[2] ?? '_specs/plugins_guide.md', 'utf8');
const section = (start, end) => src.slice(src.indexOf(start), end ? src.indexOf(end) : undefined);
const ar = section('## النسخة العربية', '## English version');
const en = section('## English version', '## قرارات اتخذتها');

function parse(text) {
  const [head, ...groups] = text.split(/^#### /m);
  const intro = head.split(/^### .*$/m)[1].trim();
  return {
    intro,
    groups: groups.map((g) => {
      const [title, ...rest] = g.split('\n');
      const body = rest.join('\n');
      const lines = body.split('\n');
      const note = lines.filter((l) => l.trim() && !l.startsWith('|') && !l.startsWith('---')).join('\n').trim();
      const rows = lines.filter((l) => /^\| (`[^`]+`|[A-Z])/.test(l) && !/^\| (Plugin|الإضافة) /.test(l))
        .map((l) => l.split('|').slice(1, -1).map((c) => c.trim()));
      return { n: Number(title.match(/^(\d+)\./)[1]), title: title.replace(/^\d+\.\s*/, '').trim(), note, rows };
    }),
  };
}

const A = parse(ar), E = parse(en);
const tail = (t) => (t.match(/\*\*(?:لم تجد|Can't find)[\s\S]*$/) ?? [''])[0].trim();
const strip = (note) => note.replace(/\*\*(?:لم تجد|Can't find)[\s\S]*$/, '').trim();
const groups = A.groups.map((g, i) => {
  const eg = E.groups[i];
  const hasLesson = g.rows[0]?.length === 5;
  return {
    n: g.n,
    title: { ar: g.title, en: eg.title },
    note: { ar: strip(g.note), en: strip(eg.note) },
    items: g.rows.map((r, j) => {
      const e = eg.rows[j];
      const name = r[0].replace(/`/g, '');
      if (name !== e[0].replace(/`/g, '')) throw new Error(`row mismatch in group ${g.n}: ${name} / ${e[0]}`);
      const link = (hasLesson ? r[3] : r[2]).replace('†', '').trim();
      const check = hasLesson ? r[4] : r[3];
      return {
        name,
        bundled: check === 'م',
        standalone: check.includes('*'),
        lessons: hasLesson ? [...r[2].matchAll(/`([a-z0-9-]+)`/g)].map((m) => m[1]) : [],
        url: /^https?:\/\//.test(link) ? link : null,
        text: { ar: r[1], en: e[1] },
      };
    }),
  };
});
const out = { source: 'plugins_guide.md', intro: { ar: A.intro, en: E.intro }, outro: { ar: tail(A.groups.at(-1).note), en: tail(E.groups.at(-1).note) }, groups };
writeFileSync('src/data/plugins.json', JSON.stringify(out, null, 2) + '\n');
console.log(`plugins: ${groups.reduce((a, g) => a + g.items.length, 0)} in ${groups.length} groups`);
