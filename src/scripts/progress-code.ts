// Short progress code: version + bitset of completed lessons and passed quizzes, base32 (Crockford),
// with two check chars (weighted sum mod 1021, a prime, so any single changed character is detected).
const ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const VERSION = 1;
const checksum = (raw: string) => {
  const m = [...raw].reduce((a, c, i) => (a + ALPHABET.indexOf(c) * (i + 1)) % 1021, 0);
  return ALPHABET[m >> 5] + ALPHABET[m & 31];
};

const STATIONS = 11; // bits 0-10: passed station quizzes; bit 11 + (n - 1): lesson with permanent slot n

// slots: Map slug -> permanent slot number (1-based, append-only, never reused).
export function encode(doneSlugs: Iterable<string>, passedStations: Iterable<number>, slots: Map<string, number>): string {
  let bits = 0n;
  for (const st of passedStations) bits |= 1n << BigInt(st);
  for (const s of doneSlugs) { const n = slots.get(s); if (n) bits |= 1n << BigInt(STATIONS + n - 1); }
  const body: string[] = [];
  let v = bits;
  do { body.unshift(ALPHABET[Number(v & 31n)]); v >>= 5n; } while (v > 0n);
  const raw = ALPHABET[VERSION] + body.join('');
  return (raw + checksum(raw)).match(/.{1,4}/g)!.join('-');
}

export function decode(code: string, slots: Map<string, number>): { done: string[]; passed: number[] } {
  // Arabic-Indic and Persian digits are common on Arabic keyboards; Arabic letters mean the wrong keyboard layout.
  const ascii = code.replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660)).replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x06F0));
  if (/[ء-ي]/.test(ascii)) throw new Error('arabic-letters');
  const s = ascii.toUpperCase().replace(/[^0-9A-Z]/g, '').replace(/O/g, '0').replace(/[IL]/g, '1');
  if (s.length < 4) throw new Error('short');
  const raw = s.slice(0, -2), check = s.slice(-2);
  if ([...raw].some((c) => !ALPHABET.includes(c))) throw new Error('chars');
  if (check !== checksum(raw)) throw new Error('checksum');
  if (ALPHABET.indexOf(raw[0]) !== VERSION) throw new Error('version');
  let bits = 0n;
  for (const c of raw.slice(1)) bits = (bits << 5n) | BigInt(ALPHABET.indexOf(c));
  const bySlot = new Map([...slots].map(([k, n]) => [n, k]));
  const done: string[] = [], passed: number[] = [];
  for (let i = 0; bits >> BigInt(i); i++) {
    if (!((bits >> BigInt(i)) & 1n)) continue;
    if (i < STATIONS) passed.push(i);
    else { const slug = bySlot.get(i - STATIONS + 1); if (slug) done.push(slug); }
  }
  return { done, passed };
}
