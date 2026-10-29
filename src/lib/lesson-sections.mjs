// What each H2 section of a lesson is, from its title and its Markdown body (used by the page, the card and the checks).
// A lesson has only the sections its content needs, with titles written for that lesson; the template does not add any.
// Kinds: gui (menu steps: a title that says "from the menus", or numbered steps naming menus or fields), script (MATLAB), values (a table of choices), verify, mistakes, topic (anything else).
import { readFileSync } from 'node:fs';

const copy = {};
for (const lang of ['ar', 'en']) copy[lang] = JSON.parse(readFileSync(`src/i18n/${lang}.json`, 'utf8'));

// Titles of the old fixed template, still accepted: each shows as its student question.
const LEGACY = { why: 'why', beforeAfter: 'before-after', gui: 'gui', script: 'script', values: 'values', mistakes: 'mistakes', verify: 'verify' };
const legacy = new Map();
for (const lang of ['ar', 'en']) {
  for (const [key, kind] of Object.entries(LEGACY)) {
    const fold = kind === 'before-after' ? null : copy[lang][`fold.${kind}.title`];
    for (const title of [copy[lang][`section.${key}`], fold]) if (title) legacy.set(title.trim(), { kind, lang, key });
  }
}
export const legacyTitle = (title) => legacy.get(title.trim()) ?? null;

const MISTAKES = /أخطاء|الخطأ|يخطئ|mistake|pitfall|go wrong/i;
const GUI = /من القوائم|بالقوائم|من الواجهة|في الواجهة|(from|in|with) the menus|in the GUI|menu steps/i;
const VERIFY = /اختبر نفسك|test yourself|تتأكد|أتأكد|نتأكد|تتحقق|أتحقق|نجح|\bcheck\b|worked|verify/i;

// Kind from raw Markdown (the card and the content checks read the source).
export function kindOfMarkdown(title, body) {
  const old = legacyTitle(title);
  if (old) return old.kind === 'before-after' || old.kind === 'why' ? 'topic' : old.kind;
  if (MISTAKES.test(title)) return 'mistakes';
  if (GUI.test(title)) return 'gui';
  if (VERIFY.test(title)) return 'verify';
  if (/^\s*\d+\.\s.*<(MenuPath|UiLabel)>/m.test(body)) return 'gui';
  if (/^```matlab/m.test(body)) return 'script';
  if (/^\|.*\|\s*$/m.test(body)) return 'values';
  return 'topic';
}

// Sections of a lesson's Markdown body: [{ title, body, kind }], the first one being the idea.
export function sectionsOfMarkdown(body) {
  return body.split(/^## /m).slice(1).map((chunk) => {
    const nl = chunk.indexOf('\n');
    const title = (nl < 0 ? chunk : chunk.slice(0, nl)).trim();
    const text = nl < 0 ? '' : chunk.slice(nl + 1);
    return { title, body: text, kind: kindOfMarkdown(title, text) };
  });
}
