// /progress/: summary, restore code and link, progress file, persistent storage, and "add from link".
import { KEYS, read, write, all, passedStations, storageOk } from './progress';
import { encode, decode } from './progress-code';

const root = document.getElementById('prog')!;
const L = root.dataset;
const $ = <T extends HTMLElement = HTMLElement>(s: string) => root.querySelector<T>(s)!;
const slots = new Map<string, number>(JSON.parse(L.slots!).map((s: string, i: number) => [s, i + 1]));
const ids: string[] = JSON.parse(L.ids!);
const cores: string[] = JSON.parse(L.cores!);
const fill = (s: string, v: Record<string, string | number>) => s.replace(/\{(\w+)\}/g, (_, k) => String(v[k] ?? ''));
const today = () => new Date().toISOString().slice(0, 10);
const plural = (n: number) => { const f = new Intl.PluralRules(document.documentElement.lang).select(n); return (f === 'two' && L.lStreakTwo) || (f === 'few' && L.lStreakFew) || L.lStreak!; };
const PREFIX = 'simplyeeglab:';
const SKIP = ['simplyeeglab:theme', KEYS.tips];

function code() {
  const done = Object.keys(all()).filter((s) => slots.has(s));
  return done.length || passedStations().length ? encode(done, passedStations(), slots) : '';
}

function render() {
  const done = all();
  const n = ids.filter((i) => i in done).length;
  $('[data-sum-count]').textContent = fill(L.lCount!, { n, total: ids.length });
  $('[data-sum-core]').textContent = fill(L.lCore!, { n: cores.filter((i) => i in done).length, total: cores.length });
  const games = read<any>(KEYS.icagame)?.rounds ?? 0;
  $('[data-sum-games]').hidden = !games;
  $('[data-sum-games]').textContent = fill(L.lGames!, { n: games });
  const streak = read<any>(KEYS.daily)?.streak ?? 0;
  $('[data-sum-streak]').hidden = !streak;
  $('[data-sum-streak]').textContent = fill(plural(streak), { n: streak });
  const c = code();
  const box = $('[data-code]');
  box.textContent = c;
  box.setAttribute('aria-label', fill(L.lCodeSr!, { code: [...c.replace(/-/g, '')].join(' ') }));
  box.hidden = !c;
  $('[data-code-empty]').hidden = !!c;
  for (const s of ['[data-copy-code]', '[data-copy-link]', '[data-download]']) $<HTMLButtonElement>(s).disabled = !c && s !== '[data-download]';
  dispatchEvent(new CustomEvent('progress-changed'));
}

function saved() {
  write(KEYS.backup, { v: 1, count: Object.keys(all()).length, at: today() });
}

async function copy(text: string) {
  try { await navigator.clipboard.writeText(text); $('[data-move-status]').textContent = L.lCopied!; saved(); } catch { $('[data-move-status]').textContent = text; }
}

// Union of lessons and quizzes, keeping the older date for each.
function merge(done: Record<string, string>, passed: Record<string, string>) {
  const cur = all();
  for (const [k, d] of Object.entries(done)) if (!cur[k] || d < cur[k]) cur[k] = d;
  write(KEYS.progress, { v: 1, done: cur });
  const q = read<any>(KEYS.quiz) ?? { v: 1, passed: {} };
  for (const [k, d] of Object.entries(passed)) if (!q.passed[k] || d < q.passed[k]) q.passed[k] = d;
  write(KEYS.quiz, q);
}

function addedCount(done: string[], passed: number[]) {
  const cur = all(), q = passedStations();
  return done.filter((d) => !(d in cur)).length + passed.filter((p) => !q.includes(p)).length;
}

const status = $('[data-restore-status]');
function confirmAdd(done: string[], passed: number[]) {
  const n = addedCount(done, passed);
  if (!n) { status.textContent = L.lLinkNone!; return; }
  const dlg = $<HTMLDialogElement>('[data-add-dialog]');
  $('[data-add-body]').textContent = fill(L.lLinkBody!, { n });
  dlg.showModal();
  $<HTMLButtonElement>('[data-add-cancel]').onclick = () => dlg.close();
  $<HTMLButtonElement>('[data-add-ok]').onclick = () => {
    const d = today();
    merge(Object.fromEntries(done.map((s) => [s, d])), Object.fromEntries(passed.map((p) => [String(p), d])));
    dlg.close();
    render();
    status.textContent = fill(L.lDone!, { n: ids.filter((i) => i in all()).length, total: ids.length });
  };
}

