import { all, read, KEYS, storageOk } from './progress';

const rm = document.getElementById('rm')!;
const bar = document.getElementById('mbar')!;
const L = bar.dataset;
const nodes: [string, string, number][] = JSON.parse(rm.dataset.map!);
const manageText = bar.querySelector('.mmanage')?.textContent ?? '';
const fill = (s: string, v: Record<string, string | number>) => s.replace(/\{(\w+)\}/g, (_, k) => String(v[k] ?? ''));

function render() {
  if (!storageOk()) return;
  try { renderBar(); } finally { dispatchEvent(new CustomEvent('map-changed')); }
}

function renderBar() {
  const done = all();
  const total = nodes.length;
  const count = nodes.filter(([id]) => id in done).length;
  for (const a of rm.querySelectorAll<HTMLAnchorElement>('.node')) {
    const d = a.dataset.id! in done;
    a.classList.toggle('done-n', d);
    const base = a.getAttribute('aria-label')!.replace(L.lDoneSr!, '');
    a.setAttribute('aria-label', d ? base + L.lDoneSr : base);
    a.classList.remove('next');
    a.querySelector('.pill')?.remove();
  }
  // Station counters.
  for (const m of rm.querySelectorAll<HTMLElement>('[data-st]')) {
    const li = m.closest('.rs')!;
    const ids = [...li.querySelectorAll<HTMLElement>('.node')].map((n) => n.dataset.id!);
    const n = ids.filter((i) => i in done).length;
    if (count) m.textContent = fill(L.lSt!, { n, total: ids.length });
    li.classList.toggle('done-s', n === ids.length);
  }
  if (!count) return;
  // Continue: the last opened lesson, else the first published lesson not done, in map order.
  const last = read<any>(KEYS.last)?.slug;
  const lastNode = nodes.find(([id, , pub]) => id === last && pub && !(id in done));
  const next = lastNode ?? nodes.find(([id, , pub]) => pub && !(id in done));
  bar.textContent = '';
  if (next) {
    const a = document.createElement('a');
    a.className = 'btn pri'; a.href = `${L.lessonUrl}${next[0]}/`; a.textContent = fill(L.lCont!, { title: next[1] });
    bar.append(a);
    const el = document.getElementById(next[0]);
    if (el) { el.classList.add('next'); const p = document.createElement('span'); p.className = 'pill'; p.textContent = L.lNext!; el.append(p); }
  }
  const prog = document.createElement('div');
  prog.className = 'mprog';
  prog.innerHTML = `<span></span><span class="bar" role="progressbar" aria-valuemin="0"><i></i></span><a></a>`;
  const [c, b, man] = prog.children as any;
  c.textContent = fill(L.lCount!, { n: count, total });
  b.setAttribute('aria-valuemax', String(total)); b.setAttribute('aria-valuenow', String(count)); b.setAttribute('aria-label', L.lProgress!);
  b.firstChild.style.width = `${((count / total) * 100).toFixed(1)}%`;
  man.href = L.progressUrl!; man.textContent = manageText;
  bar.append(prog);
  // Save reminder: first after 3 lessons, then every 5 lessons after the last save.
  const backup = read<any>(KEYS.backup);
  const since = count - (backup?.count ?? 0);
  if ((!backup && count >= 3) || (backup && since >= 5)) {
    const s = document.createElement('span'); s.className = 'save';
    s.innerHTML = `${L.lBackup} <a href="${L.progressUrl}">${L.lBackupCta}</a>`;
    bar.append(s);
  }
}

render();
addEventListener('pageshow', render);
addEventListener('storage', render);
