// Turns the first appearance of each glossary term in a lesson into a button that opens a short
// definition (Popover API, no script). Runs after the lesson template so "first" follows reading order.
import { readFileSync } from 'node:fs';
import { icon } from './rehype-lesson.mjs';

const MAX_TERMS = 12;
const glossary = JSON.parse(readFileSync('src/data/glossary.json', 'utf8'));
const copy = {};
for (const lang of ['ar', 'en']) copy[lang] = JSON.parse(readFileSync(`src/i18n/${lang}.json`, 'utf8'));

const ARABIC = /[؀-ۿ]/;
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
// Attached Arabic prefixes a term may carry: conjunction, preposition, article.
const AR_PREFIX = '(?:[وف])?(?:[بلك])?(?:ال|لل)?';
const NOT_LETTER = '[\\p{L}\\p{M}\\p{N}_]';

// Phrases that contain a glossary word but mean something else; the word inside them gets no hint.
const PROTECTED = ['power line', 'power lines', 'power-line', 'power supply', 'خط الكهرباء', 'خطوط الكهرباء'];
// Every form of every term, plus the protected phrases: a match inside a longer one of these is skipped,
// so "line noise" wins over "noise" and "power line" never shows the hint for "power".
function shadowRe(lang) {
  const forms = [...glossary.flatMap((g) => [g.en, g.ar, ...g.variants]), ...PROTECTED]
    .filter((f) => f.includes(' ') || f.includes('-')).sort((a, b) => b.length - a.length).map(esc);
  return new RegExp(`(?<!${NOT_LETTER})${lang === 'ar' ? AR_PREFIX : ''}(?:${forms.join('|')})(?!${NOT_LETTER})`, 'giu');
}

function matchers(lang) {
  return glossary.map((g) => {
    const latin = [g.en, ...(ARABIC.test(g.ar) ? [] : [g.ar]), ...g.variants.filter((v) => !ARABIC.test(v))];
    const arabic = [g.ar, ...g.variants].filter((v) => ARABIC.test(v));
    let re = null;
    if (lang === 'ar' && arabic.length) {
      const forms = arabic.sort((a, b) => b.length - a.length).map(esc).join('|');
      re = new RegExp(`(?<!${NOT_LETTER})${AR_PREFIX}(?:${forms})(?!${NOT_LETTER})`, 'gu');
    } else if (lang === 'en') {
      const forms = latin.sort((a, b) => b.length - a.length).map(esc).join('|');
      re = new RegExp(`(?<!${NOT_LETTER})(?:${forms})(?!${NOT_LETTER})`, 'giu');
    }
    // In Arabic lessons an English form counts only as a whole isolated run (an <En> or an auto-isolated span).
    const whole = lang === 'ar' && g.decision !== 'ع' ? new Set(latin.map((x) => x.toLowerCase())) : new Set();
    return { g, re, whole };
  });
}

const el = (tagName, properties, children = []) => ({ type: 'element', tagName, properties, children });
const text = (value) => ({ type: 'text', value });
const textOf = (n) => (n.type === 'text' ? n.value : (n.children ?? []).map(textOf).join(''));
const SKIP_TAGS = new Set(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'pre', 'code', 'a', 'summary', 'button', 'kbd', 'samp', 'svg', 'script', 'style']);
const TEXT_JSX = new Set(['Callout']);

function trigger(g, label, lang, latin) {
  const props = { type: 'button', className: ['term'], popoverTarget: `term-${g.id}` };
  if (latin) Object.assign(props, { lang: 'en', dir: 'ltr' });
  return el('button', props, [text(label), el('span', { className: ['sr'] }, [text(copy[lang]['term.sr'])])]);
}