function fromCode(text: string) {
  try {
    const r = decode(text, slots);
    confirmAdd(r.done, r.passed);
  } catch (e) {
    status.textContent = (e as Error).message === 'arabic-letters' ? L.lArabic! : L.lBadCode!;
  }
}

function exportFile() {
  const data: Record<string, unknown> = {};
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i)!;
    if (!k.startsWith(PREFIX) || SKIP.includes(k) || k.endsWith('.corrupt')) continue;
    try { data[k] = JSON.parse(localStorage.getItem(k)!); } catch {}
  }
  const blob = new Blob([JSON.stringify({ app: 'simplyeeglab', v: 1, exported: today(), data }, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = fill(L.lFileName!, { date: today() });
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  saved();
}

const KNOWN = new Set(Object.values(KEYS));
async function importFile(file: File) {
  let obj: any;
  try {
    if (file.size > 64 * 1024) throw new Error('size');
    obj = JSON.parse(await file.text());
    if (obj?.app !== 'simplyeeglab' || obj.v !== 1 || typeof obj.data !== 'object') throw new Error('format');
  } catch { status.textContent = L.lBadFile!; return; }
  const entries = Object.entries(obj.data).filter(([k]) => KNOWN.has(k) && !SKIP.includes(k)) as [string, any][];
  const newer = entries.some(([, v]) => v?.v !== 1) || Object.keys(obj.data).some((k) => !KNOWN.has(k));
  const usable = entries.filter(([, v]) => v?.v === 1);
  const dlg = $<HTMLDialogElement>('[data-file-dialog]');
  const warn = $('[data-replace-warn]');
  const mode = () => dlg.querySelector<HTMLInputElement>('input[name=fmode]:checked')!.value;
  warn.hidden = true;
  dlg.querySelectorAll<HTMLInputElement>('input[name=fmode]').forEach((r) => (r.onchange = () => (warn.hidden = true)));
  dlg.showModal();
  $<HTMLButtonElement>('[data-file-cancel]').onclick = () => dlg.close();
  $<HTMLButtonElement>('[data-file-ok]').onclick = () => {
    if (mode() === 'replace') {
      if (warn.hidden) { warn.hidden = false; return; } // second, explicit confirmation
      for (const k of Object.values(KEYS)) if (!SKIP.includes(k)) try { localStorage.removeItem(k); } catch {}
      for (const [k, v] of usable) write(k, v);
    } else {
      const get = (k: string) => usable.find(([x]) => x === k)?.[1];
      merge(get(KEYS.progress)?.done ?? {}, get(KEYS.quiz)?.passed ?? {});
      for (const [k, v] of usable) if (k !== KEYS.progress && k !== KEYS.quiz && read(k) === null) write(k, v);
    }
    dlg.close();
    render();
    status.textContent = fill(L.lDone!, { n: ids.filter((i) => i in all()).length, total: ids.length }) + (newer ? ' ' + L.lNewer : '');
  };
}

if (!storageOk()) {
  $('[data-unavail]').hidden = false;
} else {
  root.querySelectorAll<HTMLElement>('.js-only').forEach((e) => (e.hidden = false));
  render();
  $('[data-copy-code]').addEventListener('click', () => copy(code()));
  $('[data-copy-link]').addEventListener('click', () => copy(`${L.baseUrl}#c=${code().replace(/-/g, '')}`));
  $('[data-download]').addEventListener('click', exportFile);
  $<HTMLFormElement>('[data-restore-form]').addEventListener('submit', (e) => { e.preventDefault(); fromCode($<HTMLInputElement>('#pp-code').value); });
  $<HTMLInputElement>('[data-file]').addEventListener('change', (e) => { const f = (e.target as HTMLInputElement).files?.[0]; if (f) importFile(f); (e.target as HTMLInputElement).value = ''; });
  if (navigator.storage?.persist) {
    $('[data-persist-box]').hidden = false;
    $('[data-persist]').addEventListener('click', async () => {
      const ok = (await navigator.storage.persist()) || (await navigator.storage.persisted());
      $('[data-persist-status]').textContent = ok ? L.lPersistOn! : L.lPersistOff!;
    });
  }
  addEventListener('progress-reset', render);
  addEventListener('storage', render);
  addEventListener('pageshow', render);
  // Restore link: read once, remove it from the address bar, and only ever add.
  const m = location.hash.match(/^#c=([0-9A-Za-z-]+)$/);
  if (m) { history.replaceState(null, '', location.pathname + location.search); fromCode(m[1]); }
}
