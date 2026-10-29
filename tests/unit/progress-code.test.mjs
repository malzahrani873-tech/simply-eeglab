import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { encode, decode } from '../../src/scripts/progress-code.ts';

const slugs = readFileSync('src/data/progress-slots.lock', 'utf8').split('\n').map((s) => s.trim()).filter((s) => s && !s.startsWith('#'));
const slots = new Map(slugs.map((s, i) => [s, i + 1]));

test('round trip on random progress', () => {
  for (let k = 0; k < 500; k++) {
    const done = slugs.filter(() => Math.random() < 0.4);
    const passed = [...Array(11).keys()].filter(() => Math.random() < 0.3);
    const r = decode(encode(done, passed, slots), slots);
    assert.deepEqual(new Set(r.done), new Set(done));
    assert.deepEqual(new Set(r.passed), new Set(passed));
  }
});

test('every single-character error is caught', () => {
  const code = encode(slugs.slice(0, 30), [0, 3], slots);
  const A = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  const plain = code.replace(/-/g, '');
  for (let i = 0; i < plain.length; i++) for (const c of A) {
    if (c === plain[i]) continue;
    assert.throws(() => decode(plain.slice(0, i) + c + plain.slice(i + 1), slots));
  }
});

test('lenient input: case, separators, Arabic digits, O and I', () => {
  const code = encode(['filtering', 'eeg-origin'], [1], slots);
  const ar = code.replace(/[0-9]/g, (d) => String.fromCharCode(0x0660 + Number(d)));
  assert.deepEqual(decode(ar.toLowerCase().replace(/-/g, ' '), slots).passed, [1]);
  assert.throws(() => decode('ابجد', slots), /arabic-letters/);
});

test('longest code stays at 18 characters', () => {
  assert.equal(encode(slugs, [...Array(11).keys()], slots).replace(/-/g, '').length, 18);
});
