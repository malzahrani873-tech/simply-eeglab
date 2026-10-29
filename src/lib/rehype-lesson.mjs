// Shapes a lesson body: the first section is the idea (heading visually hidden), sections with a drawing or a
// simulation stay open, the others fold into <details> (each followed by a print-only copy), code blocks get a
// copy button, and the completion button plus the Methods box close the lesson.
import { readFileSync } from 'node:fs';
import { iconPath } from './icons.mjs';
import { sectionsOfMarkdown, legacyTitle } from './lesson-sections.mjs';

const INTERACTIVE = new Set(['FilterDemo', 'RerefDemo', 'EpochRejectDemo', 'YouTube', 'BeforeAfter']);

const copy = {};
for (const lang of ['ar', 'en']) {
  const base = JSON.parse(readFileSync(`src/i18n/${lang}.json`, 'utf8'));
  const extra = JSON.parse(readFileSync('src/i18n/pending.json', 'utf8'))[lang];
  copy[lang] = { ...extra, ...base };
}
// Counted hints use the plural form of the language ("<key>.one", ".two", ".few", ".many"), else the base key.
const t = (lang, k, n) => {
  const form = n === undefined ? 'other' : new Intl.PluralRules(lang).select(n);
  const key = form !== 'other' && `${k}.${form}` in copy[lang] ? `${k}.${form}` : k;
  return (copy[lang][key] ?? '').replace('{n}', String(n));
};
export const icon = (name, cls = 'ico') => ({
  type: 'element',
  tagName: 'svg',
  properties: { className: cls.split(' '), viewBox: '0 0 256 256', fill: 'currentColor', ariaHidden: 'true', focusable: 'false' },
  children: [{ type: 'element', tagName: 'path', properties: { d: iconPath(name) }, children: [] }],
});
const el = (tagName, properties, children = []) => ({ type: 'element', tagName, properties, children });
const text = (value) => ({ type: 'text', value });
const textOf = (n) => (n.type === 'text' ? n.value : (n.children ?? []).map(textOf).join(''));
const isEl = (n, tag) => n.type === 'element' && n.tagName === tag;
const isJsx = (name) => (n) => (n.type === 'mdxJsxFlowElement' || n.type === 'mdxJsxTextElement') && n.name === name;

function walk(n, fn, parent = null) {
  fn(n, parent);
  for (const c of [...(n.children ?? [])]) walk(c, fn, n);
}

// A copy for print: no ids, no buttons, interactive parts replaced by their static note.
function printClone(n, lang) {
  if (n.type === 'element') {
    if (n.tagName === 'button') return null;
    const props = { ...n.properties };
    delete props.id;
    const kids = (n.children ?? []).map((c) => printClone(c, lang)).filter(Boolean);
    return { ...n, properties: props, children: kids };
  }
  if ((n.type === 'mdxJsxFlowElement' || n.type === 'mdxJsxTextElement') && INTERACTIVE.has(n.name)) {
    return el('p', { className: ['muted'] }, [text(copy[lang]['interactive.noJs'])]);
  }
  if (n.children) return { ...n, children: n.children.map((c) => printClone(c, lang)).filter(Boolean) };
  return { ...n };
}

export function fold(id, iconName, heading, hint, body, extraClass, lang) {
  const summary = el('summary', {}, [
    icon(iconName, 'ico fi'),
    el('span', { className: ['ft'] }, [heading, ...(hint ? [el('span', { className: ['fh'] }, [text(hint)])] : [])]),
    icon('down', 'ico s20 cv2'),
  ]);
  const details = el('details', { id, className: ['fold', ...(extraClass ? [extraClass] : [])] }, [summary, el('div', { className: ['fb'] }, body)]);
  const print = el('div', { className: ['print-copy'], dataPagefindIgnore: '' }, [printClone(heading, lang), ...body.map((b) => printClone(b, lang)).filter(Boolean)]);
  return [details, print];
}

function inlineFold(label, body, lang) {
  const details = el('details', { className: ['inline-fold'] }, [
    el('summary', {}, [el('span', {}, [text(label)]), icon('down', 'ico s20 cv2')]),
    el('div', {}, body),
  ]);
  const print = el('div', { className: ['print-copy'], dataPagefindIgnore: '' }, [el('p', {}, [el('strong', {}, [text(label)])]), ...body.map((b) => printClone(b, lang))]);
  return [details, print];
}

// MATLAB blocks get a small header with the language name and a copy button (shown by script).
function wrapCode(tree, lang) {
  walk(tree, (n, parent) => {
    if (!parent || !isEl(n, 'pre') || parent.properties?.className?.includes?.('code')) return;
    const i = parent.children.indexOf(n);
    const head = el('div', { className: ['ch2'] }, [
      el('span', {}, [text(copy[lang]['code.lang'])]),
      el('button', { type: 'button', className: ['cp'], hidden: true, dataCopy: '', dataDone: copy[lang]['code.copied'], dataFail: copy[lang]['code.copyFailed'] }, [
        icon('copy', 'ico s20'),
        el('span', {}, [text(copy[lang]['code.copy'])]),
      ]),
    ]);
    n.properties = { ...n.properties, dir: 'ltr', tabIndex: 0 };
    parent.children[i] = el('div', { className: ['code'] }, [head, n]);
  });
}

