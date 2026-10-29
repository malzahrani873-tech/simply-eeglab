"""
draw_quiz.py - images of the station quizzes (quizzes/notes.md section 4) as WebP in assets/quiz/NN/<id>.webp.

  --draw      s00-q03: head from above, 21 grey 10-20 dots, C4 filled. No text, one version for both
              languages, not mirrored (the left of the drawing is the participant's left).
  --ica DIR   s04-q05..q08: copy the ICA game drafts from DIR (assets/ica-game/draft/img). They stay drafts
              until the game review; rerun with the final image folder after it.
  --convert DIR
              assets-src/quiz from fig_quiz.m (MATLAB): every <id>.png at its quiz size, plus the two
              main-window screenshots (s01-q02, s02-q03), scaled to fit and centred on white.

Usage:
  python3 -I tools/python/draw_quiz.py --out assets/quiz --draw --ica assets/ica-game/draft/img
  python3 -I tools/python/draw_quiz.py --out assets/quiz --convert assets-src
"""
import argparse
import math
import os
import shutil
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from draw_concepts_2 import positions_1020  # noqa: E402

# id -> (width, height), as in the quiz files
SIZES = {
    "s00-q03": (600, 600), "s00-q06": (720, 360), "s01-q02": (720, 480), "s02-q03": (720, 480),
    "s02-q04": (640, 640), "s03-q03": (720, 480), "s03-q04": (720, 480), "s05-q04": (720, 360),
    "s05-q05": (720, 420), "s06-q01": (720, 400), "s06-q04": (720, 520), "s07-q01": (720, 360),
    "s07-q02": (720, 400), "s08-q05": (720, 400),
}
ICA = {"s04-q05": "sub-003_IC01", "s04-q06": "sub-006_IC15", "s04-q07": "sub-011_IC11", "s04-q08": "sub-009_IC22"}
# hand screenshots, relative to assets-src
SCREENS = {"s01-q02": "quiz/01/s01-q02.png", "s02-q03": "screenshots/S5-main-after-import.png"}
MAX_KB = 200
QUALITY = 82

TEXT, STRONG, DOT, DOT_EDGE, HIGHLIGHT, HIGHLIGHT_EDGE = (
    "#111114", "#8A8A92", "#C6C6C8", "#8A8A92", "#0060DF", "#003E91")


def target(out, qid):
    return os.path.join(out, qid[1:3], qid + ".webp")


def save_webp(im, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    q = QUALITY
    while True:
        im.save(dst, "WEBP", quality=q, method=6)
        if os.path.getsize(dst) <= MAX_KB * 1024 or q <= 50:
            break
        q -= 8
    print(f"{os.path.basename(dst)}  {im.width}x{im.height}  q{q}  {os.path.getsize(dst) / 1024:.1f} KB")


def draw_head(out):
    """s00-q03, drawn at 4x and reduced for smooth edges."""
    w, h = SIZES["s00-q03"]
    k = 4
    im = Image.new("RGB", (w * k, h * k), "white")
    d = ImageDraw.Draw(im)
    cx, cy, r = w / 2 * k, (h / 2 + 14) * k, 230 * k
    lw = round(2.2 * k)
    # nose and ears behind the head outline
    d.line([(cx - 22 * k, cy - r + 4 * k), (cx, cy - r - 30 * k), (cx + 22 * k, cy - r + 4 * k)],
           fill=TEXT, width=lw, joint="curve")
    for s in (-1, 1):
        x0, x1 = sorted((cx + s * (r - 14 * k), cx + s * (r + 46 * k)))
        d.ellipse([x0, cy - 50 * k, x1, cy + 50 * k], fill="white", outline=TEXT, width=lw)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill="white", outline=TEXT, width=lw)
    # faint guide lines: midline and ear to ear
    for x0, y0, x1, y1 in ((cx - r, cy, cx + r, cy), (cx, cy - r, cx, cy + r)):
        n = 40
        for i in range(0, n, 2):
            d.line([(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n),
                    (x0 + (x1 - x0) * (i + 1) / n, y0 + (y1 - y0) * (i + 1) / n)], fill=DOT, width=k)
    dot = 17 * k
    pts = {}
    for name, v in positions_1020().items():
        theta = math.degrees(math.acos(max(-1.0, min(1.0, v[2]))))
        az = math.atan2(v[0], v[1])
        rr = r * theta / 90
        pts[name] = (cx + rr * math.sin(az), cy - rr * math.cos(az))
    pts["A1"], pts["A2"] = (cx - r - 22 * k, cy), (cx + r + 22 * k, cy)
    for name, (x, y) in pts.items():
        hl = name == "C4"
        d.ellipse([x - dot, y - dot, x + dot, y + dot], fill=HIGHLIGHT if hl else DOT,
                  outline=HIGHLIGHT_EDGE if hl else DOT_EDGE, width=round((3 if hl else 2) * k))
    assert len(pts) == 21
    save_webp(im.resize((w, h), Image.LANCZOS), target(out, "s00-q03"))


def copy_ica(out, src):
    for qid, item in ICA.items():
        f = os.path.join(src, item + ".webp")
        dst = target(out, qid)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(f, dst)
        with Image.open(dst) as im:
            print(f"{qid}.webp  from {item}  {im.width}x{im.height}  {os.path.getsize(dst) / 1024:.1f} KB  (draft)")


def fit(im, size):
    """Scale to fit inside size, centred on white; images already at size are kept as they are."""
    if im.size == size:
        return im
    s = min(size[0] / im.width, size[1] / im.height)
    small = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    canvas = Image.new("RGB", size, "white")
    canvas.paste(small, ((size[0] - small.width) // 2, (size[1] - small.height) // 2))
    return canvas


def convert(out, src):
    missing = []
    for qid, size in SIZES.items():
        if qid == "s00-q03":
            continue
        f = os.path.join(src, SCREENS.get(qid, f"quiz/{qid[1:3]}/{qid}.png"))
        if not os.path.exists(f):
            missing.append(f)
            continue
        with Image.open(f) as im:
            im = im.convert("RGB")
            if qid not in SCREENS and im.size != size:
                print(f"warning: {qid} is {im.width}x{im.height}, expected {size[0]}x{size[1]}")
            save_webp(fit(im, size), target(out, qid))
    if missing:
        print("not found:\n  " + "\n  ".join(missing))
        sys.exit(1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--draw", action="store_true")
    ap.add_argument("--ica")
    ap.add_argument("--convert")
    a = ap.parse_args()
    if a.draw:
        draw_head(a.out)
    if a.ica:
        copy_ica(a.out, a.ica)
    if a.convert:
        convert(a.out, a.convert)


if __name__ == "__main__":
    main()
