// Small Markdown subset for data files: paragraphs, "- " lists, **bold**, `code`, <MenuPath>a > b</MenuPath>.
import { iso } from './bidi';
import type { Lang } from '../i18n';

const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!);

export function mdInline(s: string, lang: Lang): string {
  const parts = s.split(/(`[^`]+`|<MenuPath>[\s\S]+?<\/MenuPath>|\*\*[\s\S]+?\*\*)/);
  return parts.map((p) => {
    if (p.startsWith('`') && p.endsWith('`') && p.length > 1) return `<code dir="ltr">${esc(p.slice(1, -1))}</code>`;
    if (p.startsWith('<MenuPath>')) {
      const steps = p.slice(10, -11).split('>').map((x) => `<span class="it">${esc(x.trim())}</span>`);
      return `<span class="mp" dir="ltr" lang="en">${steps.join(' <span class="cr" aria-hidden="true">›</span> ')}</span>`;
    }
    if (p.startsWith('**') && p.endsWith('**')) return `<b>${mdInline(p.slice(2, -2), lang)}</b>`;
    return iso(p, lang);
  }).join('');
}

export function md(s: string, lang: Lang): string {
  return s.trim().split(/\n{2,}/).map((block) => {
    const lines = block.split('\n');
    const items = lines.filter((l) => l.startsWith('- '));
    if (items.length && items.length === lines.length - (lines[0].startsWith('- ') ? 0 : 1)) {
      const lead = lines[0].startsWith('- ') ? '' : `<p>${mdInline(lines[0], lang)}</p>`;
      return lead + '<ul>' + items.map((l) => `<li>${mdInline(l.slice(2), lang)}</li>`).join('') + '</ul>';
    }
    return `<p>${mdInline(lines.join(' '), lang)}</p>`;
  }).join('');
}
