// Every reference card prints on at most two A4 pages, in both languages.
import { readdirSync } from 'node:fs';
import { chromium } from 'playwright';
import { serve } from '../serve.mjs';

const { server, url } = await serve('dist');
const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage();
const bad = [];
let n = 0;
for (const lang of ['', 'en/']) {
  for (const slug of readdirSync(`dist/${lang}lesson`)) {
    await page.goto(`${url}/${lang}lesson/${slug}/card/`);
    const pdf = await page.pdf({ format: 'A4', preferCSSPageSize: true });
    const pages = (pdf.toString('latin1').match(/\/Type\s*\/Page[^s]/g) ?? []).length;
    n++;
    if (pages > 2) bad.push(`${lang}${slug}: ${pages} pages`);
  }
}
await browser.close();
server.close();
if (bad.length) { console.error(`cards over two A4 pages:\n  ${bad.join('\n  ')}`); process.exit(1); }
console.log(`cards: ${n} within two A4 pages`);
