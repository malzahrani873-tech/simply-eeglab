"""
convert_and_check.py - convert assets-src images to WebP and check the size limits.

  - Lesson images: max width 1280 px, quality 82, limit 200 KB.
  - ICA game images: width 720, quality 80, limit 60 KB (built by build_ica_items.py; checked here).
  - SVG files: size check (limit 200 KB, target under 15 KB for drawings inlined in the page).
  - Before/after pairs (<name>-before.* and <name>-after.*): identical pixel size or viewBox.

Usage:
  python3 -I convert_and_check.py --src assets-src/lessons --dst assets/lessons
  python3 -I convert_and_check.py --check assets          (check only, fails on any violation)
"""
import argparse
import os
import re
import sys

from PIL import Image

LIMITS = {"lesson": 200, "ica": 60, "svg": 200}
SVG_INLINE_TARGET = 15


def convert(src_root, dst_root, max_w=1280, quality=82):
    for dirpath, _, files in os.walk(src_root):
        for f in sorted(files):
            if not f.lower().endswith(".png"):
                continue
            src = os.path.join(dirpath, f)
            rel = os.path.relpath(src, src_root)
            dst = os.path.join(dst_root, os.path.splitext(rel)[0] + ".webp")
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            im = Image.open(src).convert("RGB")
            if im.width > max_w:
                im = im.resize((max_w, round(im.height * max_w / im.width)), Image.LANCZOS)
            q = quality
            while True:
                im.save(dst, "WEBP", quality=q, method=6)
                if os.path.getsize(dst) <= LIMITS["lesson"] * 1024 or q <= 50:
                    break
                q -= 8
            print(f"{rel} -> {os.path.relpath(dst, dst_root)}  {im.width}x{im.height}  q{q}  {os.path.getsize(dst) / 1024:.1f} KB")


def size_of(path):
    """Pixel size of a raster, or the viewBox size of an SVG."""
    if path.lower().endswith(".svg"):
        m = re.search(r'viewBox="\s*[-\d.]+\s+[-\d.]+\s+([\d.]+)\s+([\d.]+)"', open(path, encoding="utf-8").read(2000))
        return (float(m.group(1)), float(m.group(2))) if m else None
    with Image.open(path) as im:
        return im.size


def check_pairs(root):
    """Before/after pairs (<name>-before.<ext> and <name>-after.<ext>, also with .ar/.en before the
    extension) must have identical dimensions so the slider frames match."""
    bad = 0
    for dirpath, _, files in os.walk(root):
        for f in sorted(files):
            m = re.match(r"(.+)-before((?:\.(?:ar|en))?\.[a-z]+)$", f)
            if not m:
                continue
            after = os.path.join(dirpath, f"{m.group(1)}-after{m.group(2)}")
            before = os.path.join(dirpath, f)
            if not os.path.exists(after):
                print(f"FAIL  {before}: no matching -after file")
                bad += 1
                continue
            a, b = size_of(before), size_of(after)
            if a != b:
                print(f"FAIL  pair {os.path.relpath(before, root)}: before {a} vs after {b}")
                bad += 1
            else:
                print(f"ok    pair {os.path.relpath(before, root)}: {a[0]:g}x{a[1]:g}")
    return bad


def check(root):
    bad = check_pairs(root)
    for dirpath, _, files in os.walk(root):
        for f in sorted(files):
            p = os.path.join(dirpath, f)
            kb = os.path.getsize(p) / 1024
            ext = f.lower().rsplit(".", 1)[-1]
            if ext in ("png", "jpg", "jpeg") and "og" not in p.split(os.sep):
                print(f"FAIL  {p}: raster must be WebP")
                bad += 1
                continue
            limit = LIMITS["ica"] if "ica-game" in p.split(os.sep) and ext == "webp" else LIMITS["lesson"]
            if ext in ("webp", "svg", "png") and kb > limit:
                print(f"FAIL  {p}: {kb:.1f} KB > {limit} KB")
                bad += 1
            elif ext == "svg" and kb > SVG_INLINE_TARGET:
                print(f"WARN  {p}: {kb:.1f} KB (inline target {SVG_INLINE_TARGET} KB)")
            elif ext in ("webp", "svg", "png"):
                print(f"ok    {p}: {kb:.1f} KB")
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src")
    ap.add_argument("--dst")
    ap.add_argument("--check")
    a = ap.parse_args()
    if a.src and a.dst:
        convert(a.src, a.dst)
    if a.check:
        sys.exit(1 if check(a.check) else 0)


if __name__ == "__main__":
    main()
