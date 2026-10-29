// Key pages load without script errors or content-security-policy violations.
import { chromium } from 'playwright';
import { serve } from '../serve.mjs';

const PAGES = ['/', '/en/', '/lesson/filtering/', '/lesson/rereferencing/', '/lesson/epoch-rejection/', '/lesson/filtering/card/', '/station/03/', '/ica-game/', '/en/ica-game/', '/search/?q=filter', '/en/search/?q=ica', '/progress/', '/about/', '/references/', '/plugins/', '/map/', '/404.html'];
const { server, url } = await serve();
const browser = await chromium.launch();
let bad = 0;
for (const path of PAGES) {
  const page = await browser.newPage();
  const errors = [];
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text().slice(0, 200)));
  page.on('pageerror', (e) => errors.push(e.message.slice(0, 200)));
  await page.goto(url + path, { waitUntil: 'networkidle' });
  await page.waitForTimeout(300);
  for (const e of errors) console.log(`${path}: ${e}`);
  bad += errors.length;
  await page.close();
}
await browser.close();
server.close();
if (bad) { console.log(`console: ${bad} error(s)`); process.exit(1); }
console.log(`console: ${PAGES.length} pages clean`);
