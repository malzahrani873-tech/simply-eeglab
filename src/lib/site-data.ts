import { getCollection, type CollectionEntry } from 'astro:content';
import { loadRoadmap, loadDatasets } from './roadmap.mjs';
import { isProduction } from '../site.config';
import type { Lang } from '../i18n';

export type Lesson = CollectionEntry<'lessons'>;
export const roadmap = loadRoadmap();
export const datasets: any[] = loadDatasets();
export const datasetByCode = new Map(datasets.map((d) => [d.code, d]));

let cache: Map<string, Lesson> | null = null;

// All lessons that are published in this build, keyed "<lang>/<slug>".
export async function lessons(): Promise<Map<string, Lesson>> {
  if (cache) return cache;
  const all = await getCollection('lessons');
  cache = new Map(all.filter((l) => !isProduction || l.data.status === 'approved').map((l) => [l.id, l]));
  return cache;
}

export async function lesson(lang: Lang, slug: string) {
  return (await lessons()).get(`${lang}/${slug}`);
}

export const slugOf = (l: Lesson) => l.id.split('/')[1];

export function nodeTitle(lang: Lang, id: string) {
  const n = roadmap.byId.get(id);
  return n ? (lang === 'ar' ? n.title : n.titleEn) : id;
}

export function stationTitle(lang: Lang, nn: number) {
  const s = roadmap.stations.find((s: any) => s.station === nn);
  return lang === 'ar' ? s.title : s.titleEn;
}

export const pad = (n: number) => String(n).padStart(2, '0');

// Published lessons in map order for one language.
export async function lessonsInOrder(lang: Lang) {
  const map = await lessons();
  return roadmap.nodes.map((n: any) => ({ node: n, lesson: map.get(`${lang}/${n.id}`) }));
}

// Next lesson that actually exists, following the computed chain.
export async function nextAvailable(lang: Lang, id: string) {
  const map = await lessons();
  let cur = roadmap.byId.get(id)?.next;
  const first = cur;
  while (cur && !map.has(`${lang}/${cur}`)) cur = roadmap.byId.get(cur)?.next;
  return { planned: first, available: cur ?? null };
}

// Every lesson file, published or not: soon cards still show the lesson's first objective.
export async function allLessonFiles(): Promise<Map<string, Lesson>> {
  return new Map((await getCollection('lessons')).map((l) => [l.id, l]));
}
