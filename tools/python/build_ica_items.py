"""
build_ica_items.py - build the ICA game data from the reviewed candidate table.

Input: a copy of candidates.csv with these columns added by the reviewer (leave a cell empty when
it does not apply):
  use            game | form-A | form-B | daily   (anything else = excluded; daily = component of the day)
  answer         brain|eye|muscle|heart|line|chan|other   (final expert decision)
  expert_agrees  yes | no
  level          1 | 2 | 3   (optional; defaults to level_suggested)
  eye_subtype    blink | saccade   (answer=eye only)
  hint_panel     topo | spectrum | time

Output (in --out):
  ica-game.items.json        language-neutral game data
  ica-forms.items.json       the two held-out forms A and B (not published)
  ica-daily.items.json       component of the day: clear components, one per day in list order
  ica-game.text.ar.json      Arabic text skeleton: all keys, empty values
  ica-game.text.en.json      same skeleton in English
  img/<id>.webp              images 720 px wide, quality 80, checked against the 60 KB limit

Usage:
  python3 -I build_ica_items.py --csv reviewed.csv --img-dir <candidates> --out <dir> \
      --dataset ds002718 --eeglab 2026.1 --iclabel 1.7 --matlab R2024b --colormap turbo
"""
import argparse
import csv
import json
import os
import sys
from datetime import date

from PIL import Image

CLASSES = ["brain", "eye", "muscle", "heart", "line", "chan", "other"]
ICL = ["brain", "muscle", "eye", "heart", "line", "chan", "other"]
MAX_KB = 60
WIDTH = 720


def to_webp(src, dst, quality):
    im = Image.open(src).convert("RGB")
    if im.width != WIDTH:
        im = im.resize((WIDTH, round(im.height * WIDTH / im.width)), Image.LANCZOS)
    im.save(dst, "WEBP", quality=quality, method=6)
    return im.size, os.path.getsize(dst) / 1024


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--img-dir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--dataset", default="ds002718")
    ap.add_argument("--eeglab", required=True)
    ap.add_argument("--iclabel", required=True)
    ap.add_argument("--matlab", default="")
    ap.add_argument("--colormap", default="turbo")
    ap.add_argument("--quality", type=int, default=80)
    ap.add_argument("--first-id", type=int, default=1)
    a = ap.parse_args()

    os.makedirs(os.path.join(a.out, "img"), exist_ok=True)
    rows = list(csv.DictReader(open(a.csv, newline="", encoding="utf-8")))
    errors, game, forms, daily, subjects, deferred = [], [], {"A": [], "B": []}, [], [], []
    n, nd = a.first_id, 1

    for r in rows:
        use = (r.get("use") or "").strip()
        if use not in ("game", "form-A", "form-B", "daily"):
            continue
        answer = (r.get("answer") or "").strip()
        where = f"{r['sub']} {r['ic']}"
        if answer not in CLASSES:
            errors.append(f"{where}: answer '{answer}' is not a class")
            continue
        level = int(r.get("level") or r["level_suggested"])
        verdict = (r.get("expert_agrees") or "").strip().lower()
        agrees = verdict == "yes"
        # Forms and daily components may be reviewed after launch: unreviewed ones are left out for now.
        if use != "game" and verdict == "":
            deferred.append(f"{where} ({use})")
            continue
        if use == "daily" and not agrees:
            continue
        if (use == "daily" or level in (1, 2)) and not agrees:
            errors.append(f"{where}: {'daily' if use == 'daily' else f'level {level}'} requires expert_agrees=yes")
        line_hz = r.get("line_hz") or None
        if answer == "line" and line_hz not in ("50", "60"):
            errors.append(f"{where}: line item needs line_hz 50 or 60 from its spectrum")

        if use == "daily":
            cid = f"d{nd:03d}"
            nd += 1
        else:
            cid = f"c{n:03d}"
            n += 1
        size, kb = to_webp(os.path.join(a.img_dir, r["img"]), os.path.join(a.out, "img", cid + ".webp"), a.quality)
        if kb > MAX_KB:
            errors.append(f"{where}: {cid}.webp is {kb:.1f} KB (> {MAX_KB})")

        item = {
            "id": cid,
            "img": f"/ica-game/{cid}.webp",
            "w": size[0],
            "h": size[1],
            "level": level,
            "answer": answer,
            "eye_subtype": (r.get("eye_subtype") or None) if answer == "eye" else None,
            "iclabel": {c: float(r[c]) for c in ICL},
            "validation": {
                "expert_agrees": agrees,
                "eog_corr": max(float(r["r_heog"]), float(r["r_veog"])),
                "ecg_corr": float(r["r_ecg"]),
            },
            "line_hz": int(line_hz) if answer == "line" and line_hz else None,
            "hint_panel": (r.get("hint_panel") or "topo").strip(),
            "origin": f"{r['sub']}/{r['ic']}",
        }
        if r["sub"] not in subjects:
            subjects.append(r["sub"])
        if use == "game":
            game.append(item)
        elif use == "daily":
            daily.append(item)
        else:
            forms[use[-1]].append(item)

    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    if deferred:
        print(f"{len(deferred)} items not reviewed yet, left out: " + ", ".join(deferred), file=sys.stderr)

    source = {
        "dataset": a.dataset,
        "subjects": subjects,
        "license": "CC0",
        "url": f"https://openneuro.org/datasets/{a.dataset}",
        "eeglab": a.eeglab,
        "iclabel": a.iclabel,
        "matlab": a.matlab,
        "colormap": a.colormap,
        "generated": date.today().isoformat(),
    }
    dump = lambda obj, name: json.dump(obj, open(os.path.join(a.out, name), "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    dump({"v": 1, "source": source, "classes": CLASSES, "items": game}, "ica-game.items.json")
    dump({"v": 1, "source": source, "forms": forms}, "ica-forms.items.json")
    dump({"v": 1, "source": source, "classes": CLASSES, "items": daily}, "ica-daily.items.json")

    pairs = ["brain>eye", "brain>muscle", "brain>other", "eye>chan", "muscle>chan",
             "muscle>line", "heart>brain", "heart>other", "chan>other", "line>other"]
    for lang in ("ar", "en"):
        dump(
            {
                "classes": {c: {"name": "", "term": "", "signature": ""} for c in CLASSES},
                "confusions": {p: "" for p in pairs},
                "eye_subtypes": {"blink": "", "saccade": ""},
                "items": {i["id"]: {"note": "", "alt": ""} for i in game},
            },
            f"ica-game.text.{lang}.json",
        )

    by_level = {}
    for i in game:
        by_level.setdefault(i["level"], {}).setdefault(i["answer"], 0)
        by_level[i["level"]][i["answer"]] += 1
    print(f"game items: {len(game)}  forms: A={len(forms['A'])} B={len(forms['B'])}  daily: {len(daily)}")
    for lvl in sorted(by_level):
        print(f"  level {lvl}: {by_level[lvl]}")


if __name__ == "__main__":
    main()
