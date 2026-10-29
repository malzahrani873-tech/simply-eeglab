// make_og.mjs - social share image 1200x630 in two versions (ar and en), in the site's visual identity.
// Needs Playwright and the Vazirmatn and JetBrains Mono fonts installed locally.
// Usage: node tools/og/make_og.mjs <output folder>
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';

const out = process.argv[2] || 'public/og';
mkdirSync(out, { recursive: true });

// Pen trace: starts noisy and settles
function trace(width, height) {
  const pts = [];
  let seed = 7;
  const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647) - 0.5;
  for (let x = 0; x <= width; x += 4) {
    const k = x / width;
    const calm = Math.max(0, 1 - k * 1.6);
    const y = height / 2 + Math.sin(x / 9) * (3 + 10 * calm) + rnd() * 26 * calm * calm;
    pts.push(`${x},${y.toFixed(1)}`);
  }
  return `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><polyline points="${pts.join(' ')}" fill="none" stroke="#C8102E" stroke-width="3" stroke-linejoin="round"/></svg>`;
}

// 10-20 head mark from icons/eeg-head-1020.svg, with the central electrode Cz in the trace colour
const head = `<svg width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="#111114" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="13" r="8.5"/><path d="M10 4.8 L12 2.5 L14 4.8"/>
  <path d="M3.5 11 C2.3 12 2.3 14 3.5 15"/><path d="M20.5 11 C21.7 12 21.7 14 20.5 15"/>
  <g fill="#111114" stroke="none"><circle cx="12" cy="8.5" r="1"/><circle cx="7.5" cy="13" r="1"/>
  <circle cx="16.5" cy="13" r="1"/><circle cx="12" cy="17.5" r="1"/></g>
  <circle cx="12" cy="13" r="1" fill="#C8102E" stroke="none"/></svg>`;

const copy = {
  ar: { dir: 'rtl', lang: 'ar', mark: '<bdi lang="en">EEGLAB</bdi> ببساطة',
        line: 'خريطة طريق عربية لتعلّم EEGLAB خطوة بخطوة', sub: 'من استيراد البيانات إلى ICA و ERP' },
  en: { dir: 'ltr', lang: 'en', mark: 'Simply EEGLAB',
        line: 'A step-by-step roadmap for learning EEGLAB', sub: 'From importing data to ICA and ERPs' },
};

const page = (c) => `<!doctype html><html lang="${c.lang}" dir="${c.dir}"><head><meta charset="utf-8"><style>
  html,body{margin:0;width:1200px;height:630px}
  body{background:#F2F2F7;font-family:Vazirmatn,sans-serif;color:#111114;position:relative;overflow:hidden;
    background-image:linear-gradient(#D3D8E3 1px,transparent 1px),linear-gradient(90deg,#D3D8E3 1px,transparent 1px),
      linear-gradient(#E3E6EE 1px,transparent 1px),linear-gradient(90deg,#E3E6EE 1px,transparent 1px);
    background-size:125px 125px,125px 125px,25px 25px,25px 25px}
  .card{position:absolute;inset:72px 80px;background:#FFFFFF;border-radius:12px;border:1px solid #C6C6C8;
    padding:64px 72px;box-sizing:border-box;display:flex;flex-direction:column;justify-content:center}
  .brand{display:flex;align-items:center;gap:28px}
  .mark{font-weight:700;font-size:76px;line-height:1.1;letter-spacing:${c.lang === 'en' ? '-0.5px' : '0'}}
  .line{font-size:36px;font-weight:600;margin-top:34px}
  .sub{font-size:28px;color:#5C5C66;margin-top:12px}
  .trace{margin-top:30px}
  [dir=rtl] .trace svg{transform:scaleX(-1)}  /* the trace settles in the reading direction */
</style></head><body><div class="card">
  <div class="brand">${head}<div class="mark">${c.mark}</div></div>
  <div class="trace">${trace(1040 - 144, 56)}</div>
  <div class="line">${c.line}</div><div class="sub">${c.sub}</div>
</div></body></html>`;

const browser = await chromium.launch();
const p = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
for (const [k, c] of Object.entries(copy)) {
  await p.setContent(page(c));
  await p.evaluate(() => document.fonts.ready);
  const file = join(out, k === 'ar' ? 'default.png' : 'default-en.png');
  await p.screenshot({ path: file });
  console.log(file);
}
await browser.close();
