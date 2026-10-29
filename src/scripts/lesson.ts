import { isDone, markDone, unmark, setLast, storageOk } from './progress';

const art = document.querySelector<HTMLElement>('[data-lesson]');
const slug = art?.dataset.lesson ?? '';
if (slug && storageOk()) setLast(slug);

// Copy buttons for code blocks and the Methods paragraph.
async function copyText(text: string) {
  try { await navigator.clipboard.writeText(text); return true; } catch {
    const ta = document.createElement('textarea'); ta.value = text; document.body.append(ta); ta.select();
    let ok = false; try { ok = document.execCommand('copy'); } catch {} ta.remove(); return ok;
  }
}
for (const b of document.querySelectorAll<HTMLButtonElement>('[data-copy], [data-copy-prev]')) {
  b.hidden = false;
  const label = b.querySelector('span')!;
  const orig = label.textContent;
  b.addEventListener('click', async () => {
    const src = b.hasAttribute('data-copy-prev') ? b.closest('.fb, .print-copy, article')!.querySelector('blockquote') : b.closest('.code')!.querySelector('pre');
    const ok = await copyText((src?.textContent ?? '').trim());
    label.textContent = ok ? b.dataset.done ?? '✓' : b.dataset.fail ?? '';
    setTimeout(() => (label.textContent = orig), 1800);
  });
}

// "Mark as complete" with undo; announced through the status line.
const box = document.querySelector<HTMLElement>('[data-lesson-complete]');
if (box) {
  const btn = box.querySelector<HTMLButtonElement>('.done-btn')!;
  const msg = box.querySelector<HTMLElement>('.done-msg')!;
  const label = btn.querySelector('span')!;
  const badge = document.querySelector<HTMLElement>('.done-badge');
  const saved = box.querySelector<HTMLTemplateElement>('[data-saved]')!.innerHTML;
  const undo = box.querySelector<HTMLTemplateElement>('[data-undo]')!.innerHTML;
  const render = (announce = false) => {
    const d = isDone(slug);
    btn.setAttribute('aria-pressed', String(d));
    label.textContent = d ? btn.dataset.lDone! : btn.dataset.lMark!;
    if (badge) badge.hidden = !d;
    msg.textContent = '';
    if (d && announce) {
      msg.append(saved + ' ');
      const u = document.createElement('button'); u.type = 'button'; u.textContent = undo;
      u.addEventListener('click', () => { unmark(slug); render(); btn.focus(); });
      msg.append(u);
    }
  };
  if (storageOk()) {
    btn.hidden = false;
    btn.addEventListener('click', () => {
      if (isDone(slug)) { unmark(slug); render(); return; }
      markDone(slug); render(true);
      document.getElementById('next-lesson')?.focus({ preventScroll: false });
    });
    render();
    addEventListener('pageshow', () => render());
    addEventListener('storage', () => render());
  } else box.querySelector<HTMLElement>('.done-na')!.hidden = false;
}

// "Open all" / "Close all" for the folded sections.
const all = document.querySelector<HTMLButtonElement>('[data-open-all]');
if (all) {
  // Every fold in the lesson body, inner note folds included; the starting-point script toggle is separate.
  const folds = () => [...document.querySelectorAll<HTMLDetailsElement>('article details')].filter((d) => !d.closest('.start1'));
  const sync = () => { const open = folds().every((d) => d.open); all.textContent = open ? all.dataset.close! : all.dataset.open!; };
  all.hidden = false;
  all.addEventListener('click', () => { const open = !folds().every((d) => d.open); folds().forEach((d) => (d.open = open)); sync(); });
  document.addEventListener('toggle', sync, true);
}

// A link to a folded section (#gui, #verify…) opens the fold before the page scrolls to it.
const openTarget = () => {
  const el = location.hash.length > 1 ? document.getElementById(decodeURIComponent(location.hash.slice(1))) : null;
  if (el instanceof HTMLDetailsElement && !el.open) { el.open = true; el.scrollIntoView(); }
};
addEventListener('hashchange', openTarget);
openTarget();
document.addEventListener('click', (e) => {
  const a = (e.target as Element).closest?.('a[href^="#"]');
  if (a) setTimeout(openTarget);
});
