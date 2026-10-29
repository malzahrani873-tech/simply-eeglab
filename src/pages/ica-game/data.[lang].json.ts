import type { APIRoute } from 'astro';
import { icaGameFor, icaAvailable } from '../../lib/ica-data';

export function getStaticPaths() {
  return icaAvailable ? [{ params: { lang: 'ar' } }, { params: { lang: 'en' } }] : [];
}
export const GET: APIRoute = ({ params }) => new Response(JSON.stringify(icaGameFor(params.lang as 'ar' | 'en')));
