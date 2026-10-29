// Copies source images into public/ before a build. Files are copied byte for byte
// so the provenance metadata inside them is kept.
import { cpSync, existsSync, mkdirSync, rmSync } from 'node:fs';

const production = process.env.CONTENT_MODE === 'production' || (process.env.CF_PAGES === '1' && process.env.CF_PAGES_BRANCH === 'main');

rmSync('public/img/lessons', { recursive: true, force: true });
mkdirSync('public/img', { recursive: true });
cpSync('assets-src/lessons', 'public/img/lessons', { recursive: true });

// ICA game images: the final set when present; previews fall back to the test fixture.
rmSync('public/ica', { recursive: true, force: true });
if (existsSync('assets-src/ica')) cpSync('assets-src/ica', 'public/ica', { recursive: true });
else if (!production) cpSync('tests/fixtures/ica/img', 'public/ica', { recursive: true });
console.log('assets prepared');
