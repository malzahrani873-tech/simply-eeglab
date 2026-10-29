import ar from './ar.json';
import en from './en.json';
import pending from './pending.json';
// Plural forms that the copy source describes in prose (site_copy.md v1.4 §3), written out here.
import plurals from './plurals.json';

export type Lang = 'ar' | 'en';
// Keys agreed for the redesign but not yet in the copy source are kept in pending.json.
const dict: Record<Lang, Record<string, string>> = {
  ar: { ...pending.ar, ...ar, ...plurals.ar },
  en: { ...pending.en, ...en, ...plurals.en },
};

export function t(lang: Lang, key: string, vars: Record<string, string | number> = {}): string {
  const s = dict[lang][key] ?? dict.ar[key];
  if (s === undefined) throw new Error(`missing copy key: ${key}`);
  return s.replace(/\{(\w+)\}/g, (_, k) => (k in vars ? String(vars[k]) : `{${k}}`));
}

// Plural forms by Intl.PluralRules: "<key>.one", ".two", ".few", ".many", else the base key ("other").
const rules = { ar: new Intl.PluralRules('ar'), en: new Intl.PluralRules('en') };
export function tn(lang: Lang, key: string, n: number, vars: Record<string, string | number> = {}): string {
  const form = rules[lang].select(n);
  const k = form !== 'other' && `${key}.${form}` in dict[lang] ? `${key}.${form}` : key;
  return t(lang, k, { n, ...vars });
}

export const otherLang = (lang: Lang): Lang => (lang === 'ar' ? 'en' : 'ar');
export const dir = (lang: Lang) => (lang === 'ar' ? 'rtl' : 'ltr');
