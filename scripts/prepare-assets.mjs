// Copies source images into public/ before a build. Files are copied byte for byte
// so the provenance metadata inside them is kept.
import { cpSync, mkdirSync, rmSync } from 'node:fs';


rmSync('public/img/lessons', { recursive: true, force: true });
mkdirSync('public/img', { recursive: true });
cpSync('assets-src/lessons', 'public/img/lessons', { recursive: true });

// Images of the removed ICA game, left over from older builds.
rmSync('public/ica', { recursive: true, force: true });
console.log('assets prepared');
