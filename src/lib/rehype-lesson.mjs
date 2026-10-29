// Shapes a lesson body into the fixed template: stable section ids, the first heading visually hidden,
// secondary sections folded into <details> (each followed by a print-only copy), code blocks with a
// copy button, and the completion button plus the Methods box right after "verify".
import { readFileSync } from 'node:fs';
import { iconPath } from './icons.mjs';
import { LESSON_LAYOUT } from '../lesson-layout.mjs';

const SECTIONS = ['why', 'before-after', 'gui', 'script', 'values', 'mistakes', 'verify'];
const FOLDED = { script: 'code', values: 'list', mistakes: 'warn' };
const INTERACTIVE = new Set(['FilterDemo', 'RerefDemo', 'EpochRejectDemo', 'YouTube', 'BeforeAfter']);

const copy = {};
for (const lang of ['ar', 'en']) {
  const base = JSON.parse(readFileSync(`src/i18n/${lang}.json`, 'utf8'));
  const extra = JSON.parse(readFileSync('src/i18n/pending.json', 'utf8'))[lang];
  copy[lang] = { ...extra, ...base };
}
const t = (lang, k, n) => (copy[lang][k] ?? '').replace('{n}', String(n));
// H2 titles the template knows, per section, in both languages (lessons use these headings).
const KNOWN_TITLES = Object.fromEntries(SECTIONS.map((id) => {
  const key = { why: 'why', 'before-after': 'beforeAfter', gui: 'gui', script: 'script', values: 'values', mistakes: 'mistakes', verify: 'verify' }[id];
  return [id, [copy.ar[`section.${key}`], copy.en[`section.${key}`]]];
}));

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