// Tables get the site style; on phones each row of a large table stacks, and every cell shows its column name (data-h).
function styleTables(tree) {
  walk(tree, (n) => {
    if (!isEl(n, 'table')) return;
    const rows = [];
    walk(n, (r) => { if (isEl(r, 'tr')) rows.push(r); });
    // A small table (up to 3 short columns) stays a table on phones; others stack row by row.
    const cells = rows.flatMap((r) => r.children.filter((c) => isEl(c, 'td') || isEl(c, 'th')));
    const cols = Math.max(0, ...rows.map((r) => r.children.filter((c) => isEl(c, 'td') || isEl(c, 'th')).length));
    const compact = cols <= 3 && cells.every((c) => textOf(c).trim().length <= 80);
    n.properties = { ...n.properties, className: [...(n.properties?.className ?? []), 'tbl', ...(compact ? ['compact'] : [])] };
    const head = rows.find((r) => r.children.some((c) => isEl(c, 'th')));
    const names = head ? head.children.filter((c) => isEl(c, 'th')).map((c) => textOf(c).trim()) : [];
    for (const r of rows) {
      r.children.filter((c) => isEl(c, 'td')).forEach((c, i) => { if (names[i]) c.properties = { ...c.properties, dataH: names[i] }; });
    }
  });
}

// Arabic lessons: each Latin run in running text is isolated, so "الـ high-pass" and "(L1، الفصل 4)" keep their order.
const RUN = /[A-Za-z0-9_.][A-Za-z0-9 ._\-/+&]*[A-Za-z0-9_]|[A-Za-z]/g;
const SKIP_ISO = new Set(['code', 'pre', 'bdi', 'script', 'style', 'svg', 'kbd', 'samp']);
function isolateLatin(n) {
  if (n.type !== 'element' && n.type !== 'root' && !n.type?.startsWith('mdxJsx')) return;
  if (n.type === 'element' && (SKIP_ISO.has(n.tagName) || n.properties?.lang === 'en' || n.properties?.dir === 'ltr')) return;
  if (n.type?.startsWith('mdxJsx') && !['Callout', 'BeforeAfter'].includes(n.name)) return;
  const out = [];
  for (const c of n.children ?? []) {
    if (c.type !== 'text') { isolateLatin(c); out.push(c); continue; }
    let last = 0;
    for (const m of c.value.matchAll(RUN)) {
      if (!/[A-Za-z]/.test(m[0])) continue;
      if (m.index > last) out.push(text(c.value.slice(last, m.index)));
      const nw = !/\s/.test(m[0]) && m[0].length <= 24;
      out.push(el('bdi', nw ? { lang: 'en', className: ['nw'] } : { lang: 'en' }, [text(m[0])]));
      last = m.index + m[0].length;
    }
    if (last === 0) out.push(c);
    else if (last < c.value.length) out.push(text(c.value.slice(last)));
  }
  n.children = out;
}

const DEMOS = new Set(['FilterDemo', 'RerefDemo', 'EpochRejectDemo', 'BeforeAfter', 'Figure', 'ImageSpec', 'IcaGameTeaser', 'YouTube']);
const FOLD_ICON = { topic: 'book', gui: 'steps', script: 'code', values: 'list', verify: 'check', mistakes: 'warn' };
const countItems = (body) => body.filter((n) => isEl(n, 'ol') || isEl(n, 'ul')).reduce((a, l) => a + l.children.filter((c) => isEl(c, 'li')).length, 0);
const isDemo = (n) => (n.type === 'mdxJsxFlowElement' && DEMOS.has(n.name)) || (isEl(n, 'p') && n.children.some((c) => c.type === 'mdxJsxTextElement' && DEMOS.has(c.name)));
const hasContent = (body) => body.some((n) => n.type !== 'text' || n.value.trim());

// The small line under a folded title: a count where one helps the student decide to open it.
function hintFor(kind, body, lang) {
  let n = 0;
  if (kind === 'script') {
    let pre = null;
    walk({ children: body }, (x) => { if (!pre && isEl(x, 'pre')) pre = x; });
    n = pre ? textOf(pre).split('\n').filter((l) => l.trim()).length : 0;
  } else if (kind === 'mistakes') {
    const h3s = body.filter((x) => isEl(x, 'h3')).length;
    for (const ul of body.filter((x) => isEl(x, 'ul') || isEl(x, 'ol'))) ul.properties = { ...ul.properties, className: ['mlist'] };
    n = h3s || countItems(body);
  } else if (kind === 'gui' || kind === 'verify') n = countItems(body);
  return n ? t(lang, `fold.${kind}.hint`, n) : '';
}

