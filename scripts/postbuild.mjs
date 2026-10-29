// Static hosts look for 404.html in the nearest folder, so the English 404 page must be en/404.html.
import { existsSync, renameSync, rmSync } from 'node:fs';

const from = 'dist/en/404/index.html';
if (existsSync(from)) {
  renameSync(from, 'dist/en/404.html');
  rmSync('dist/en/404', { recursive: true });
}
