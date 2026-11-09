// EEGLAB windows explained field by field. One YAML file per window in src/data/windows/.
// Field names and defaults come from the EEGLAB source (pop_*.m), not from memory.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { load as loadYaml } from 'js-yaml';

const DIR = 'src/data/windows';
let cache = null;

export function loadWindows() {
  if (cache) return cache;
  const all = new Map();
  for (const f of readdirSync(DIR).filter((n) => n.endsWith('.yaml')).sort()) {
    const w = loadYaml(readFileSync(`${DIR}/${f}`, 'utf8'));
    if (w.id !== f.replace(/\.yaml$/, '')) throw new Error(`windows/${f}: id must match the file name`);
    for (const k of ['title', 'menu', 'func', 'source', 'intro', 'fields']) {
      if (w[k] === undefined) throw new Error(`windows/${f}: missing ${k}`);
    }
    const keys = new Set();
    for (const fl of w.fields) {
      if (!fl.key || !fl.label || !fl.ar || !fl.en) throw new Error(`windows/${f}: field needs key, label, ar, en`);
      if (keys.has(fl.key)) throw new Error(`windows/${f}: duplicate key ${fl.key}`);
      keys.add(fl.key);
    }
    all.set(w.id, w);
  }
  cache = all;
  return cache;
}

// Real screenshot of the window, if tonight's capture has been added: assets-src/lessons/windows/<shot>.webp|png
export function windowShot(w) {
  const name = w.shot ?? w.id;
  for (const ext of ['webp', 'png']) {
    const file = `windows/${name}.${ext}`;
    const path = `assets-src/lessons/${file}`;
    if (existsSync(path)) return { file, ...imageSize(readFileSync(path)) };
  }
  return null;
}

function imageSize(b) {
  // PNG: IHDR width/height at bytes 16..23
  if (b[0] === 0x89 && b.toString('ascii', 1, 4) === 'PNG') return { width: b.readUInt32BE(16), height: b.readUInt32BE(20) };
  // WebP: VP8 / VP8L / VP8X
  if (b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP') {
    const kind = b.toString('ascii', 12, 16);
    if (kind === 'VP8X') return { width: 1 + b.readUIntLE(24, 3), height: 1 + b.readUIntLE(27, 3) };
    if (kind === 'VP8L') {
      const n = b.readUInt32LE(21);
      return { width: (n & 0x3fff) + 1, height: ((n >> 14) & 0x3fff) + 1 };
    }
    if (kind === 'VP8 ') return { width: b.readUInt16LE(26) & 0x3fff, height: b.readUInt16LE(28) & 0x3fff };
  }
  return { width: 720, height: 480 };
}
