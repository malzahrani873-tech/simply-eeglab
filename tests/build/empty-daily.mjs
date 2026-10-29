// Builds the site with an empty component-of-the-day list and checks that the feature disappears
// cleanly: no section, no data files, no links to it, and the game page still loads without errors.
import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, copyFileSync, existsSync, readFileSync, readdirSync, statSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { chromium } from 'playwright';
import { serve } from '../serve.mjs';

const work = mkdtempSync(join(tmpdir(), 'ica-empty-'));
const data = join(work, 'data');
const out = join(work, 'dist');
execFileSync('mkdir', ['-p', data]);
// The game cards whose images public/ica holds: the final set when present, else the fixture.
const game = existsSync('src/data/ica-game.items.json') ? 'src/data/ica-game.items.json' : 'tests/fixtures/ica/ica-game.items.json';
copyFileSync(game, join(data, 'ica-game.items.json'));
writeFileSync(join(data, 'ica-daily.items.json'), JSON.stringify({ v: 1, source: {}, classes: [], items: [] }) + '\n');

execFileSync('npx', ['astro', 'build', '--outDir', out], { env: { ...process.env, ICA_DATA_DIR: data }, stdio: ['ignore', 'ignore', 'inherit'] });

const fails = [];
const walk = (d) => readdirSync(d).flatMap((n) => (statSync(join(d, n)).isDirectory() ? walk(join(d, n)) : [join(d, n)]));
if (existsSync(join(out, 'ica-game/daily'))) fails.push('ica-game/daily/ was generated');
for (const f of walk(out).filter((f) => f.endsWith('.html'))) {
  const html = readFileSync(f, 'utf8');
  if (/id="daily"/.test(html)) fails.push(`${f}: daily section rendered`);
  if (/href="[^"]*#daily"/.test(html)) fails.push(`${f}: link to the daily section`);
  if (/ica-game\/daily\//.test(html)) fails.push(`${f}: reference to daily data`);
}
for (const p of ['ica-game/index.html', 'en/ica-game/index.html']) {
  if (!/id="game"/.test(readFileSync(join(out, p), 'utf8'))) fails.push(`${p}: game section missing`);
}

const { server, url } = await serve(out);
const browser = await chromium.launch();
for (const p of ['/ica-game/', '/en/ica-game/']) {
  const page = await browser.newPage();
  const errors = [];
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto(url + p, { waitUntil: 'networkidle' });
  if (!(await page.locator('#game').isVisible())) fails.push(`${p}: game not shown`);
  for (const e of errors) fails.push(`${p}: ${e.slice(0, 160)}`);
  await page.close();
}
await browser.close();
server.close();
rmSync(work, { recursive: true, force: true });

if (fails.length) { console.log(fails.join('\n')); process.exit(1); }
console.log('empty daily list: feature hidden cleanly');
