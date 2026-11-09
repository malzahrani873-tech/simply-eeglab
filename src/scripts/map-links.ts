// Decorative connector lines on wide screens: one curve from each station box to each of its lessons.
// Start points are spread down the box edge in lesson order, so the curves fan out and never cross.
// Purely visual; the station and lesson order are in the list itself.
const rm = document.getElementById('rm')!;
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
  const box = (el: Element) => { const r = el.getBoundingClientRect(); return { l: r.left - R.left, r: r.right - R.left, t: r.top - R.top, b: r.bottom - R.top }; };
  let out = '';
  for (const rs of rm.querySelectorAll('.rs')) {
    const sb = box(rs.querySelector('.sbox')!);
    const nodes = [...rs.querySelectorAll<HTMLElement>('.node')];
    const step = (sb.b - sb.t) / (nodes.length + 1);
    nodes.forEach((n, i) => {
      const r = box(n), right = r.l > sb.r;
      const x1 = right ? sb.r : sb.l, x2 = right ? r.l : r.r, mx = (x1 + x2) / 2;
      const y1 = sb.t + step * (i + 1), y2 = (r.t + r.b) / 2;
      const cls = [n.classList.contains('soon') && 'soon', n.classList.contains('done-n') && 'done', n.id === hl && 'hl'].filter(Boolean).join(' ');
      out += `<path${cls ? ` class="${cls}"` : ''} d="M${x1.toFixed(1)} ${y1.toFixed(1)}C${mx.toFixed(1)} ${y1.toFixed(1)} ${mx.toFixed(1)} ${y2.toFixed(1)} ${x2.toFixed(1)} ${y2.toFixed(1)}"/>`;
    });
  }
  svg.innerHTML = out;
}
const queue = () => { if (!raf) raf = requestAnimationFrame(draw); };
const setHl = (id: string | null) => { if (id !== hl) { hl = id; queue(); } };
const nodeOf = (e: Event) => (e.target as Element).closest<HTMLElement>('.node');
rm.addEventListener('pointerover', (e) => setHl(nodeOf(e)?.id ?? null));
rm.addEventListener('pointerleave', () => setHl(null));
rm.addEventListener('focusin', (e) => setHl(nodeOf(e)?.id ?? null));
rm.addEventListener('focusout', () => setHl(null));
addEventListener('map-changed', queue);
new ResizeObserver(queue).observe(rm);
wide.addEventListener('change', queue);
