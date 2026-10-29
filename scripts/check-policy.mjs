// Content policy scan. Terms come from the POLICY_TERMS environment variable (one per line),
// so the list itself never lives in the repository. Only file and line are reported.
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createHash } from 'node:crypto';

const terms = (process.env.POLICY_TERMS ?? '').split('\n').map((t) => t.trim()).filter(Boolean);
if (!terms.length) {
  console.log('content policy: no terms configured, skipped');
  process.exit(0);
}
const esc = (t) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const re = new RegExp(`(?<![\\p{L}\\p{N}_])(?:${terms.map(esc).join('|')})(?![\\p{L}\\p{N}_])`, 'iu');
// Provenance records (C2PA) are never stripped or edited. Images listed in c2pa-exceptions.txt keep
// theirs and are reported only; a record anywhere else that matches a term fails the check.
const exceptions = readFileSync('c2pa-exceptions.txt', 'utf8').split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
const excepted = (f) => exceptions.some((e) => (e.endsWith('/') ? f.startsWith(e) : f === e));
const records = (buf) => {
  const s = buf.toString('latin1');
  const out = [...s.matchAll(/<c2pa:manifest>([A-Za-z0-9+/=\s]+)<\/c2pa:manifest>/g)].map((m) => Buffer.from(m[1], 'base64').toString('latin1'));
  if (!out.length && /c2pa/.test(s) && buf.subarray(0, 8000).includes(0)) out.push(s);
  return out;
};
const digest = (s) => createHash('sha256').update(s).digest('hex');

let failures = 0;
let notes = 0;
const scanText = (label, text) => {
  text.split('\n').forEach((line, i) => {
    if (!re.test(line)) return;
    if (excepted(label)) { notes++; console.log(`  note  ${label}:${i + 1}`); }
    else { failures++; console.log(`  match ${label}:${i + 1}`); }
  });
};
const isText = (buf) => !buf.subarray(0, 8000).includes(0);
// Records of excepted files, so their copies in dist/ are recognised too (files in the repo must be listed).
const allowed = new Set();
const scanRecords = (label, buf, own) => {
  for (const r of records(buf)) {
    if (!re.test(r)) continue;
    if (own === true || (own === 'dist' && allowed.has(digest(r)))) { notes++; console.log(`  note  ${label} (provenance record, kept)`); }
    else { failures++; console.log(`  match ${label} (provenance record; not in c2pa-exceptions.txt)`); }
  }
};

const tracked = execFileSync('git', ['ls-files', '-z'], { encoding: 'utf8' }).split('\0').filter(Boolean);
for (const f of tracked) if (excepted(f) && existsSync(f)) for (const r of records(readFileSync(f))) allowed.add(digest(r));
for (const f of tracked) {
  scanText(f, f); // file names count too
  if (!existsSync(f)) continue;
  const buf = readFileSync(f);
  if (isText(buf)) scanText(f, buf.toString('utf8'));
  scanRecords(f, buf, excepted(f));
}

const walk = (dir) => readdirSync(dir).flatMap((n) => {
  const p = join(dir, n);
  return statSync(p).isDirectory() ? walk(p) : [p];
});
if (existsSync('dist')) {
  for (const f of walk('dist')) {
    const buf = readFileSync(f);
    if (isText(buf)) scanText(f, buf.toString('utf8'));
    scanRecords(f, buf, 'dist');
  }
}

const range = process.env.POLICY_RANGE; // e.g. origin/main..HEAD
let log = '';
try {
  log = execFileSync('git', ['log', '--format=%H%n%B%n%x00', ...(range ? [range] : [])], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
} catch {
  // A repository with no commits yet has no messages to check.
}
for (const entry of log.split('\0').map((e) => e.trim()).filter(Boolean)) {
  const [sha, ...body] = entry.split('\n');
  scanText(`commit ${sha.slice(0, 10)}`, body.join('\n'));
}
for (const name of ['PR_TITLE', 'PR_BODY', 'BRANCH_NAME']) {
  if (process.env[name]) scanText(name.toLowerCase().replace('_', ' '), process.env[name]);
}

if (failures) {
  console.log(`content policy: ${failures} match(es)`);
  process.exit(1);
}
console.log(`content policy: clean${notes ? ` (${notes} note(s) in provenance metadata, kept as is)` : ''}`);
