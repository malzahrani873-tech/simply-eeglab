import type { APIRoute } from 'astro';
import { dailyItems } from '../../../lib/ica-data';

// One small file per position in the daily list and language (/ica-game/daily/<index>.<lang>.json), plus
// count.json with the list length. Nothing is generated while the list is empty.
export function getStaticPaths() {
  const lists = { ar: dailyItems('ar'), en: dailyItems('en') };
  if (!lists.ar.length) return [];
  return [
    { params: { file: 'count' }, props: { body: { n: lists.ar.length } } },
    ...(['ar', 'en'] as const).flatMap((lang) => lists[lang].map((item, n) => ({ params: { file: `${n}.${lang}` }, props: { body: item } }))),
  ];
}
export const GET: APIRoute = ({ props }) => new Response(JSON.stringify((props as any).body));
