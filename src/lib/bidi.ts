// Arabic text with embedded Latin terms: each Latin run is isolated so punctuation and
// word order stay right ("فلترة high-pass و low-pass").
const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!);
// Short terms without spaces ("high-pass") never break across lines; longer runs may wrap.
export const nowrap = (run: string) => !/\s/.test(run) && run.length <= 24;
export const RUN = /[A-Za-z0-9_.][A-Za-z0-9 ._\-/+&]*[A-Za-z0-9_]|[A-Za-z]/g;
export function iso(s: string, lang: 'ar' | 'en' = 'ar'): string {
  if (lang === 'en') return esc(s);
  let out = '', last = 0;
  for (const m of s.matchAll(RUN)) {
    if (!/[A-Za-z]/.test(m[0])) continue;
    out += esc(s.slice(last, m.index)) + `<bdi lang="en"${nowrap(m[0]) ? ' class="nw"' : ''}>${esc(m[0])}</bdi>`;
    last = m.index! + m[0].length;
  }
  return out + esc(s.slice(last));
}
