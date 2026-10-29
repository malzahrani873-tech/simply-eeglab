import type { Lang } from '../i18n';

const BASE = import.meta.env.BASE_URL.replace(/\/?$/, '/');
export const langOf = (u: URL): Lang => (u.pathname.startsWith(BASE + 'en/') || u.pathname === BASE + 'en' ? 'en' : 'ar');