function card(g, lang) {
  const head = [];
  if (lang === 'ar') {
    head.push(el('strong', ARABIC.test(g.ar) ? {} : { lang: 'en', dir: 'ltr' }, [text(g.ar)]));
    if (g.en.toLowerCase() !== g.ar.toLowerCase()) head.push(el('bdi', { lang: 'en', className: ['muted'] }, [text(g.en)]));
  } else head.push(el('strong', {}, [text(g.en)]));
  head.push(el('button', { type: 'button', className: ['term-x'], popoverTarget: `term-${g.id}`, popoverTargetAction: 'hide', ariaLabel: copy[lang]['term.close'] }, [icon('close', 'ico s20')]));
  return el('span', { id: `term-${g.id}`, className: ['term-def'], popover: 'auto', role: 'note', dataPagefindIgnore: '' }, [
    el('span', { className: ['term-def-head'] }, head),
    el('span', { className: ['term-def-body'] }, [text(g.def[lang])]),
  ]);
}

export default function rehypeTerms() {
  const byLang = { ar: matchers('ar'), en: matchers('en') };
  const shadows = { ar: shadowRe('ar'), en: shadowRe('en') };
  return (tree, file) => {
    const path = (file.path ?? file.history?.[0] ?? '').replace(/\\/g, '/');
    const m = path.match(/content\/lessons\/(ar|en)\/[^/]+\.mdx$/);
    if (!m) return;
    const lang = m[1];
    const left = [...byLang[lang]];
    let used = 0;

    const takeWhole = (s) => {
      const k = left.findIndex((x) => x.whole.has(s.trim().toLowerCase()));
      return k < 0 ? null : left.splice(k, 1)[0];
    };
    // First match of a term that is not part of a longer term or protected phrase in the same text.
    const firstFree = (re, s, spans) => {
      re.lastIndex = 0;
      for (let r; (r = re.exec(s)); ) {
        const a = r.index, b = a + r[0].length;
        if (!spans.some(([x, y]) => x <= a && b <= y && y - x > b - a)) return r;
        if (r[0].length === 0) re.lastIndex++;
      }
      return null;
    };
    // Splits one text node at the earliest remaining match; returns the replacement nodes.
    const splitText = (value) => {
      const out = [];
      let rest = value;
      while (used < MAX_TERMS && rest) {
        const spans = [...rest.matchAll(shadows[lang])].map((m) => [m.index, m.index + m[0].length]);
        let best = null;
        for (const x of left) {
          if (!x.re) continue;
          const r = firstFree(x.re, rest, spans);
          if (r && (!best || r.index < best.r.index || (r.index === best.r.index && r[0].length > best.r[0].length))) best = { x, r };
        }
        if (!best) break;
        left.splice(left.indexOf(best.x), 1);
        used++;
        const { index } = best.r;
        if (index) out.push(text(rest.slice(0, index)));
        out.push(trigger(best.x.g, best.r[0], lang, false), card(best.x.g, lang));
        rest = rest.slice(index + best.r[0].length);
      }
      if (rest) out.push(text(rest));
      return out;
    };

    const visit = (n) => {
      if (!n.children || used >= MAX_TERMS) return;
      const kids = [];
      for (const c of n.children) {
        if (used >= MAX_TERMS) { kids.push(c); continue; }
        if (c.type === 'text') { kids.push(...splitText(c.value)); continue; }
        // A whole English run inside Arabic text: <En>…</En> or an isolated Latin span.
        const isEn = c.type === 'mdxJsxTextElement' && c.name === 'En';
        const isBdi = c.type === 'element' && c.tagName === 'bdi' && c.properties?.lang === 'en';
        if (lang === 'ar' && (isEn || isBdi)) {
          const x = takeWhole(textOf(c));
          if (x) { used++; kids.push(trigger(x.g, textOf(c), lang, true), card(x.g, lang)); continue; }
          kids.push(c);
          continue;
        }
        if (c.type === 'element') {
          const cls = c.properties?.className ?? [];
          if (SKIP_TAGS.has(c.tagName) || cls.includes('print-copy') || cls.includes('sr') || cls.includes('start1')) { kids.push(c); continue; }
          visit(c);
        } else if (c.type?.startsWith('mdxJsx')) {
          if (TEXT_JSX.has(c.name)) visit(c);
        } else visit(c);
        kids.push(c);
      }
      n.children = kids;
    };
    visit(tree);
  };
}
