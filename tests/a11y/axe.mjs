// axe on one page of every type, both languages, light and dark. Fails on serious or critical issues.
import { chromium } from 'playwright';
import { AxeBuilder } from '@axe-core/playwright';
import { serve } from '../serve.mjs';

const PAGES = ['', 'station/03/', 'lesson/filtering/', 'lesson/filtering/card/', 'lesson/epoch-rejection/', 'ica-game/', 'search/', 'progress/', 'about/', 'references/', 'plugins/', 'map/', '404.html'];
const { server, url } = await serve();
const browser = await chromium.launch();
let bad = 0;
for (const scheme of ['light', 'dark']) {
  // bypassCSP lets the test inject axe and its helper style; the pages themselves are unchanged.
  const ctx = await browser.newContext({ colorScheme: scheme, viewport: { width: 390, height: 844 }, bypassCSP: true });
  const page = await ctx.newPage();
  for (const lang of ['', 'en/']) {
    for (const p of PAGES) {
      const path = `/${lang}${p}`;
      await page.goto(url + path, { waitUntil: 'networkidle' });
      // The sticky tab bar covers whatever sits at the bottom of the viewport; in use the page scrolls
      // past it. Pin it in the flow so target-size measures the controls themselves (the bar is still checked).
      await page.addStyleTag({ content: '.tabs,.backnote{position:static!important}' });
      const { violations } = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
      const serious = violations.filter((v) => v.impact === 'serious' || v.impact === 'critical');
      for (const v of serious) {
        bad++;
        console.log(`${scheme} ${path}: ${v.id} (${v.impact}) ${v.nodes.slice(0, 3).map((n) => n.target.join(' ')).join(' | ')}`);
      }
    }
  }
  await ctx.close();
}
await browser.close();
server.close();
if (bad) { console.log(`axe: ${bad} serious or critical issue(s)`); process.exit(1); }
console.log('axe: no serious or critical issues');
