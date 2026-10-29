// Icon names used across the site, mapped to Phosphor Regular files (single-path, 256 grid).
import { readFileSync } from 'node:fs';

export const ICON_FILES = {
  map: 'map-trifold', play: 'play-circle', wave: 'wave-sine', search: 'magnifying-glass', more: 'dots-three',
  moon: 'moon', sun: 'sun', chevStart: 'caret-left', chevEnd: 'caret-right', down: 'caret-down', check: 'check',
  copy: 'copy', warn: 'warning-circle', info: 'info', flag: 'flag', chat: 'chat-circle', heart: 'heart',
  list: 'list-bullets', plug: 'plug', book: 'book-open', chart: 'chart-bar', about: 'user-circle', img: 'image',
  steps: 'list-checks', code: 'code', file: 'file-text', books: 'books', close: 'x', undo: 'arrow-counter-clockwise',
  download: 'download-simple', upload: 'upload-simple', link: 'link', home: 'house', game: 'game-controller',
  idea: 'lightbulb', print: 'printer', cap: 'graduation-cap', help: 'question',
  ok: 'check-circle', bad: 'x-circle', up: 'arrow-up', dn: 'arrow-down',
};

const cache = new Map();
export function iconPath(name) {
  if (!cache.has(name)) {
    const file = ICON_FILES[name];
    if (!file) throw new Error(`unknown icon: ${name}`);
    const svg = readFileSync(`src/icons/phosphor/${file}.svg`, 'utf8');
    cache.set(name, svg.match(/ d="([^"]+)"/)[1]);
  }
  return cache.get(name);
}
