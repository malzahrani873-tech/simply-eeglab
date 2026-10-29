import type { Lang } from '../i18n';

const BASE = import.meta.env.BASE_URL.replace(/\/?$/, '/');

// Every internal link goes through url() so the site also works under a sub-path.
export function url(path: string, lang: Lang = 'ar'): string {
  const p = path.replace(/^\//, '');
  const prefix = lang === 'en' ? 'en/' : '';
  return BASE + prefix + p;
}

// Same page in the other language (the path without the language prefix).
export function asset(path: string): string {
  return BASE + path.replace(/^\//, '');
}