// Tables get the site style; on phones each row stacks, and every cell shows its column name (data-h).
function styleTables(tree) {
  walk(tree, (n) => {
    if (!isEl(n, 'table')) return;
    n.properties = { ...n.properties, className: [...(n.properties?.className ?? []), 'tbl'] };
    const rows = [];
    walk(n, (r) => { if (isEl(r, 'tr')) rows.push(r); });
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
const FOLD_ICON = { why: 'idea', gui: 'steps', script: 'code', values: 'list', verify: 'check', mistakes: 'warn' };
const countItems = (body) => body.filter((n) => isEl(n, 'ol') || isEl(n, 'ul')).reduce((a, l) => a + l.children.filter((c) => isEl(c, 'li')).length, 0);

function hintFor(id, body, lang) {
  let n = 0;
  if (id === 'script') {
    let pre = null;
    walk({ children: body }, (x) => { if (!pre && isEl(x, 'pre')) pre = x; });
    n = pre ? textOf(pre).split('\n').filter((l) => l.trim()).length : 0;
  } else if (id === 'mistakes') {
    const h3s = body.filter((x) => isEl(x, 'h3')).length;
    for (const ul of body.filter((x) => isEl(x, 'ul') || isEl(x, 'ol'))) ul.properties = { ...ul.properties, className: ['mlist'] };
    n = h3s || countItems(body);
  } else if (id === 'gui' || id === 'verify') n = countItems(body);
  else return t(lang, `fold.${id}.hint`, 0);
  return n ? t(lang, `fold.${id}.hint`, n) : '';
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

    // Split the top level into chunks that start at each H2.
    const chunks = [{ h2: null, body: [] }];
    for (const node of tree.children) {
      if (isEl(node, 'h2')) chunks.push({ h2: node, body: [] });
      else chunks.at(-1).body.push(node);
    }
    if (chunks.length - 1 !== SECTIONS.length) file.message(`expected ${SECTIONS.length} sections, found ${chunks.length - 1}`);

    // The Methods box sits after the completion button, folded, whatever its place in the source.
    const methods = [];
    for (const c of chunks) c.body = c.body.filter((n) => (isJsx('Methods')(n) ? (methods.push(n), false) : true));
    const sec = {};
    chunks.slice(1).forEach((c, i) => {
      const id = SECTIONS[i] ?? `section-${i + 1}`;
      const known = KNOWN_TITLES[id];
      if (known && !known.includes(textOf(c.h2).trim())) file.message(`section "${textOf(c.h2).trim()}" has an unknown title`);
      sec[id] = c;
    });
    const out = [...chunks[0].body];
    const tail = () => {
      out.push({ type: 'mdxJsxFlowElement', name: 'LessonComplete', attributes: [{ type: 'mdxJsxAttribute', name: 'slug', value: slug }], children: [] });
      if (methods.length) {
        const title = LESSON_LAYOUT === 'questions' ? copy[lang]['fold.methods.title'] : copy[lang]['methods.title'];
        out.push(...fold('methods', 'file', el('h2', {}, [text(title)]), t(lang, 'fold.methods.hint'), methods, 'methods', lang));
      }
    };

    if (LESSON_LAYOUT === 'questions') {
      // 1. The idea in brief: the first paragraphs of "why", up to about 60 words (at least one).
      const why = sec.why?.body ?? [];
      let words = 0, cut = 0;
      for (let i = 0; i < why.length; i++) {
        const n = why[i];
        if (n.type === 'text') continue;
        if (!isEl(n, 'p')) break;
        const w = textOf(n).trim().split(/\s+/).length;
        if (cut > 0 && words + w > 60) break;
        words += w; cut = i + 1;
      }
      out.push(el('h2', { id: 'idea', className: ['sr'] }, [text(copy[lang]['section.idea.sr'])]), ...why.slice(0, cut));
      // 2. The exercise: instructions and the first demo stay open; what follows folds as notes.
      if (sec['before-after']) {
        const b = sec['before-after'];
        b.h2.properties = { ...b.h2.properties, id: 'before-after' };
        const k = b.body.findIndex((n) => (n.type === 'mdxJsxFlowElement' && DEMOS.has(n.name)) || (isEl(n, 'p') && n.children.some((c) => c.type === 'mdxJsxTextElement' && DEMOS.has(c.name))));
        const head = k < 0 ? b.body : b.body.slice(0, k + 1);
        const rest = k < 0 ? [] : b.body.slice(k + 1).filter((n) => n.type !== 'text' || n.value.trim());
        out.push(b.h2, ...head, ...(rest.length ? inlineFold(copy[lang]['fold.demo.notes'], rest, lang) : []));
      }
      // 3. Every other section is a question.
      out.push(el('div', { className: ['fold-lead'] }, [
        el('p', {}, [text(copy[lang]['fold.lead'])]),
        el('button', { type: 'button', className: ['btn', 'small', 'sec'], hidden: true, dataOpenAll: '', dataOpen: copy[lang]['fold.openAll'], dataClose: copy[lang]['fold.closeAll'] }, [text(copy[lang]['fold.openAll'])]),
      ]));
      const restWhy = why.slice(cut);
      const order = [['why', restWhy], ['gui'], ['script'], ['values'], ['verify'], ['mistakes']];
      for (const [id, body0] of order) {
        const body = body0 ?? sec[id]?.body;
        if (!body || !body.some((n) => n.type !== 'text' || n.value.trim())) continue;
        const hint = hintFor(id, body, lang);
        out.push(...fold(id, FOLD_ICON[id], el('h2', {}, [text(copy[lang][`fold.${id}.title`])]), hint, body, id === 'mistakes' ? 'mist' : '', lang));
      }
      tail();
    } else {
      chunks.slice(1).forEach((c, i) => {
        const id = SECTIONS[i] ?? `section-${i + 1}`;
        const h2 = c.h2;
        h2.properties = { ...h2.properties };
        if (FOLDED[id]) {
          delete h2.properties.id;
          out.push(...fold(id, FOLDED[id], h2, hintFor(id, c.body, lang), c.body, id === 'mistakes' ? 'mist' : '', lang));
        } else {
          h2.properties.id = id;
          if (id === 'why') h2.properties.className = ['sr'];
          out.push(h2, ...(id === 'before-after' ? foldSimulationNotes(c.body, lang) : c.body));
        }
        if (id === 'verify') tail();
      });
    }
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
