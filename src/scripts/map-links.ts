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

// Packing on wide screens: lessons alternate sides, so a station only has to clear the station above it
// and the lessons two stations up (same side). Rows are placed absolutely from measured heights;
// without JS, or on narrow screens, the list keeps its normal flow.
const GAP_STATION = 28, GAP_SIDE = 20;
let packedWidth = -1;
function pack() {
  const rows = [...rm.querySelectorAll<HTMLElement>('.rs')];
  if (!wide.matches) { rm.classList.remove('packed'); rm.style.height = ''; rows.forEach((r) => (r.style.top = '')); packedWidth = -1; return; }
  const w = rm.clientWidth;
  if (w === packedWidth) return;
  rm.classList.remove('packed'); rm.style.height = '';
  const m = rows.map((r) => {
    const top = r.getBoundingClientRect().top;
    const s = r.querySelector('.sbox')!.getBoundingClientRect(), l = r.querySelector('.cl')!.getBoundingClientRect();
    return { s: s.top - top, sb: s.bottom - top, l: l.top - top, lb: l.bottom - top, h: r.getBoundingClientRect().height };
  });
  const T: number[] = [];
  m.forEach((x, i) => {
    let y = 0;
    if (i > 0) y = Math.max(y, T[i - 1] + m[i - 1].sb + GAP_STATION - x.s);
    if (i > 1) y = Math.max(y, T[i - 2] + m[i - 2].lb + GAP_SIDE - x.l);
    T.push(y);
  });
  rows.forEach((r, i) => (r.style.top = `${T[i]}px`));
  rm.style.height = `${Math.max(...m.map((x, i) => T[i] + x.h))}px`;
  rm.classList.add('packed');
  packedWidth = rm.clientWidth;
}

function draw() {
  raf = 0;
  pack();
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
addEventListener('map-changed', () => { packedWidth = -1; queue(); });
document.fonts?.ready.then(() => { packedWidth = -1; queue(); });
new ResizeObserver(queue).observe(rm);
wide.addEventListener('change', queue);
