// Decorative connector lines on wide screens: station to each lesson, and on hover or focus
// the lessons the current one builds on. Purely visual; the same facts are in each node's label.
const rm = document.getElementById('rm')!;
const pre: Record<string, string[]> = JSON.parse(rm.dataset.pre ?? '{}');
const wide = matchMedia('(min-width: 900px)');
const NS = 'http://www.w3.org/2000/svg';
const svg = document.createElementNS(NS, 'svg');
svg.classList.add('links'); svg.setAttribute('aria-hidden', 'true');
rm.prepend(svg);
let hl: string | null = null, raf = 0;

function draw() {
  raf = 0;
  if (!wide.matches || getComputedStyle(svg).display === 'none') { svg.replaceChildren(); return; }
  const R = rm.getBoundingClientRect();
  const box = (el: Element) => { const r = el.getBoundingClientRect(); return { l: r.left - R.left, r: r.right - R.left, t: r.top - R.top, b: r.bottom - R.top, cy: (r.top + r.bottom) / 2 - R.top, cx: (r.left + r.right) / 2 - R.left }; };
  let d = '', dd = '', h = '';
  for (const rs of rm.querySelectorAll('.rs')) {
    const sb = box(rs.querySelector('.sbox')!);
    for (const n of rs.querySelectorAll<HTMLElement>('.node')) {
      if (!n.offsetParent) continue;
      const r = box(n), right = r.l > sb.r;
      const x1 = right ? sb.r : sb.l, x2 = right ? r.l : r.r, mx = (x1 + x2) / 2;
      const p = `M${x1} ${sb.cy}C${mx} ${sb.cy} ${mx} ${r.cy} ${x2} ${r.cy}`;
      if (n.classList.contains('c')) d += p; else dd += p;
    }
  }
  if (hl) {
    const tg = document.getElementById(hl);
    if (tg?.offsetParent) {
      const tr = box(tg);
      for (const id of pre[hl] ?? []) {
        const s = document.getElementById(id);
        if (!s?.offsetParent) continue;
        const sr = box(s), dy = Math.max(30, (tr.t - sr.b) / 2);
        h += `M${sr.cx} ${sr.b}C${sr.cx} ${sr.b + dy} ${tr.cx} ${tr.t - dy} ${tr.cx} ${tr.t}`;
      }
    }
  }
  svg.innerHTML = `<path d="${d}"/><path class="dash" d="${dd}"/><path class="hl" d="${h}"/>`;
}
const queue = () => { if (!raf) raf = requestAnimationFrame(draw); };
function setHl(id: string | null) {
  if (id === hl) return;
  rm.querySelectorAll('.node.pre,.node.cur').forEach((n) => n.classList.remove('pre', 'cur'));
  hl = id;
  if (id && wide.matches) {
    document.getElementById(id)?.classList.add('cur');
    for (const p of pre[id] ?? []) document.getElementById(p)?.classList.add('pre');
  }
  queue();
}
rm.addEventListener('pointerover', (e) => { const n = (e.target as Element).closest<HTMLElement>('.node'); if (n) setHl(n.id); });
rm.addEventListener('pointerleave', () => setHl(null));
rm.addEventListener('focusin', (e) => { const n = (e.target as Element).closest<HTMLElement>('.node'); if (n) setHl(n.id); });
rm.addEventListener('focusout', () => setHl(null));
new ResizeObserver(queue).observe(rm);
wide.addEventListener('change', queue);
