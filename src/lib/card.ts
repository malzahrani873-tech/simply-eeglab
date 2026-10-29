// Reference card content, taken from a lesson's MDX source at build time (DESIGN.md §7.18).
const ORDER = ['why', 'before-after', 'gui', 'script', 'values', 'mistakes', 'verify'] as const;

export interface CardData {
  steps: { path: string[][]; labels: string[]; values: string[] }[];
  script: string | null;
  table: string[][] | null;
  checks: string[];
  methods: string | null;
  warnings: string[];
  scriptInLesson: boolean;
}

// A script longer than this stays in the lesson; the card points to it (keeps the card within two A4 pages).
const SCRIPT_MAX_LINES = 18;

// Plain text for the card: lesson component tags (<UiLabel>, <En>, <MenuPath>…) keep only their text.
const strip = (s: string) => s.replace(/<\/?[A-Z][A-Za-z]*\b[^>]*>/g, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');

export function cardFrom(body: string): CardData {
  const parts = body.split(/^## .*$/m).slice(1);
  const sec = Object.fromEntries(ORDER.map((id, i) => [id, parts[i] ?? ''])) as Record<(typeof ORDER)[number], string>;
  // 1. Steps: every list item in the GUI section that names a menu or a field, with the values typed there.
  const raw = sec.gui.split('\n').filter((l) => /^\s*\d+\.\s/.test(l) && /<(MenuPath|UiLabel)>/.test(l)).map((l) => ({
    path: [...l.matchAll(/<MenuPath>([\s\S]*?)<\/MenuPath>/g)].map((m) => m[1].split('>').map((x) => x.trim())),
    labels: [...l.matchAll(/<UiLabel>([\s\S]*?)<\/UiLabel>/g)].map((m) => m[1].trim()),
    values: [...strip(l).replace(/<MenuPath>[\s\S]*?<\/MenuPath>|<UiLabel>[\s\S]*?<\/UiLabel>/g, '').matchAll(/`([^`]+)`/g)].map((m) => m[1]),
  }));
  // Consecutive steps on the same menu read as one line.
  const steps: CardData['steps'] = [];
  for (const st of raw) {
    const prev = steps.at(-1);
    if (prev && st.path.length && JSON.stringify(prev.path) === JSON.stringify(st.path)) {
      prev.labels.push(...st.labels);
      prev.values.push(...st.values);
    } else steps.push(st);
  }
  // 2. Script: the first code block of the script section, without comment and blank lines;
  // the code itself is never cut.
  const code = sec.script.match(/```[a-z]*\n([\s\S]*?)```/)?.[1];
  const lines = code ? code.split('\n').filter((l) => l.trim() && !/^\s*%/.test(l)) : [];
  const scriptInLesson = lines.length > SCRIPT_MAX_LINES;
  const script = lines.length && !scriptInLesson ? lines.join('\n') : null;
  // 3. The values table as written.
  const rows = sec.values.split('\n').filter((l) => /^\|.*\|\s*$/.test(l) && !/^\|[\s|:-]+\|\s*$/.test(l));
  let table = rows.length ? rows.map((r) => r.trim().slice(1, -1).split('|').map((c) => strip(c.trim()))) : null;
  // Keep the goal and value columns; the "why" column stays in the lesson.
  const why = table?.[0].findIndex((h, i) => i > 0 && /^(لماذا|why\b)/i.test(h)) ?? -1;
  if (table && why > 0 && table[0].length > 2) table = table.map((r) => r.filter((_, i) => i !== why));
  // 4. Checks: the bold lead of each top-level item, else the item up to its first full stop.
  const checks = sec.verify.split('\n').filter((l) => /^\d+\.\s/.test(l)).map((l) => {
    const t = strip(l.replace(/^\d+\.\s+/, ''));
    return (t.match(/^\*\*(.+?)\*\*/)?.[1] ?? t.split(/(?<=[.؟])\s/)[0]).replace(/[.:]$/, '').trim();
  }).slice(0, 5);
  const raw_m = body.match(/<Methods>\s*([\s\S]*?)\s*<\/Methods>/)?.[1].trim();
  const methods = raw_m ? strip(raw_m) : null;
  // 5. Warnings inside the GUI steps print as one line each: the bold lead, else the first sentence.
  const warnings = [...sec.gui.matchAll(/<Callout\b[^>]*type="warning"[^>]*>\s*([\s\S]*?)<\/Callout>/g)].map((m) => {
    const t = strip(m[1].trim());
    return (t.match(/^\*\*(.+?)\*\*/)?.[1] ?? t.split(/(?<=[.؟])\s/)[0]).replace(/[.:]$/, '').trim();
  }).filter(Boolean);
  return { steps, script, table, checks, methods, warnings, scriptInLesson };
}

// Rough height check against the smaller of A4 and Letter (279mm tall, 24mm margins), from line counts at the card's type sizes.
export function cardTooLong(c: CardData): boolean {
  const mm = 30 + c.steps.length * 6 + (c.script ? c.script.split('\n').length * 4 + 12 : 0) +
    (c.table ? c.table.reduce((a, r) => a + 5 * Math.max(1, Math.ceil(Math.max(...r.map((x) => x.length)) / 45)), 12) : 0) +
    c.checks.length * 6 + 10 + (c.methods ? Math.ceil(c.methods.length / 110) * 4.5 + 10 : 0) + 18;
  return mm > 255;
}
