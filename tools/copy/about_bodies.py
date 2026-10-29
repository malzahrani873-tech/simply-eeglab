"""Extracts the long about-page texts (`about.*.body`) from site_copy.md into src/i18n/about.json.

Usage: python3 tools/copy/about_bodies.py _specs/site_copy.md src/i18n/about.json
"""
import html, json, re, sys

src, out = sys.argv[1], sys.argv[2]
text = open(src, encoding='utf-8').read()
blocks = re.split(r'^\*\*`(about\.[a-z0-9.]+\.body)`\*\*.*$', text, flags=re.M)
res = {'ar': {}, 'en': {}}


def inline(s):
    s = html.escape(s.strip(), quote=False)
    s = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', s)
    return re.sub(r'`(.+?)`', r'<code>\1</code>', s)


for key, body in zip(blocks[1::2], blocks[2::2]):
    body = re.split(r'^(?:> |### |\*\*`|- \*\*الأزرار)', body, flags=re.M)[0]
    for lang in ('ar', 'en'):
        m = re.search(rf'^- \*\*{lang}:\*\*(.*?)(?=^- \*\*(?:ar|en):\*\*|\Z)', body, flags=re.M | re.S)
        if not m:
            continue
        chunk = m.group(1)
        items = re.findall(r'^\s{2,}- (.+)$', chunk, flags=re.M)
        res[lang][key] = ('<ul>' + ''.join(f'<li>{inline(i)}</li>' for i in items) + '</ul>') if items else f'<p>{inline(chunk)}</p>'

json.dump(res, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print(f'{len(res["ar"])} ar, {len(res["en"])} en')
