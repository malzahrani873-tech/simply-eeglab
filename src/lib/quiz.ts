import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { isProduction } from '../site.config';
import { load as loadYaml } from 'js-yaml';
import { iso } from './bidi';
import type { Lang } from '../i18n';

export interface QuizOption { id: string; text: string }
export interface QuizQuestion {
  id: string; type: 'single' | 'multiple' | 'order' | 'image'; lesson: string; objective: number;
  prompt: string; options: QuizOption[]; answer: string[]; explanation: string;
  image?: { src: string; w: number; h: number; status: 'pending' | 'draft' | 'ready'; alt: string; fromIcaGame?: string };
}
export interface Quiz { v: 1; station: number; lang: Lang; passPercent: number; questions: QuizQuestion[] }

const pad = (n: number) => String(n).padStart(2, '0');

// Lessons live in this build: production shows approved lessons only.
const live = new Map<Lang, Set<string>>();
function liveLessons(lang: Lang) {
  if (!live.has(lang)) {
    const dir = `content/lessons/${lang}`;
    live.set(lang, new Set(readdirSync(dir).filter((f) => /^status:\s*approved\s*$/m.test(readFileSync(`${dir}/${f}`, 'utf8')))
      .map((f) => f.replace(/^\d\d-\d\d-/, '').replace(/\.mdx$/, ''))));
  }
  return live.get(lang)!;
}

// A production quiz leaves out questions whose image is not ready or whose lesson is not live yet;
// they come back once both are in place. A quiz left with fewer than 4 questions is held back whole.
export function quizFor(station: number, lang: Lang): Quiz | null {
  const f = `src/data/quizzes/${pad(station)}.${lang}.json`;
  if (!existsSync(f)) return null;
  const q: Quiz = JSON.parse(readFileSync(f, 'utf8'));
  if (!isProduction) return q;
  const questions = q.questions.filter((x) => (!x.image || x.image.status === 'ready') && liveLessons(lang).has(x.lesson));
  return questions.length >= 4 ? { ...q, questions } : null;
}

// Quiz text is plain text; `backticks` become LTR code.
export function qtext(s: string, lang: Lang): string {
  return s.split(/`([^`]+)`/).map((part, i) => (i % 2
    ? `<code dir="ltr">${part.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!)}</code>`
    : iso(part, lang))).join('');
}

export interface StationText { station: number; description: string; descriptionEn: string; outcomes: string[]; outcomesEn: string[] }
let stations: StationText[] | null = null;
export function stationText(n: number): StationText | undefined {
  stations ??= loadYaml(readFileSync('src/data/stations.yaml', 'utf8')) as StationText[];
  return stations.find((s) => s.station === n);
}
