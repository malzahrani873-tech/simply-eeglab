// Map data loader shared by the site and the content checks. Plain JS so Node scripts can import it.
import { readFileSync } from 'node:fs';
import { load as loadYaml } from 'js-yaml';

const dataDir = 'src/data/';
const load = (f) => loadYaml(readFileSync(dataDir + f, 'utf8'));

export function loadRoadmap() {
  const stations = load('roadmap.yaml');
  const nodes = [];
  for (const s of stations) {
    s.nodes.forEach((n, i) => nodes.push({ ...n, station: s.station, order: i + 1 }));
  }
  const ids = nodes.map((n) => n.id);
  // next: core -> next core; other -> next in its station, else first core of a later station;
  // when no core node is left, the next node in order; last node -> null.
  nodes.forEach((n, i) => {
    if (n.next !== undefined) return;
    const later = nodes.slice(i + 1);
    let next;
    if (n.level === 'core') next = later.find((m) => m.level === 'core');
    else next = later.find((m) => m.station === n.station) ?? later.find((m) => m.level === 'core');
    next ??= later[0];
    n.next = next ? next.id : null;
  });
  const byId = new Map(nodes.map((n) => [n.id, n]));
  return { stations, nodes, ids, byId };
}

export const loadDatasets = () => load('datasets.yaml');

export function loadSlots() {
  const lines = readFileSync(dataDir + 'progress-slots.lock', 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);
  return lines;
}
