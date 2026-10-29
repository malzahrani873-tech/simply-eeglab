// Lock files are append-only: every line on the base branch must still be there, in the same place.
import { execFileSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';

const base = process.argv[2] ?? 'origin/main';
const locks = ['src/data/progress-slots.lock', 'src/data/ica-daily.lock'];
let bad = 0;
for (const f of locks) {
  if (!existsSync(f)) continue;
  let old;
  try {
    old = execFileSync('git', ['show', `${base}:${f}`], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
  } catch {
    console.log(`${f}: not on ${base} yet, nothing to compare`);
    continue;
  }
  const a = old.split('\n').filter(Boolean);
  const b = readFileSync(f, 'utf8').split('\n').filter(Boolean);
  a.forEach((line, i) => {
    if (b[i] !== line) { bad++; console.log(`${f}:${i + 1}: "${line}" was changed, moved or removed; only append new lines`); }
  });
}
if (bad) process.exit(1);
console.log('lock files: append-only');
