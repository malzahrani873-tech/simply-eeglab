// Local progress, kept in this browser only. Every access is guarded: storage can be blocked.
export const KEYS = {
  progress: 'simplyeeglab:progress.v1', icagame: 'simplyeeglab:icagame.v1', quiz: 'simplyeeglab:quiz.v1',
  daily: 'simplyeeglab:daily.v1', last: 'simplyeeglab:last.v1', backup: 'simplyeeglab:backup.v1', tips: 'simplyeeglab:tips.v1',
};

export function storageOk(): boolean {
  try { const k = 'simplyeeglab:probe'; localStorage.setItem(k, '1'); localStorage.removeItem(k); return true; } catch { return false; }
}

// Reads a JSON value. A value that does not parse or has an unknown version is ignored (returns null).
export function read<T = any>(key: string, v = 1): T | null {
  try {
    const raw = localStorage.getItem(key);
    if (raw === null) return null;
    const o = JSON.parse(raw);
    if (!o || typeof o !== 'object' || o.v !== v) throw new Error('bad');
    return o;
  } catch { return null; }
}

// Before the first write over a damaged value, keep one copy of it next to the key.
export function write(key: string, value: object): boolean {
  try {
    const raw = localStorage.getItem(key);
    if (raw !== null) {
      let ok = false;
      try { ok = JSON.parse(raw)?.v === (value as any).v; } catch {}
      if (!ok && localStorage.getItem(key + '.corrupt') === null) localStorage.setItem(key + '.corrupt', raw);
    }
    localStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch { return false; }
}

const today = () => new Date().toISOString().slice(0, 10);
export const all = (): Record<string, string> => read<{ v: 1; done: Record<string, string> }>(KEYS.progress)?.done ?? {};
export const isDone = (id: string) => id in all();
export function markDone(id: string) { const done = all(); if (!done[id]) done[id] = today(); return write(KEYS.progress, { v: 1, done }); }
export function unmark(id: string) { const done = all(); delete done[id]; return write(KEYS.progress, { v: 1, done }); }
export function passedStations(): number[] { return read<{ v: 1; passed: Record<string, string> }>(KEYS.quiz)?.passed ? Object.keys(read<any>(KEYS.quiz).passed).map(Number) : []; }
export function markPassed(st: number) { const q = read<any>(KEYS.quiz) ?? { v: 1, passed: {} }; q.passed[st] ??= today(); return write(KEYS.quiz, q); }
export function setLast(slug: string) { write(KEYS.last, { v: 1, slug, at: today() }); }
export function tips(): string[] { return read<any>(KEYS.tips)?.closed ?? []; }
export function closeTip(id: string) { const c = tips(); if (!c.includes(id)) c.push(id); write(KEYS.tips, { v: 1, closed: c }); }

// Clears progress. Theme and closed tips are display preferences and stay.
export function reset() {
  for (const k of ['progress', 'icagame', 'quiz', 'daily', 'last', 'backup'] as const) {
    try { localStorage.removeItem(KEYS[k]); } catch {}
  }
}
