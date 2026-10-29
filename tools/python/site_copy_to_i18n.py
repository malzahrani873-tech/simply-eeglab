#!/usr/bin/env python3
"""Generate src/i18n/ar.json and en.json from the key tables in site_copy.md.

A key row looks like: | `key.name` | Arabic text | English text | note |
Struck rows (~~...~~) are skipped. A key that appears twice keeps its last row,
since later versions of the copy are appended below earlier ones.

Usage: python3 -I site_copy_to_i18n.py <site_copy.md> <out dir>
"""
import json, pathlib, re, sys

ROW = re.compile(r'^\|\s*`([a-zA-Z0-9][\w.-]*)`\s*\|(.*)$')


def cells(rest):
    parts, cur, code = [], '', False
    for ch in rest:
        if ch == '`':
            code = not code
        if ch == '|' and not code:
            parts.append(cur.strip()); cur = ''
        else:
            cur += ch
    return parts


def clean(v):
    v = v.replace('\\|', '|')
    return re.sub(r'^`(.*)`$', r'\1', v)


def main():
    src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    ar, en, dup = {}, {}, []
    for line in src.read_text(encoding='utf-8').splitlines():
        if '~~`' in line[:6]:
            continue
        m = ROW.match(line)
        if not m:
            continue
        c = cells(m.group(2))
        if len(c) < 2 or not c[0] or not c[1]:
            continue
        key = m.group(1)
        if key in ar:
            dup.append(key)
        ar[key], en[key] = clean(c[0]), clean(c[1])
    out.mkdir(parents=True, exist_ok=True)
    for name, d in (('ar', ar), ('en', en)):
        (out / f'{name}.json').write_text(json.dumps(dict(sorted(d.items())), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'i18n: {len(ar)} keys' + (f'; repeated (last row kept): {", ".join(sorted(set(dup)))}' if dup else ''))


if __name__ == '__main__':
    main()
