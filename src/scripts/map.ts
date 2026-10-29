import { all, read, KEYS, storageOk } from './progress';

const rm = document.getElementById('rm')!;
const bar = document.getElementById('mbar')!;
const L = bar.dataset;
const nodes: [string, number, string, number][] = JSON.parse(rm.dataset.map!);
const manageText = bar.querySelector('.mmanage')?.textContent ?? '';
const fill = (s: string, v: Record<string, string | number>) => s.replace(/\{(\w+)\}/g, (_, k) => String(v[k] ?? ''));

// Filter: ?level=all|core|core-rec. Without JS every level shows.
function applyFilter() {
  const lv = new URLSearchParams(location.search).get('level');
  const level = lv === 'core' || lv === 'core-rec' ? lv : 'all';
  rm.dataset.level = level;
  document.querySelectorAll<HTMLElement>('#flt [data-f]').forEach((a) => a.setAttribute('aria-current', String(a.dataset.f === level)));
  const shown = [...rm.querySelectorAll<HTMLElement>('.node')].filter((n) => n.offsetParent !== null).length;
  const out = document.getElementById('flt-count')!;
  out.textContent = level === 'all' ? '' : fill(out.dataset.l!, { n: shown, total: nodes.length });
}

function render() {
  if (!storageOk()) return;
  const done = all();
  const total = nodes.length;
  const count = nodes.filter(([id]) => id in done).length;
  const cores = nodes.filter((n) => n[1]);
  const coreDone = cores.filter(([id]) => id in done).length;
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
    if (count) m.textContent = fill(L.lSt!, { n: ids.filter((i) => i in done).length, total: ids.length });
  }
  if (!count) return;
  // Continue: the last opened lesson, else the first core lesson not done.
  const last = read<any>(KEYS.last)?.slug;
  const lastNode = nodes.find(([id, , , pub]) => id === last && pub && !(id in done));
  const next = lastNode ?? cores.find(([id, , , pub]) => pub && !(id in done));
  bar.textContent = '';
  if (next) {
    const a = document.createElement('a');
    a.className = 'btn pri'; a.href = `${L.lessonUrl}${next[0]}/`; a.textContent = fill(L.lCont!, { title: next[2] });
    bar.append(a);
    const el = document.getElementById(next[0]);
    if (el) { el.classList.add('next'); const p = document.createElement('span'); p.className = 'pill'; p.textContent = L.lNext!; el.append(p); }
  }
  const prog = document.createElement('div');
  prog.className = 'mprog';
  prog.innerHTML = `<span></span><span class="bar" role="progressbar" aria-valuemin="0"><i></i></span><span class="muted"></span><a></a>`;
  const [c, b, cc, man] = prog.children as any;
  c.textContent = fill(L.lCount!, { n: count, total });
  b.setAttribute('aria-valuemax', String(total)); b.setAttribute('aria-valuenow', String(count)); b.setAttribute('aria-label', L.lProgress!);
  b.firstChild.style.width = `${((count / total) * 100).toFixed(1)}%`;
  cc.textContent = fill(L.lCore!, { n: coreDone, total: cores.length });
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

applyFilter();
render();
addEventListener('pageshow', render);
addEventListener('storage', render);
