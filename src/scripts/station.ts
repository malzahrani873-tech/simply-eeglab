// Station page: done marks, the station counter and the "completed" badge.
import { all } from './progress';

const head = document.querySelector<HTMLElement>('.shead');
const rows = [...document.querySelectorAll<HTMLElement>('.srow')];
function render() {
  const done = all();
  let n = 0;
  rows.forEach((r) => { const d = r.dataset.id! in done; if (d) n++; r.querySelector<HTMLElement>('.done')!.hidden = !d; r.classList.toggle('is-done', d); });
  const prog = head?.querySelector<HTMLElement>('.st-prog');
  if (prog) { prog.textContent = ' · ' + prog.dataset.l!.replace('{n}', String(n)).replace('{total}', String(rows.length)); prog.hidden = false; }
  const badge = head?.querySelector<HTMLElement>('.st-done');
  if (badge) badge.hidden = n < rows.length;
}
render();
addEventListener('pageshow', render);
addEventListener('storage', render);