export default function rehypeLesson() {
  return (tree, file) => {
    const path = (file.path ?? file.history?.[0] ?? '').replace(/\\/g, '/');
    const m = path.match(/content\/lessons\/(ar|en)\/\d\d-\d\d-([a-z0-9-]+)\.mdx$/);
    if (!m) return;
    const [, lang, slug] = m;
    wrapCode(tree, lang);
    styleTables(tree);
    if (lang === 'ar') isolateLatin(tree);

    // Split the top level into chunks that start at each H2; the source says what each section is.
    const chunks = [{ h2: null, body: [] }];
    for (const node of tree.children) {
      if (isEl(node, 'h2')) chunks.push({ h2: node, body: [] });
      else chunks.at(-1).body.push(node);
    }
    const src = String(file.value ?? '').replace(/^---\n[\s\S]*?\n---\n/, '');
    const kinds = sectionsOfMarkdown(src).map((s) => s.kind);
    if (kinds.length !== chunks.length - 1) file.message(`found ${chunks.length - 1} sections, the source has ${kinds.length}`);

    // The Methods box sits after the completion button, folded, whatever its place in the source.
    const methods = [];
    for (const c of chunks) c.body = c.body.filter((n) => (isJsx('Methods')(n) ? (methods.push(n), false) : true));
    const out = [...chunks[0].body];
    const [first, ...rest] = chunks.slice(1);

    // 1. The idea: the first section, open, under a heading only screen readers hear.
    if (first) out.push(el('h2', { id: 'idea', className: ['sr'] }, [text(copy[lang]['section.idea.sr'])]), ...first.body);

    // 2. An explanation with a drawing or a simulation stays open; every other section is a question that folds
    //    (steps, script, checks and mistakes fold even when they hold a demo).
    const used = new Set();
    let lead = false;
    rest.forEach((c, i) => {
      const kind = kinds[i + 1] ?? 'topic';
      if (!hasContent(c.body)) return;
      const id = kind !== 'topic' && !used.has(kind) ? kind : `s${i + 2}`;
      used.add(kind);
      const old = legacyTitle(textOf(c.h2));
      const title = old && old.kind !== 'before-after' && old.kind !== 'why' ? copy[lang][`fold.${old.kind}.title`] : textOf(c.h2).trim();
      if ((kind === 'topic' || kind === 'values') && c.body.some(isDemo)) {
        out.push(el('h2', { id }, [text(title)]), ...foldSimulationNotes(c.body, lang));
        return;
      }
      if (!lead) {
        lead = true;
        out.push(el('div', { className: ['fold-lead'] }, [
          el('p', {}, [text(copy[lang]['fold.lead'])]),
          el('button', { type: 'button', className: ['btn', 'small', 'sec'], hidden: true, dataOpenAll: '', dataOpen: copy[lang]['fold.openAll'], dataClose: copy[lang]['fold.closeAll'] }, [text(copy[lang]['fold.openAll'])]),
        ]));
      }
      out.push(...fold(id, FOLD_ICON[kind], el('h2', {}, [text(title)]), hintFor(kind, c.body, lang), c.body, kind === 'mistakes' ? 'mist' : '', lang));
    });

    // 3. The completion button (its reminder links only to sections this lesson has), then Methods.
    out.push({ type: 'mdxJsxFlowElement', name: 'LessonComplete', attributes: [
      { type: 'mdxJsxAttribute', name: 'slug', value: slug },
      ...['gui', 'verify'].filter((k) => used.has(k)).map((k) => ({ type: 'mdxJsxAttribute', name: k, value: null })),
    ], children: [] });
    if (methods.length) out.push(...fold('methods', 'file', el('h2', {}, [text(copy[lang]['fold.methods.title'])]), t(lang, 'fold.methods.hint'), methods, 'methods', lang));
    tree.children = out;
  };
}

// After a simulation, paragraphs that start with "Simplifications" or "Also notice" fold into one toggle.
const NOTE_START = /^(تبسيطات في المحاكاة|ولاحظ|Simplifications in the simulation|Simplifications|Also notice|Notice also)/;
function foldSimulationNotes(body, lang) {
  const idx = body.findIndex((n) => isEl(n, 'p') && NOTE_START.test(textOf(n).trim()));
  if (idx < 0) return body;
  let end = idx;
  while (end + 1 < body.length && (body[end + 1].type === 'text' || (isEl(body[end + 1], 'p') && NOTE_START.test(textOf(body[end + 1]).trim())))) end++;
  const notes = body.slice(idx, end + 1).filter((n) => n.type !== 'text');
  return [...body.slice(0, idx), ...inlineFold(copy[lang]['fold.demo.notes'], notes, lang), ...body.slice(end + 1)];
}
