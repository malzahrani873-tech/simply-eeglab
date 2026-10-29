import { existsSync, readFileSync } from 'node:fs';
import { isProduction } from '../site.config';
import { asset } from './url';

// Final game data lives in src/data/ as ica-game.items.json and ica-daily.items.json, each
// {"v", "source", "classes", "items": [...]}; images in assets-src/ica/. Until the game file exists,
// previews use the test fixture. ICA_DATA_DIR points the build at another folder (used by the build tests).
const override = process.env.ICA_DATA_DIR ? process.env.ICA_DATA_DIR.replace(/\/?$/, '/') : null;
const GAME = 'ica-game.items.json';
const DAILY = 'ica-daily.items.json';
const final = !override && existsSync('src/data/' + GAME);
const dir = override ?? (final ? 'src/data/' : 'tests/fixtures/ica/');
export const icaAvailable = final || !isProduction;
export const icaIsFixture = !final;

export const CAT_KEY: Record<string, string> = { brain: 'brain', eye: 'eye', muscle: 'muscle', heart: 'heart', line: 'lineNoise', chan: 'chanNoise', other: 'other' };

const withSrc = (items: any[]) => items.map((it) => ({ ...it, src: asset(`ica/${String(it.img).split('/').pop()}`) }));

export function icaGame(): any | null {
  if (!icaAvailable) return null;
  const g = JSON.parse(readFileSync(dir + GAME, 'utf8'));
  return { ...g, items: withSrc(g.items) };
}

// The daily list in day order, with full item fields and its own ids.
function dailyRaw(): any[] {
  if (!icaAvailable) return [];
  if (existsSync(dir + DAILY)) return withSrc(JSON.parse(readFileSync(dir + DAILY, 'utf8')).items ?? []);
  return [];
}
export const icaDaily = (): string[] => dailyRaw().map((i) => i.id);

// One solved example for the in-lesson teaser.
export function teaserItem() {
  const g = icaGame();
  const it = g?.items.find((i: any) => i.answer === 'eye') ?? g?.items[0];
  if (!it) return null;
  return {
    ...it,
    catKey: CAT_KEY[it.answer],
    alt: {
      ar: 'مكوّن ICA بثلاث لوحات: خريطة الرأس، والطيف، والنشاط عبر الزمن.',
      en: 'An ICA component in three panels: scalp map, spectrum and activity over time.',
    },
  };
}

// Per-language texts: src/data/ica-game.text.<lang>.json when it exists; previews fall back to class names only.
function textFor(lang: 'ar' | 'en') {
  const tf = `src/data/ica-game.text.${lang}.json`;
  return existsSync(tf) ? JSON.parse(readFileSync(tf, 'utf8')) : { classes: {}, confusions: {}, items: {} };
}
// Until a card has its own description, its image gets the general one (the three panels).
const ALT = {
  ar: 'مكوّن ICA بثلاث لوحات: خريطة الرأس، والطيف، والنشاط عبر الزمن.',
  en: 'An ICA component in three panels: scalp map, spectrum and activity over time.',
};
const shape = (i: any, text: any, lang: 'ar' | 'en') => ({
  id: i.id, src: i.src, w: i.w, h: i.h, level: i.level, answer: i.answer, iclabel: i.iclabel,
  line_hz: i.line_hz ?? null, hint: i.hint_panel ?? null, eye: i.eye_subtype ?? null,
  note: text.items?.[i.id]?.note ?? '', alt: text.items?.[i.id]?.alt || ALT[lang],
});

// Per-language game file: neutral item data plus that language's texts (interactives_spec §5.8).
export function icaGameFor(lang: 'ar' | 'en') {
  const g = icaGame();
  if (!g) return null;
  const text = textFor(lang);
  const neutral = JSON.stringify(g.items.map((i: any) => [i.id, i.answer, i.level, i.img]));
  let h = 0;
  for (let i = 0; i < neutral.length; i++) h = (h * 31 + neutral.charCodeAt(i)) >>> 0;
  return {
    v: 1, dataVersion: h.toString(36), fixture: icaIsFixture, classes: g.classes,
    items: g.items.map((i: any) => shape(i, text, lang)),
    signature: Object.fromEntries(Object.entries(text.classes ?? {}).map(([k, v]: any) => [k, v.signature ?? ''])),
    confusions: text.confusions ?? {},
  };
}

// Today's-component files, one per day in list order. An empty list switches the component of the
// day off: no section, no files, no links.
export function dailyItems(lang: 'ar' | 'en') {
  const g = icaGameFor(lang);
  if (!g) return [];
  const text = textFor(lang);
  return dailyRaw().map((i) => ({ ...shape(i, text, lang), signature: g.signature, confusions: g.confusions, dataVersion: g.dataVersion }));
}
export const hasDaily = () => dailyRaw().length > 0;
