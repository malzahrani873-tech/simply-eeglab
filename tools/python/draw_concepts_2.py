"""
draw_concepts_2.py - concept drawings for stations 0, 1, 5 and 8, as SVG in the site's visual identity.

Same conventions as draw_concepts.py: one file per language because text is part of the drawing,
colours are CSS variables with light-mode fallbacks, and both languages share one viewBox.
Every <text> carries an explicit direction, so an inlined drawing renders the same inside an RTL
page as it does as an <img>. Latin terms, file names and code are always separate LTR elements.

Drawings:
  eeg-origin/eeg-origin-cells.{ar,en}.svg            one cell -> parallel cells -> random vs synchronized
  electrode-10-20/electrode-10-20.{ar,en}.svg        side view (10/20 % arc) and top view (21 electrodes)
  matlab-basics/matlab-window.{ar,en}.svg            Current Folder, Command Window, Workspace
  experiment-design/trial-timelines.{ar,en}.svg      weak vs good trial timing
  eeg-struct/eeg-struct-tree.{ar,en}.svg             the main fields of EEG in eeglab_data.set
  extract-epochs/extract-epochs-concept.{ar,en}.svg  continuous Cz -> stacked epochs (needs --d1)
  study-concepts/study-concepts-gates.{ar,en}.svg     four files -> three gates (one stops) -> STUDY
  create-study/create-study-files.{ar,en}.svg        28 files in 14 folders -> one STUDY table
  study-from-bids/study-from-bids-tree.{ar,en}.svg   ds002680 BIDS tree -> gonogo_bids.study, datasetinfo rows
  study-design/study-design-2x2.{ar,en}.svg          animal/distractor (paired) x F/M (unpaired)
  study-precompute/study-precompute-files.{ar,en}.svg participant folder before/after std_precomp
  limo/limo-two-levels.{ar,en}.svg                   14 first-level models -> paired test, channels x time clusters

Usage:
  python3 -I draw_concepts_2.py --out assets/lessons --d1 path/to/eeglab_data.set [--only slug ...]
  python3 -I draw_concepts_2.py --out assets/lessons --only study-precompute --precompute-mb 31 16 26
"""
import argparse
import math
import os

import numpy as np

FONT = "Vazirmatn, 'Noto Sans Arabic', 'Segoe UI', sans-serif"
MONO = "'JetBrains Mono', ui-monospace, monospace"
C = {
    "text": "var(--color-text, #111114)",
    "muted": "var(--color-text-muted, #5C5C66)",
    "primary": "var(--color-primary, #0060DF)",
    "sep": "var(--color-separator, #C6C6C8)",
    "strong": "var(--color-border-strong, #8A8A92)",
    "fill": "var(--color-surface-2, #E9E9EE)",
    "surface": "var(--color-surface, #FFFFFF)",
    "core": "var(--level-core, #5A3FD6)",
    "rec": "var(--level-rec, #1B7F45)",
    "info": "var(--status-info-soft, #E5F0FF)",
}


# --- primitives ------------------------------------------------------------------------

def _anchor(side, rtl):
    """Physical side ('left', 'middle', 'right') to text-anchor for the given direction."""
    if side == "middle":
        return "middle"
    return {("left", False): "start", ("right", False): "end",
            ("left", True): "end", ("right", True): "start"}[(side, rtl)]


def label(x, y, s, lang, size=14, fill=None, side="middle", weight=400, extra=""):
    """Text in the drawing's language. Arabic is RTL; English and Latin-only strings are LTR."""
    rtl = lang == "ar"
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill or C["text"]}" text-anchor="{_anchor(side, rtl)}" direction="{"rtl" if rtl else "ltr"}"{extra}>{s}</text>')


def code(x, y, s, size=12.5, fill=None, side="middle", weight=400):
    """Latin term, file name or MATLAB code: monospace and always LTR."""
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{MONO}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill or C["text"]}" text-anchor="{_anchor(side, False)}" direction="ltr" xml:space="preserve">{s}</text>')


def latin(x, y, s, size=13, fill=None, side="middle", weight=400):
    """Latin word in the text font (e.g. Nasion, Odd), always LTR."""
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill or C["text"]}" text-anchor="{_anchor(side, False)}" direction="ltr">{s}</text>')


def path(xs, ys, stroke, width=1.5, dash=None, nd=1):
    """Path with relative coordinates rounded to `nd` decimals (0.1 px by default)."""
    xs, ys = np.round(np.asarray(xs, float), nd), np.round(np.asarray(ys, float), nd)
    d = [f"M{xs[0]:g} {ys[0]:g}l"]
    for dx, dy in zip(np.diff(xs), np.diff(ys)):
        d.append(f"{round(dx, nd):g} {round(dy, nd):g}")
    da = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<path d="{" ".join(d)}" fill="none" stroke="{stroke}" stroke-width="{width}" '
            f'stroke-linejoin="round" stroke-linecap="round"{da}/>')


def line(x1, y1, x2, y2, stroke, width=1.0, dash=None):
    da = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{stroke}" stroke-width="{width}"{da}/>'


def rect(x, y, w, h, fill="none", stroke=None, width=1.0, rx=0, dash=None, opacity=None):
    st = f' stroke="{stroke}" stroke-width="{width}"' if stroke else ""
    da = f' stroke-dasharray="{dash}"' if dash else ""
    op = f' opacity="{opacity}"' if opacity is not None else ""
    r = f' rx="{rx}"' if rx else ""
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}"{r} fill="{fill}"{st}{da}{op}/>'


def arrow(x1, y, x2, stroke=None, width=1.4):
    """Horizontal arrow from x1 to x2 (either direction)."""
    s = 1 if x2 > x1 else -1
    stroke = stroke or C["text"]
    return (line(x1, y, x2 - 8 * s, y, stroke, width) +
            f'<path d="M{x2:.1f},{y:.1f} l{-10 * s},-5.5 v11 z" fill="{stroke}"/>')


def varrow(x, y1, y2, stroke=None, width=1.2):
    s = 1 if y2 > y1 else -1
    stroke = stroke or C["text"]
    return (line(x, y1, x, y2 - 7 * s, stroke, width) +
            f'<path d="M{x:.1f},{y2:.1f} l-4.5,{-9 * s} h9 z" fill="{stroke}"/>')


def svg(w, h, body, aria):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'role="img" aria-label="{aria}">\n' + "\n".join(body) + "\n</svg>\n")


def save(out, rel, content):
    p = os.path.join(out, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as fh:
        fh.write(content)
    print(f"{rel}  {len(content.encode()) / 1024:.1f} KB")


def order(items, lang):
    """Panels follow the reading direction: left to right in English, right to left in Arabic."""
    return list(items) if lang == "en" else list(items)[::-1]


# --- 00-01 eeg-origin ------------------------------------------------------------------

T_ORIGIN = {
    "p1": {"ar": "خلية هرمية واحدة", "en": "One pyramidal cell"},
    "p2": {"ar": "آلاف الخلايا المتوازية", "en": "Thousands of parallel cells"},
    "p3": {"ar": "ما يلتقطه القطب", "en": "What the electrode picks up"},
    "surface": {"ar": "السطح", "en": "Surface"},
    "input": {"ar": "إشارة مشبكية", "en": "Synaptic input"},
    "current": {"ar": "تيار", "en": "Current"},
    "body": {"ar": "جسم الخلية", "en": "Cell body"},
    "scalp": {"ar": "فروة الرأس", "en": "Scalp"},
    "skull": {"ar": "الجمجمة", "en": "Skull"},
    "men": {"ar": "السحايا", "en": "Meninges"},
    "cortex": {"ar": "القشرة", "en": "Cortex"},
    "random": {"ar": "توقيت عشوائي", "en": "Random timing"},
    "sync": {"ar": "توقيت متزامن", "en": "Synchronized timing"},
    "same": {"ar": "نفس عدد الخلايا، ونفس المقياس", "en": "Same number of cells, same scale"},
    "aria": {
        "ar": "ثلاث لوحات: خلية هرمية واحدة يمر فيها تيار على طول تغصّنها، ثم صف من الخلايا المتوازية تحت السحايا والجمجمة وفروة الرأس، ثم قطب على فروة الرأس يلتقط موجة صغيرة جداً عندما يكون توقيت الخلايا عشوائياً وموجة كبيرة عندما تتزامن.",
        "en": "Three panels: one pyramidal cell with current along its dendrite, a row of parallel cells under the meninges, skull and scalp, and a scalp electrode that picks up a tiny wave when the cells' timing is random and a large wave when they are synchronized.",
    },
}


def pyramidal(cx, base, height, stroke, width=1.3, tuft=True):
    """Cell body (triangle) at `base`, apical dendrite rising `height` px, small tuft and basal dendrites."""
    s = height / 150
    b = []
    tri = f"M{cx - 9 * s:.1f},{base:.1f} L{cx + 9 * s:.1f},{base:.1f} L{cx:.1f},{base - 16 * s:.1f} Z"
    b.append(f'<path d="{tri}" fill="{stroke}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"/>')
    top = base - height
    b.append(line(cx, base - 16 * s, cx, top + 8 * s, stroke, width))
    if tuft:
        for dx, dy in ((-14, -2), (14, -4), (-8, 6), (9, 8)):
            b.append(line(cx, top + 10 * s + dy * s, cx + dx * s, top + dy * s - 4 * s, stroke, width * 0.8))
    for dx in (-16, 16):
        b.append(line(cx + 6 * math.copysign(1, dx) * s, base - 2 * s, cx + dx * s, base + 12 * s, stroke, width * 0.8))
    b.append(line(cx, base, cx, base + 22 * s, stroke, width * 0.8))
    return b


def draw_eeg_origin(out, lang):
    W, H = 720, 372
    pw, top, bot = 210, 66, 346
    xs = order([20, 255, 490], lang)
    body = [rect(0, 0, W, H, C["surface"])]
    for x, key in zip(xs, ("p1", "p2", "p3")):
        body.append(rect(x, top - 14, pw, bot - top + 14, "none", C["sep"], 1, rx=12))
        body.append(label(x + pw / 2, top - 26, T_ORIGIN[key][lang], lang, 15, weight=600))
    for i, x in enumerate(xs):
        body.append(f'<circle cx="{x + 18}" cy="{top + 6}" r="10" fill="{C["fill"]}"/>')
        body.append(latin(x + 18, top + 10.5, str(i + 1), 12, C["muted"], weight=600))

    # panel 1: one cell, input near the top, current flowing down the dendrite
    x0 = xs[0]
    cx, base = x0 + pw / 2 + 14, 268
    body += pyramidal(cx, base, 170, C["text"], 1.6)
    syn_y = base - 150
    body.append(path([cx + 46, cx + 22, cx + 7], [syn_y - 24, syn_y - 10, syn_y], C["muted"], 1.2))
    body.append(f'<circle cx="{cx + 5:.1f}" cy="{syn_y:.1f}" r="4" fill="{C["primary"]}"/>')
    body.append(label(x0 + pw - 8, syn_y - 30, T_ORIGIN["input"][lang], lang, 13, C["muted"], side="right"))
    ax = cx + 16
    body.append(line(ax, syn_y + 14, ax, base - 34, C["primary"], 2.2))
    body.append(f'<path d="M{ax:.1f},{base - 26:.1f} l-5,-10 h10 z" fill="{C["primary"]}"/>')
    body.append(label(ax + 8, (syn_y + base) / 2 - 4, T_ORIGIN["current"][lang], lang, 13, C["primary"], side="left"))
    body.append(label(cx, base + 40, T_ORIGIN["body"][lang], lang, 13, C["muted"]))
    body.append(varrow(x0 + 30, base - 30, top + 62, C["muted"], 1))
    body.append(label(x0 + 30, top + 50, T_ORIGIN["surface"][lang], lang, 12.5, C["muted"]))

    # panel 2: layers above a row of parallel cells (approximate thicknesses)
    x0 = xs[1]
    layers = [("scalp", 22, C["fill"], 1.0), ("skull", 26, C["strong"], 0.35), ("men", 16, C["fill"], 0.7)]
    y = top + 18
    for key, h, fill, op in layers:
        body.append(rect(x0 + 10, y, pw - 20, h, fill, opacity=op))
        body.append(label(x0 + pw / 2, y + h / 2 + 5, T_ORIGIN[key][lang], lang, 13, C["text"]))
        y += h
    body.append(label(x0 + pw / 2, bot - 10, T_ORIGIN["cortex"][lang], lang, 13, C["muted"]))
    for i in range(14):
        xx = x0 + 22 + i * 12.8
        body += pyramidal(xx, 296, 128, C["text"], 1.1, tuft=False)
        body.append(line(xx + 4.5, y + 24, xx + 4.5, y + 62, C["primary"], 1.3))
        body.append(f'<path d="M{xx + 4.5:.1f},{y + 70:.1f} l-3,-8 h6 z" fill="{C["primary"]}"/>')

    # panel 3: electrode, then two traces on the same amplitude scale (sum of 1000 10-Hz sources)
    x0 = xs[2]
    ex = x0 + pw / 2
    body.append(rect(x0 + 10, top + 18, pw - 20, 14, C["fill"]))
    body.append(f'<ellipse cx="{ex:.1f}" cy="{top + 16:.1f}" rx="14" ry="5" fill="{C["text"]}"/>')
    body.append(path([ex, ex + 4, ex + 30, ex + 46], [top + 12, top - 2, top - 6, top - 6], C["text"], 1.4))
    body.append(latin(ex + 50, top - 2, "EEG", 11.5, C["muted"], side="left"))
    rng = np.random.default_rng(2026)
    t = np.linspace(0, 0.5, 220)
    n = 1000
    phases = rng.uniform(0, 2 * np.pi, n)
    random_sum = np.sin(2 * np.pi * 10 * t[:, None] + phases[None, :]).sum(1)
    sync_sum = n * np.sin(2 * np.pi * 10 * t)
    scale = 38 / n
    for j, (key, sig) in enumerate((("random", random_sum), ("sync", sync_sum))):
        yc = 168 + j * 104
        body.append(label(x0 + pw / 2 + 10, yc - 44, T_ORIGIN[key][lang], lang, 13.5, weight=600))
        body.append(line(x0 + 40, yc, x0 + pw - 14, yc, C["sep"], 0.8))
        body.append(line(x0 + 40, yc - 40, x0 + 40, yc + 40, C["strong"], 1))
        body.append(path(x0 + 44 + t / t[-1] * (pw - 62), yc - sig * scale, C["primary"] if key == "sync" else C["text"], 1.6))
        body.append(latin(x0 + 34, yc + 4, "µV", 11.5, C["muted"], side="right"))
    body.append(label(x0 + pw / 2, bot - 10, T_ORIGIN["same"][lang], lang, 12.5, C["muted"]))
    save(out, f"eeg-origin/eeg-origin-cells.{lang}.svg", svg(W, H, body, T_ORIGIN["aria"][lang]))


# --- 00-02 electrode-10-20 -------------------------------------------------------------

T_1020 = {
    "side": {"ar": "منظر جانبي من اليسار", "en": "Side view, from the left"},
    "top": {"ar": "منظر من فوق، والأنف للأعلى", "en": "Top view, nose up"},
    "odd": {"ar": "أرقام فردية", "en": "Odd numbers"},
    "even": {"ar": "أرقام زوجية", "en": "Even numbers"},
    "mid": {"ar": "المنتصف", "en": "Midline"},
    "left": {"ar": "يسار المشارك", "en": "Participant's left"},
    "right": {"ar": "يمينه", "en": "Right"},
    "nasion": {"ar": "أعلى الأنف", "en": "top of the nose"},
    "inion": {"ar": "مؤخرة الجمجمة", "en": "back of the skull"},
    "aria": {
        "ar": "نظام 10-20. يسار: منظر جانبي فيه قوس من Nasion إلى Inion مقسّم 10% ثم أربع مرات 20% ثم 10%، وعليه Fpz و Fz و Cz و Pz و Oz. يمين: منظر من فوق فيه الأقطاب الـ 21، والأرقام الفردية على يسار الرأس والزوجية على يمينه، وحرف z على خط المنتصف.",
        "en": "The 10-20 system. Left: side view with the arc from nasion to inion split into 10%, four times 20%, then 10%, carrying Fpz, Fz, Cz, Pz and Oz. Right: top view with the 21 electrodes; odd numbers on the left of the head, even on the right, z on the midline.",
    },
}


def _sph(theta, phi):
    """Unit vector: theta = angle from the vertex (deg), phi = azimuth from the nose, positive to the right (deg)."""
    t, p = math.radians(theta), math.radians(phi)
    return np.array([math.sin(t) * math.sin(p), math.sin(t) * math.cos(p), math.cos(t)])


def _mid(a, b):
    v = a + b
    return v / np.linalg.norm(v)


def positions_1020():
    """The 19 scalp sites of the 10-20 system on a unit sphere (x right, y nose, z up)."""
    P = {"Cz": _sph(0, 0), "Fz": _sph(36, 0), "Pz": _sph(36, 180), "C3": _sph(36, -90), "C4": _sph(36, 90)}
    for name, phi in (("Fp1", -18), ("Fp2", 18), ("F7", -54), ("F8", 54), ("T7", -90), ("T8", 90),
                      ("P7", -126), ("P8", 126), ("O1", -162), ("O2", 162)):
        P[name] = _sph(72, phi)
    # F3 lies halfway between Fz and F7 (and between Fp1 and C3); same for the others.
    P["F3"], P["F4"] = _mid(P["Fz"], P["F7"]), _mid(P["Fz"], P["F8"])
    P["P3"], P["P4"] = _mid(P["Pz"], P["P7"]), _mid(P["Pz"], P["P8"])
    return P


def draw_10_20(out, lang):
    W, H = 720, 420
    body = [rect(0, 0, W, H, C["surface"])]

    # side view (left panel in both languages: the drawing is not mirrored); the participant faces left
    cx, cy, R = 200, 236, 100
    body.append(label(cx, 40, T_1020["side"][lang], lang, 15, weight=600))
    nx0, ix0 = cx - R, cx + R
    body.append(f'<path d="M{nx0},{cy} A{R},{R} 0 0 1 {ix0},{cy}" fill="none" stroke="{C["text"]}" stroke-width="1.6"/>')
    face = f"M{nx0},{cy} l-16,26 l13,5 l-2,10 l3,8 l-3,10 q4,18 30,20 q30,0 44,-14"
    neck = f"M{ix0},{cy} q-2,44 -30,64 l-6,30"
    body.append(f'<path d="{face}" fill="none" stroke="{C["text"]}" stroke-width="1.6" stroke-linejoin="round"/>')
    body.append(f'<path d="{neck}" fill="none" stroke="{C["text"]}" stroke-width="1.6"/>')
    body.append(f'<ellipse cx="{cx + 10}" cy="{cy + 14}" rx="10" ry="18" fill="none" stroke="{C["muted"]}" stroke-width="1.2"/>')
    # arc from nasion (180 deg) over the top to inion (0 deg); 10-20 splits
    marks = [0, 10, 30, 50, 70, 90, 100]
    names = {10: "Fpz", 30: "Fz", 50: "Cz", 70: "Pz", 90: "Oz"}
    ang = lambda pc: math.radians(180 - pc * 1.8)
    pt = lambda pc, r=R: (cx + r * math.cos(ang(pc)), cy - r * math.sin(ang(pc)))
    for a, b in zip(marks[:-1], marks[1:]):
        mx, my = pt((a + b) / 2, R + 22)
        body.append(latin(mx, my + 4, f"{b - a}%", 12, C["primary"], weight=600))
    for pc in marks:
        x1, y1 = pt(pc, R - 6)
        x2, y2 = pt(pc, R + 8)
        body.append(line(x1, y1, x2, y2, C["primary"], 1.6))
    for pc, nm in names.items():
        x, y = pt(pc)
        body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="9" fill="{C["surface"]}" stroke="{C["text"]}" stroke-width="1.4"/>')
        lx, ly = pt(pc, R - 26)
        body.append(latin(lx, ly + 4.5, nm, 12.5, weight=600))
    nx, ny = pt(0)
    ix, iy = pt(100)
    body.append(f'<circle cx="{nx:.1f}" cy="{ny:.1f}" r="3.5" fill="{C["text"]}"/>')
    body.append(f'<circle cx="{ix:.1f}" cy="{iy:.1f}" r="3.5" fill="{C["text"]}"/>')
    body.append(latin(nx - 22, ny + 16, "Nasion", 13, weight=600, side="right"))
    body.append(label(nx - 22, ny + 34, T_1020["nasion"][lang], lang, 12.5, C["muted"], side="right"))
    body.append(latin(ix + 14, iy + 50, "Inion", 13, weight=600, side="left"))
    body.append(label(ix + 14, iy + 68, T_1020["inion"][lang], lang, 12.5, C["muted"], side="left"))

    # top view
    tx0, ty0, r = 545, 226, 125
    body.append(label(tx0, 40, T_1020["top"][lang], lang, 15, weight=600))
    body.append(f'<path d="M{tx0},{ty0 - r} A{r},{r} 0 0 0 {tx0},{ty0 + r} Z" fill="{C["info"]}"/>')
    body.append(f'<circle cx="{tx0}" cy="{ty0}" r="{r}" fill="none" stroke="{C["text"]}" stroke-width="1.6"/>')
    body.append(path([tx0 - 14, tx0, tx0 + 14], [ty0 - r + 1, ty0 - r - 18, ty0 - r + 1], C["text"], 1.6))
    for s in (-1, 1):
        ex = tx0 + s * (r + 10)
        body.append(f'<path d="M{tx0 + s * r:.1f},{ty0 - 22} q{s * 20},4 {s * 16},24 q-{s * 2},18 -{s * 16},20" '
                    f'fill="none" stroke="{C["text"]}" stroke-width="1.4"/>')
        body.append(latin(ex + s * 4, ty0 + 44, "A1" if s < 0 else "A2", 12.5, weight=600))
        body.append(f'<circle cx="{ex + s * 2:.1f}" cy="{ty0 + 28}" r="7" fill="{C["surface"]}" stroke="{C["text"]}" stroke-width="1.3"/>')
    # inner reference circle (10 % level) and the faint ear-to-ear and nose-to-inion lines
    body.append(f'<circle cx="{tx0}" cy="{ty0}" r="{r * 0.8:.1f}" fill="none" stroke="{C["sep"]}" stroke-width="1" stroke-dasharray="3 3"/>')
    body.append(line(tx0 - r, ty0, tx0 + r, ty0, C["strong"], 0.9, "2 3"))
    body.append(line(tx0, ty0 - r, tx0, ty0 + r, C["strong"], 0.9, "2 3"))
    for k in (1, 3, 5, 7, 9):
        x = tx0 - r + k * r * 0.2
        body.append(line(x, ty0 - 4, x, ty0 + 4, C["strong"], 1))
    P = positions_1020()
    for name, v in P.items():
        theta = math.degrees(math.acos(max(-1.0, min(1.0, v[2]))))
        az = math.atan2(v[0], v[1])
        rr = r * theta / 90
        x, y = tx0 + rr * math.sin(az), ty0 - rr * math.cos(az)
        mid = name.endswith("z")
        body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="15" fill="{C["surface"]}" stroke="{C["primary"] if mid else C["text"]}" stroke-width="1.4"/>')
        body.append(latin(x, y + 4.3, name, 11.5, C["primary"] if mid else C["text"], weight=600))
    body.append(label(tx0 - r * 0.55, ty0 + r + 30, T_1020["odd"][lang], lang, 13.5, weight=600))
    body.append(latin(tx0 - r * 0.55, ty0 + r + 48, "1, 3, 5, 7", 12, C["muted"]))
    body.append(label(tx0 + r * 0.55, ty0 + r + 30, T_1020["even"][lang], lang, 13.5, weight=600))
    body.append(latin(tx0 + r * 0.55, ty0 + r + 48, "2, 4, 6, 8", 12, C["muted"]))
    body.append(latin(tx0, ty0 + r + 30, "z", 15, C["primary"], weight=600))
    body.append(label(tx0, ty0 + r + 48, T_1020["mid"][lang], lang, 12.5, C["primary"]))
    body.append(label(tx0 - r - 8, ty0 - r + 4, T_1020["left"][lang], lang, 12.5, C["muted"], side="left"))
    body.append(label(tx0 + r + 8, ty0 - r + 4, T_1020["right"][lang], lang, 12.5, C["muted"], side="right"))
    save(out, f"electrode-10-20/electrode-10-20.{lang}.svg", svg(W, H, body, T_1020["aria"][lang]))


# --- 00-03 matlab-basics ---------------------------------------------------------------

T_MAT = {
    "folder": {"ar": "الملفات في المجلد الحالي", "en": "Files in the current folder"},
    "cmd": {"ar": "هنا تكتب الأوامر", "en": "Where you type commands"},
    "ws": {"ar": "المتغيّرات الموجودة الآن", "en": "Variables that exist now"},
    "toolbar": {"ar": "شريط الأدوات", "en": "Toolstrip"},
    "aria": {
        "ar": "رسم تخطيطي لنافذة MATLAB: Current Folder على اليسار فيه ملفات المجلد الحالي، و Command Window في المنتصف وفيه السطر demo.srate = 128 ونتيجته، و Workspace على اليمين وفيه المتغيّر demo من نوع 1x1 struct.",
        "en": "Schematic of the MATLAB window: Current Folder on the left with the files of the current folder, Command Window in the middle with the line demo.srate = 128 and its output, and Workspace on the right with the variable demo of type 1x1 struct.",
    },
}


def draw_matlab(out, lang):
    W, H = 720, 400
    body = [rect(0, 0, W, H, C["surface"])]
    body.append(rect(16, 16, W - 32, H - 32, C["surface"], C["strong"], 1.2, rx=10))
    # faint toolstrip
    body.append(rect(17, 17, W - 34, 46, C["fill"], opacity=0.6))
    for i, w in enumerate((44, 44, 44, 60, 44, 44)):
        body.append(rect(32 + i * 64, 28, w, 24, C["sep"], rx=4, opacity=0.6))
    body.append(label(W - 40, 45, T_MAT["toolbar"][lang], lang, 12.5, C["muted"], side="right"))
    # three parts, fixed MATLAB layout (not mirrored)
    parts = [(28, 168, "Current Folder", "folder", C["rec"]),
             (206, 312, "Command Window", "cmd", C["primary"]),
             (528, 164, "Workspace", "ws", C["core"])]
    y0, h = 76, 296
    for x, w, name, key, col in parts:
        body.append(rect(x, y0, w, h, "none", col, 2.2, rx=8))
        body.append(rect(x, y0, w, 52, col, rx=8, opacity=0.1))
        body.append(latin(x + w / 2, y0 + 21, name, 13.5, col, weight=600))
        body.append(label(x + w / 2, y0 + 41, T_MAT[key][lang], lang, 12.5, C["text"]))
    # Current Folder content
    x = 28
    body.append(code(x + 12, y0 + 76, "Name", 11.5, C["muted"], side="left"))
    body.append(line(x + 8, y0 + 84, x + 160, y0 + 84, C["sep"], 1))
    for i, nm in enumerate(("demo_basics.m",)):
        yy = y0 + 104 + i * 22
        body.append(rect(x + 12, yy - 10, 10, 12, "none", C["muted"], 1, rx=1.5))
        body.append(code(x + 28, yy, nm, 11.5, side="left"))
    # Command Window content (MATLAB output for a new struct field)
    x = 206
    lines = [(">> demo.srate = 128", C["text"]), ("", None), ("demo = ", C["text"]), ("", None),
             ("  struct with fields:", C["text"]), ("", None), ("    srate: 128", C["text"]), ("", None),
             (">> ", C["text"])]
    for i, (s, col) in enumerate(lines):
        if s:
            body.append(code(x + 14, y0 + 82 + i * 19, s, 12.5, col, side="left"))
    body.append(rect(x + 44, y0 + 82 + 8 * 19 - 12, 2, 15, C["text"]))
    # Workspace content
    x = 528
    body.append(code(x + 12, y0 + 76, "Name", 11.5, C["muted"], side="left"))
    body.append(code(x + 84, y0 + 76, "Value", 11.5, C["muted"], side="left"))
    body.append(line(x + 8, y0 + 84, x + 156, y0 + 84, C["sep"], 1))
    body.append(rect(x + 4, y0 + 90, 156, 22, C["core"], rx=4, opacity=0.12))
    body.append(code(x + 12, y0 + 105, "demo", 12, side="left"))
    body.append(code(x + 84, y0 + 105, "1x1 struct", 12, side="left"))
    save(out, f"matlab-basics/matlab-window.{lang}.svg", svg(W, H, body, T_MAT["aria"][lang]))


# --- 00-05 experiment-design -----------------------------------------------------------

T_EXP = {
    "weak": {"ar": "تصميم ضعيف", "en": "Weak design"},
    "good": {"ar": "تصميم جيد", "en": "Good design"},
    "fix": {"ar": "نقطة تثبيت", "en": "Fixation"},
    "stim": {"ar": "المثير", "en": "Stimulus"},
    "press": {"ar": "ضغطة الزر", "en": "Button press"},
    "gap": {"ar": "فاصل ثابت", "en": "Fixed gap"},
    "gapv": {"ar": "فاصل متغيّر", "en": "Variable gap"},
    "random": {"ar": "عشوائي", "en": "random"},
    "note": {"ar": "التوقيت محفوظ في برنامج العرض فقط", "en": "Timing saved in the presentation software only"},
    "photo": {"ar": "حسّاس ضوء على زاوية الشاشة", "en": "Photodiode on the screen corner"},
    "marks": {"ar": "علامة حدث تُسجَّل مع الإشارة", "en": "Event mark recorded with the EEG"},
    "time": {"ar": "الزمن (ms)", "en": "Time (ms)"},
    "aria": {
        "ar": "خطّان زمنيان لمحاولتين متتاليتين. التصميم الضعيف: تثبيت ثم مثير ثم ضغطة ثم فاصل ثابت، بلا علامات أحداث، والتوقيت محفوظ في برنامج العرض فقط. التصميم الجيد: نفس التسلسل مع علامة square عند المثير وعلامة rt عند الضغطة، وفاصل عشوائي الطول، وحسّاس ضوء على زاوية الشاشة.",
        "en": "Two timelines of two consecutive trials. Weak design: fixation, stimulus, press, fixed gap, no event marks, timing saved in the presentation software only. Good design: the same sequence with a square mark at the stimulus and an rt mark at the press, a random-length gap, and a photodiode on the screen corner.",
    },
}


def draw_experiment(out, lang):
    """Time runs left to right in both languages, like every time axis on the site."""
    W, H = 720, 460
    L, R = 60, 690
    tmax = 3600
    X = lambda ms: L + (R - L) * ms / tmax
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    rts = [420, 380]

    def screen(x, y, kind, diode=False):
        b = [rect(x - 15, y - 11, 30, 22, C["surface"], C["text"], 1.2, rx=3)]
        if kind == "fix":
            b.append(line(x - 4, y, x + 4, y, C["text"], 1.4) + line(x, y - 4, x, y + 4, C["text"], 1.4))
        else:
            b.append(rect(x - 5, y - 5, 10, 10, C["text"]))
        if diode:
            b.append(rect(x + 8, y - 10, 6, 6, C["primary"]))
        return b

    def timeline(y, starts, good):
        b = [label(R if rtl else L, y - 74, T_EXP["good" if good else "weak"][lang], lang, 15, weight=600,
                   side="right" if rtl else "left")]
        b.append(line(L, y, R, y, C["text"], 1.4))
        for k, t0 in enumerate(starts):
            st, rt = t0 + 500, t0 + 500 + rts[k]
            b.append(rect(X(t0), y - 10, X(st) - X(t0), 10, C["fill"]))
            b.append(rect(X(st), y - 10, X(st + 200) - X(st), 10, C["text"]))
            b += screen(X(t0 + 250), y - 32, "fix")
            b += screen(X(st + 100), y - 32, "stim", diode=good)
            b.append(f'<circle cx="{X(rt):.1f}" cy="{y - 5:.1f}" r="5" fill="{C["surface"]}" stroke="{C["text"]}" stroke-width="1.4"/>')
            if k + 1 < len(starts):
                g0, g1 = rt + 100, starts[k + 1]
                b.append(line(X(g0), y + 10, X(g1), y + 10, C["muted"], 1.2, "3 3"))
                gx = (X(g0) + X(g1)) / 2
                if good:
                    b.append(label(gx, y + 52, T_EXP["gapv"][lang], lang, 12.5, C["muted"]))
                    b.append(f'<path d="M{X(g0):.1f},{y + 60} q0,8 8,8 H{gx - 6:.1f} q6,0 6,8 q0,-8 6,-8 H{X(g1) - 8:.1f} q8,0 8,-8" '
                             f'fill="none" stroke="{C["primary"]}" stroke-width="1.2"/>')
                    b.append(label(gx, y + 94, T_EXP["random"][lang], lang, 12.5, C["primary"]))
                else:
                    b.append(label(gx, y + 30, T_EXP["gap"][lang], lang, 12.5, C["muted"]))
            if good:
                for ms, name in ((st, "square"), (rt, "rt")):
                    b.append(line(X(ms), y - 54, X(ms), y + 18, C["primary"], 2))
                    b.append(code(X(ms), y + 32, name, 12, C["primary"], weight=600))
        return b

    yw, yg = 128, 300
    body += timeline(yw, [0, 1800], False)
    # phase names once, on the first weak trial
    body.append(label(X(250), yw - 52, T_EXP["fix"][lang], lang, 12.5, C["muted"]))
    body.append(label(X(rts[0] + 500), yw - 52, T_EXP["press"][lang], lang, 12.5, C["muted"]))
    body.append(label(X(600), yw + 26, T_EXP["stim"][lang], lang, 12.5, C["muted"]))
    body.append(label(W / 2, yw + 64, T_EXP["note"][lang], lang, 13, C["muted"]))
    body += timeline(yg, [0, 1500], True)
    # legend, on the side away from the title
    lx, ly = L + (330 if rtl else 300), yg - 80
    body.append(rect(lx - 4, ly - 9, 8, 8, C["primary"]))
    body.append(line(lx, ly + 10, lx, ly + 24, C["primary"], 2))
    side = "right" if rtl else "left"
    tx_ = lx - 14 if rtl else lx + 14
    body.append(label(tx_, ly, T_EXP["photo"][lang], lang, 12.5, C["primary"], side=side))
    body.append(label(tx_, ly + 22, T_EXP["marks"][lang], lang, 12.5, C["primary"], side=side))
    # time axis
    ya = H - 50
    body.append(line(L, ya, R, ya, C["sep"], 1))
    for ms in range(0, tmax + 1, 500):
        body.append(line(X(ms), ya - 4, X(ms), ya + 4, C["sep"], 1))
        if ms % 1000 == 0:
            body.append(latin(X(ms), ya + 20, str(ms), 11.5, C["muted"]))
    body.append(label((L + R) / 2, ya + 38, T_EXP["time"][lang], lang, 12, C["muted"]))
    save(out, f"experiment-design/trial-timelines.{lang}.svg", svg(W, H, body, T_EXP["aria"][lang]))


# --- 01-03 eeg-struct ------------------------------------------------------------------

T_STRUCT = {
    "data": {"ar": "الإشارة نفسها", "en": "The signal itself"},
    "srate": {"ar": "عيّنات في الثانية", "en": "Samples per second"},
    "chanlocs": {"ar": "اسم كل قناة ومكانها", "en": "Each channel's name and place"},
    "event": {"ar": "نوع كل حدث وتوقيته", "en": "Each event's type and time"},
    "ica": {"ar": "فارغ الآن، يمتلئ بعد ICA", "en": "Empty now, filled after ICA"},
    "ch": {"ar": "قنوات", "en": "channels"},
    "smp": {"ar": "عيّنات (الزمن)", "en": "samples (time)"},
    "file": {"ar": "القيم من", "en": "Values from"},
    "aria": {
        "ar": "شجرة EEG في eeglab_data.set: data مصفوفة 32 × 30504 (القنوات في الصفوف والعيّنات في الأعمدة)، و srate قيمته 128، و chanlocs فيه 32 عنصراً، و event فيه 154 عنصراً، و icaweights فارغ حتى تشغيل ICA.",
        "en": "The EEG tree in eeglab_data.set: data is a 32 × 30504 matrix (channels in rows, samples in columns), srate is 128, chanlocs has 32 elements, event has 154 elements, and icaweights is empty until ICA is run.",
    },
}


def draw_eeg_struct(out, lang, facts):
    W, H = 720, 400
    body = [rect(0, 0, W, H, C["surface"])]
    root_y = 46
    body.append(rect(W / 2 - 46, root_y - 22, 92, 40, C["primary"], rx=8))
    body.append(code(W / 2, root_y + 4, "EEG", 16, "var(--color-primary-on, #FFFFFF)", weight=600))
    nch, npts, srate, nev = facts["nbchan"], facts["pnts"], facts["srate"], facts["nevent"]
    fields = [("data", f"{nch} × {npts}", "data"), ("srate", f"{srate:g}", "srate"),
              ("chanlocs", f"1 × {nch} struct", "chanlocs"), ("event", f"1 × {nev} struct", "event"),
              ("icaweights", "[]", "ica")]
    fields = order(fields, lang)
    bw, gap = 128, 10
    x0 = (W - 5 * bw - 4 * gap) / 2
    by = 118
    body.append(line(x0 + bw / 2, by - 24, x0 + 4 * (bw + gap) + bw / 2, by - 24, C["strong"], 1.2))
    body.append(line(W / 2, root_y + 18, W / 2, by - 24, C["strong"], 1.2))
    for i, (name, val, key) in enumerate(fields):
        x = x0 + i * (bw + gap)
        cx = x + bw / 2
        body.append(line(cx, by - 24, cx, by, C["strong"], 1.2))
        empty = key == "ica"
        body.append(rect(x, by, bw, 92, C["surface"], C["strong"] if empty else C["text"], 1.3, rx=8,
                         dash="4 3" if empty else None))
        body.append(code(cx, by + 24, name, 13, weight=600))
        body.append(code(cx, by + 48, val, 12.5, C["primary"]))
        body.append(label(cx, by + 75, T_STRUCT[key][lang], lang, 12, C["muted"]))
        if name == "data":
            mx, my, mw, mh = cx - 52, by + 132, 104, 64
            body.append(rect(mx, my, mw, mh, C["info"], C["primary"], 1.2, rx=3))
            for k in range(1, 6):
                body.append(line(mx, my + k * mh / 6, mx + mw, my + k * mh / 6, C["primary"], 0.5))
            body.append(varrow(mx - 14, my, my + mh, C["text"]))
            body.append(arrow(mx, my + mh + 14, mx + mw, C["text"], 1.2))
            body.append(label(mx - 22, my + mh / 2 + 4, T_STRUCT["ch"][lang], lang, 12.5, side="right"))
            body.append(latin(mx - 22, my + mh / 2 + 22, str(nch), 12, C["muted"], side="right"))
            body.append(label(mx + mw / 2, my + mh + 36, T_STRUCT["smp"][lang], lang, 12.5))
            body.append(latin(mx + mw / 2, my + mh + 54, str(npts), 12, C["muted"]))
            body.append(line(cx, by + 92, cx, my, C["sep"], 1, "3 3"))
    fy = H - 18
    if lang == "en":
        body.append(label(W / 2 - 4, fy, T_STRUCT["file"][lang], lang, 12, C["muted"], side="right"))
        body.append(code(W / 2 + 4, fy, "eeglab_data.set", 12, C["muted"], side="left"))
    else:
        body.append(label(W / 2 + 4, fy, T_STRUCT["file"][lang], lang, 12, C["muted"], side="left"))
        body.append(code(W / 2 - 4, fy, "eeglab_data.set", 12, C["muted"], side="right"))
    save(out, f"eeg-struct/eeg-struct-tree.{lang}.svg", svg(W, H, body, T_STRUCT["aria"][lang]))


# --- 05-01 extract-epochs --------------------------------------------------------------

T_EPOCH = {
    "cont": {"ar": "بيانات مستمرة", "en": "Continuous data"},
    "ep": {"ar": "مقاطع مرصوصة", "en": "Stacked epochs"},
    "cut": {"ar": "التقطيع", "en": "Epoching"},
    "ch": {"ar": "قنوات", "en": "channels"},
    "tp": {"ar": "نقاط زمنية", "en": "time points"},
    "ne": {"ar": "epochs", "en": "epochs"},
    "time": {"ar": "الزمن (s)", "en": "Time (s)"},
    "rel": {"ar": "الزمن من الحدث (s)", "en": "Time from event (s)"},
    "aria": {
        "ar": "قناة Cz من D1 لمدة 15 ثانية، وعليها خمسة أحداث square كل 3 ثوانٍ، وحول كل حدث نافذة من ثانية قبله إلى ثانيتين بعده. بعد التقطيع تصير النوافذ صفوفاً فوق بعض تبدأ كلها عند -1 ثانية، والصفر عند الحدث. الحجم الكلي 32 قناة × 384 نقطة زمنية × 80 epoch.",
        "en": "Channel Cz from D1 over 15 seconds with five square events every 3 seconds, each inside a window from 1 s before to 2 s after. After epoching the windows become stacked rows that all start at -1 s, with zero at the event. Total size: 32 channels × 384 time points × 80 epochs.",
    },
}


def d1_cz(d1_path):
    """Cz of D1, band-passed 0.5-30 Hz for display, plus the square event times and the dataset facts."""
    import mne
    from scipy.signal import butter, sosfiltfilt
    raw = mne.io.read_raw_eeglab(d1_path, preload=True, verbose="error")
    sf = raw.info["sfreq"]
    events, ids = mne.events_from_annotations(raw, verbose="error")
    sq = events[events[:, 2] == ids["square"], 0] / sf
    x = raw.get_data(picks=["Cz"])[0] * 1e6
    sos = butter(4, [0.5, 30], btype="band", fs=sf, output="sos")
    facts = {"nbchan": raw.info["nchan"], "pnts": raw.n_times, "srate": sf, "nevent": len(events),
             "nsquare": len(sq), "epoch_pnts": int(round(3 * sf))}
    return sosfiltfilt(sos, x), sf, sq, facts


def draw_epochs(out, lang, cz, sf, sq, facts):
    W, H = 720, 400
    t0, t1 = 3.65, 18.75
    ev = [e for e in sq if t0 + 1 <= e <= t1 - 2][:5]
    body = [rect(0, 0, W, H, C["surface"])]
    left_w, right_w = 360, 230
    xa, xb = (24, 466) if lang == "en" else (336, 24)   # continuous part, epochs part
    i0, i1 = int(t0 * sf), int(t1 * sf)
    seg = cz[i0:i1]
    amp = np.quantile(np.abs(seg), 0.995)
    # continuous trace
    yc, ys = 170, 46 / amp
    Xc = lambda s: xa + (s - t0) / (t1 - t0) * left_w
    body.append(label(xa + left_w / 2, 52, T_EPOCH["cont"][lang], lang, 15, weight=600))
    for e in ev:
        body.append(rect(Xc(e - 1), yc - 62, Xc(e + 2) - Xc(e - 1) - 3, 124, C["primary"], rx=4, opacity=0.1))
        body.append(line(Xc(e), yc - 70, Xc(e), yc + 62, C["primary"], 1.2))
    body.append(code(Xc(ev[0]), yc - 76, "square", 11.5, C["primary"], weight=600))
    # every 2nd sample is enough at this width (the display copy is low-passed at 30 Hz)
    tt = np.arange(i0, i1, 2) / sf
    body.append(path(Xc(tt), yc - seg[::2] * ys, C["text"], 1, nd=0))
    body.append(code(xa - 4 if lang == "en" else xa + left_w + 4, yc + 4, "Cz", 12, C["muted"], side="right" if lang == "en" else "left"))
    for s in range(4, 19, 2):
        body.append(line(Xc(s), yc + 70, Xc(s), yc + 75, C["muted"], 1))
        body.append(latin(Xc(s), yc + 89, f"{s}", 11, C["muted"]))
    body.append(line(xa, yc + 70, xa + left_w, yc + 70, C["sep"], 1))
    body.append(label(xa + left_w / 2, yc + 108, T_EPOCH["time"][lang], lang, 12, C["muted"]))
    # arrow between the parts, along the reading direction
    ay = yc
    if lang == "en":
        body.append(arrow(xa + left_w + 18, ay, xb - 18))
        mid = (xa + left_w + xb) / 2
    else:
        body.append(arrow(xa - 18, ay, xb + right_w + 18))
        mid = (xb + right_w + xa) / 2
    body.append(label(mid, ay - 12, T_EPOCH["cut"][lang], lang, 12.5, C["muted"]))
    # stacked epochs, time axis always left to right
    body.append(label(xb + right_w / 2, 52, T_EPOCH["ep"][lang], lang, 15, weight=600))
    Xe = lambda s: xb + (s + 1) / 3 * right_w
    rh = 34
    top = 84
    for k, e in enumerate(ev):
        y = top + k * rh + rh / 2
        j0 = int(round((e - 1) * sf))
        w = cz[j0:j0 + facts["epoch_pnts"]:2]
        body.append(rect(xb, y - rh / 2 + 2, right_w, rh - 4, C["primary"], rx=4, opacity=0.08))
        body.append(path(Xe(np.arange(len(w)) * 2 / sf - 1), y - w * ys * 0.32, C["text"], 0.9, nd=0))
    body.append(line(Xe(0), top - 6, Xe(0), top + 5 * rh + 6, C["primary"], 1.4))
    yb = top + 5 * rh + 14
    body.append(line(xb, yb, xb + right_w, yb, C["sep"], 1))
    for s in (-1, 0, 1, 2):
        body.append(line(Xe(s), yb, Xe(s), yb + 5, C["muted"], 1))
        body.append(latin(Xe(s), yb + 19, f"{s}" if s >= 0 else "−1", 11, C["muted"]))
    body.append(label(xb + right_w / 2, yb + 38, T_EPOCH["rel"][lang], lang, 12, C["muted"]))
    # size of the result: numbers stay in EEGLAB's order in both languages
    nums = [(str(facts["nbchan"]), "ch"), (str(facts["epoch_pnts"]), "tp"), (str(facts["nsquare"]), "ne")]
    cy = H - 42
    cxs = [W / 2 - 120, W / 2, W / 2 + 120]
    for (n, key), x in zip(nums, cxs):
        body.append(code(x, cy, n, 16, weight=600))
        if key == "ne":
            body.append(latin(x, cy + 22, "epochs", 12.5, C["muted"]))
        else:
            body.append(label(x, cy + 22, T_EPOCH[key][lang], lang, 12.5, C["muted"]))
    for x in (W / 2 - 60, W / 2 + 60):
        body.append(code(x, cy, "×", 16, C["muted"]))
    save(out, f"extract-epochs/extract-epochs-concept.{lang}.svg", svg(W, H, body, T_EPOCH["aria"][lang]))


# --- station 8 (D6: Go-nogo, OpenNeuro ds002680) ---------------------------------------
# Participants and their gender column come from ds002680/participants.tsv (7 F, 7 M).


def folder_icon(x, y, w=26, h=18, stroke=None):
    stroke = stroke or C["text"]
    return (f'<path d="M{x},{y + 4} v{h - 4} h{w} v{-(h - 6)} h{-(w - 11)} l-3,-4 h-8 z" fill="{C["fill"]}" '
            f'stroke="{stroke}" stroke-width="1.2" stroke-linejoin="round"/>')


def file_icon(x, y, w=13, h=16, stroke=None, fill=None):
    stroke = stroke or C["text"]
    return (f'<path d="M{x},{y} h{w - 4} l4,4 v{h - 4} h{-w} z" fill="{fill or C["surface"]}" '
            f'stroke="{stroke}" stroke-width="1.1" stroke-linejoin="round"/>')


def flow_x(lang, W, widths, gap, margin):
    """Left edges of panels laid out in reading order."""
    xs, x = [], margin
    for w in widths:
        xs.append(x)
        x += w + gap
    if lang == "ar":
        xs = [W - xx - w for xx, w in zip(xs, widths)]
    return xs


# --- 08-01 study-concepts ---------------------------------------------------------------

T_SCON = {
    "subj": {"ar": "المشارك", "en": "Participant"},
    "g1": {"ar": ["نفس المعدل", "والنافذة"], "en": ["Same rate", "and window"]},
    "g2": {"ar": ["نفس القنوات", "والأحداث"], "en": ["Same channels", "and events"]},
    "g3": {"ar": ["نفس خطوات", "المعالجة"], "en": ["Same processing", "steps"]},
    "stop": {"ar": "معدله مختلف", "en": "Different rate"},
    "aria": {
        "ar": "أربعة ملفات .set لأربعة مشاركين تمر على ثلاث بوابات متتالية: نفس المعدل والنافذة، ثم نفس القنوات والأحداث، ثم نفس خطوات المعالجة. ملف المشارك 2 يقف عند البوابة الأولى بعلامة حمراء لأن معدله مختلف، والثلاثة الباقية تمر وتتصل بخطوط بملف واحد اسمه STUDY.",
        "en": "Four .set files from four participants pass three gates in a row: same rate and window, then same channels and events, then same processing steps. Participant 2's file stops at the first gate with a red mark because its sampling rate differs; the other three pass and are linked by lines to one file named STUDY.",
    },
}


def draw_study_concepts(out, lang):
    W, H = 720, 320
    rtl = lang == "ar"
    X = (lambda x: W - x) if rtl else (lambda x: x)
    side = lambda s: {"left": "right", "right": "left"}.get(s, s) if rtl else s
    red = "var(--status-danger, #B3261E)"
    body = [rect(0, 0, W, H, C["surface"])]
    lanes = [96, 146, 196, 246]
    gates = [270, 390, 510]
    sx, sy = 640, 171                      # STUDY icon centre
    # lanes first, so the gates sit on top of them
    for k, y in enumerate(lanes):
        if k == 1:
            body.append(line(X(154), y, X(gates[0] - 16), y, red, 1.6))
            continue
        xs_ = [154, 560, sx - 30]
        ys_ = [y, y, sy]
        body.append(path([X(v) for v in xs_], ys_, C["primary"], 1.6))
    for gx, key in zip(gates, ("g1", "g2", "g3")):
        body.append(rect(min(X(gx - 9), X(gx + 9)), 76, 18, 190, C["fill"], C["strong"], 1.2, rx=4))
        for i, s in enumerate(T_SCON[key][lang]):
            body.append(label(X(gx), 36 + i * 18, s, lang, 12.5, weight=600 if i == 0 else 400))
    # participant files
    for k, y in enumerate(lanes):
        bad = k == 1
        stroke = red if bad else C["strong"]
        body.append(rect(min(X(30), X(150)), y - 17, 120, 34, C["surface"], stroke, 1.2, rx=6))
        fx = X(40) - (13 if rtl else 0)
        body.append(file_icon(fx, y - 8, 13, 16, C["muted"]))
        body.append(label(X(62), y + 5, f"{T_SCON['subj'][lang]} {k + 1}", lang, 12.5, side=side("left")))
    # red mark where file 2 stops
    mx, my = X(gates[0] - 22), lanes[1]
    body.append(f'<circle cx="{mx:.1f}" cy="{my}" r="9" fill="{red}"/>')
    body.append(f'<path d="M{mx - 3.5:.1f},{my - 3.5} l7,7 m0,-7 l-7,7" stroke="var(--color-primary-on, #FFFFFF)" '
                f'stroke-width="1.8" stroke-linecap="round"/>')
    body.append(label(X(gates[0] - 40), my + 26, T_SCON["stop"][lang], lang, 12, red, side=side("right"), weight=600))
    # STUDY file
    iw, ih = 44, 56
    ix = X(sx) - iw / 2
    body.append(file_icon(ix, sy - ih / 2, iw, ih, C["primary"], C["info"]))
    body.append(code(X(sx), sy + ih / 2 + 20, "STUDY", 14, C["primary"], weight=600))
    save(out, f"study-concepts/study-concepts-gates.{lang}.svg", svg(W, H, body, T_SCON["aria"][lang]))


# Participant codes of the ready STUDY and their gender, from code/bids_export_animal.m in ds002680
D6_CODES = [("cba", "F"), ("clm", "F"), ("ega", "F"), ("fsa", "M"), ("gro", "M"), ("hth", "M"), ("lmi", "F"),
            ("mba", "F"), ("mma", "M"), ("mta", "F"), ("pla", "M"), ("sce", "F"), ("sph", "M"), ("wpa", "M")]
GROUP_FILL = {"F": C["rec"], "M": C["core"]}


def mirror(lang, W):
    """x mapping and side mapping for drawings that are laid out once and mirrored in Arabic."""
    if lang == "ar":
        return (lambda x: W - x), (lambda s: {"left": "right", "right": "left"}.get(s, s))
    return (lambda x: x), (lambda s: s)


def hbox(X, x0, x1, y, h, **kw):
    """rect between two logical x positions, correct after mirroring."""
    a, b = sorted((X(x0), X(x1)))
    return rect(a, y, b - a, h, **kw)


# --- 08-02 create-study ------------------------------------------------------------------

T_CREATE = {
    "before": {"ar": "قبل: 28 ملفاً في 14 مجلداً", "en": "Before: 28 files in 14 folders"},
    "after": {"ar": "بعد: جدول واحد", "en": "After: one table"},
    "subj": {"ar": "المشارك", "en": "Subject"},
    "group": {"ar": "المجموعة", "en": "Group"},
    "aria": {
        "ar": "قبل: 28 ملف .set صغيراً في 14 مجلداً، على كل مجلد رمز مشارك من cba إلى wpa، وفي كل مجلد ملفان. بعد: مخطط جدول فيه ثلاثة صفوف للمشاركين cba و clm و ega ثم صف نقاط، وعموداه الشرطان animal و distractor، وعمود ضيق للمجموعة F أو M بلونين. سهم من الملفات إلى الجدول، وتحته ملف واحد اسمه animal_mine.study.",
        "en": "Before: 28 small .set files in 14 folders, each folder labelled with a participant code from cba to wpa, two files per folder. After: a sketch of a table with rows for the participants cba, clm and ega and then a row of dots, the conditions animal and distractor as columns, and a narrow group column, F or M, in two colours. An arrow leads from the files to the table, and under it is one file named animal_mine.study.",
    },
}


def draw_create_study(out, lang):
    W, H = 720, 420
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    bw, tw = 210, 410
    xa, xb = flow_x(lang, W, [bw, tw], W - 32 - bw - tw, 16)
    body.append(label(xa + bw / 2, 30, T_CREATE["before"][lang], lang, 14.5, weight=600))
    body.append(label(xb + tw / 2, 30, T_CREATE["after"][lang], lang, 14.5, weight=600))
    # folders: two columns of seven, the listing itself stays LTR
    for k, (c, _) in enumerate(D6_CODES):
        col, row = divmod(k, 7)
        x, y = xa + 6 + col * 106, 50 + row * 52
        body.append(folder_icon(x, y, 24, 17))
        body.append(code(x + 30, y + 14, c, 12, weight=600, side="left"))
        for j in range(2):
            body.append(file_icon(x + 8 + j * 16, y + 24, 10, 13, C["muted"]))
    # arrow
    ay = 220
    if rtl:
        body.append(arrow(xa - 8, ay, xb + tw + 6))
    else:
        body.append(arrow(xa + bw + 8, ay, xb - 6))
    # table: subject, animal, distractor, group (LTR, like the STUDY window)
    tx, ty, rh = xb, 110, 30
    cols = [80, 135, 135, 60]
    edges = np.cumsum([0] + cols) + tx
    shown = D6_CODES[:3]
    th = rh * (len(shown) + 2)
    body.append(rect(tx, ty, tw, th, C["surface"], C["text"], 1.3, rx=6))
    body.append(label(tx + cols[0] / 2, ty + 19, T_CREATE["subj"][lang], lang, 12, C["muted"]))
    body.append(code((edges[1] + edges[2]) / 2, ty + 19, "animal", 12.5, weight=600))
    body.append(code((edges[2] + edges[3]) / 2, ty + 19, "distractor", 12.5, weight=600))
    body.append(label((edges[3] + edges[4]) / 2, ty + 19, T_CREATE["group"][lang], lang, 11, C["muted"]))
    for k, (c, g) in enumerate(shown):
        y = ty + rh * (k + 1)
        body.append(line(tx, y, tx + tw, y, C["sep"] if k else C["text"], 1))
        body.append(rect(edges[3] + 1, y + 1, cols[3] - 2, rh - 2, GROUP_FILL[g], opacity=0.16))
        body.append(code(tx + cols[0] / 2, y + 20, c, 12, weight=600))
        for j in (1, 2):
            body.append(file_icon(edges[j] + cols[j] / 2 - 6, y + 7, 12, 16, C["primary"], C["info"]))
        body.append(code((edges[3] + edges[4]) / 2, y + 20, g, 12, GROUP_FILL[g], weight=600))
    y = ty + rh * (len(shown) + 1)
    body.append(line(tx, y, tx + tw, y, C["sep"], 1))
    for j in range(4):
        body.append(latin((edges[j] + edges[j + 1]) / 2, y + 19, "…", 15, C["muted"]))
    for x in edges[1:-1]:
        body.append(line(x, ty, x, ty + th, C["sep"], 1))
    # saved study file
    fy = ty + th + 34
    body.append(varrow(tx + tw / 2, ty + th + 4, fy - 6, C["text"]))
    body.append(file_icon(tx + tw / 2 - 84, fy, 16, 20, C["primary"], C["info"]))
    body.append(code(tx + tw / 2 - 60, fy + 15, "animal_mine.study", 13, C["primary"], weight=600, side="left"))
    save(out, f"create-study/create-study-files.{lang}.svg", svg(W, H, body, T_CREATE["aria"][lang]))


# --- 08-03 study-from-bids --------------------------------------------------------------

T_SBIDS = {
    "before": {"ar": "قبل: مجلد BIDS", "en": "Before: the BIDS folder"},
    "after": {"ar": "بعد: STUDY", "en": "After: the STUDY"},
    "faded": {"ar": "لم نُنزّلهما", "en": "not downloaded"},
    "aria": {
        "ar": "قبل: شجرة ds002680 فيها participants.tsv و dataset_description.json، ثم المجلدات sub-002 و sub-003 و sub-004 و sub-005، والأوسطان باهتان لأننا لم ننزّلهما. تحت sub-002 و sub-005 المسار ses-01/eeg وملف التشغيل 1. بجانب participants.tsv جدول صغير فيه صفان مظلّلان: sub-002 F و sub-005 M. بعد: ملف gonogo_bids.study في derivatives/eeglab، ومنه سهمان إلى صفين في جدول STUDY.datasetinfo، في كل صف subject و session و run و gender: sub-002 و 1 و 1 و F، ثم sub-005 و 1 و 1 و M.",
        "en": "Before: the ds002680 tree with participants.tsv and dataset_description.json, then the folders sub-002, sub-003, sub-004 and sub-005, the middle two faded because we did not download them. Under sub-002 and sub-005 the path ses-01/eeg and the run-1 file. Next to participants.tsv a small table with two shaded rows: sub-002 F and sub-005 M. After: a gonogo_bids.study file in derivatives/eeglab, with two arrows to two rows of a STUDY.datasetinfo table, each showing subject, session, run and gender: sub-002, 1, 1, F and sub-005, 1, 1, M.",
    },
}


def draw_study_from_bids(out, lang):
    W, H = 720, 420
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    widths = [372, 250]
    xt, xs = flow_x(lang, W, widths, W - 32 - sum(widths), 16)
    body.append(label(xt + widths[0] / 2, 28, T_SBIDS["before"][lang], lang, 14.5, weight=600))
    body.append(label(xs + widths[1] / 2, 28, T_SBIDS["after"][lang], lang, 14.5, weight=600))
    run = "_ses-01_task-gonogo_run-1_eeg.set"
    rows = [(0, "ds002680/", True, ""), (1, "participants.tsv", False, "rec"), (1, "dataset_description.json", False, ""),
            (1, "sub-002/", True, ""), (2, "ses-01/eeg/", True, ""), (3, "sub-002" + run, False, "hl"),
            (1, "sub-003/", True, "ghost"), (1, "sub-004/", True, "ghost"),
            (1, "sub-005/", True, ""), (2, "ses-01/eeg/", True, ""), (3, "sub-005" + run, False, "hl")]
    x0, y0, rh, ind = xt + 2, 62, 30, 18
    parent_y = {}
    for i, (lvl, name, folder, style) in enumerate(rows):
        y = y0 + i * rh
        x = x0 + lvl * ind
        if lvl > 0:
            body.append(path([x - ind + 7, x - ind + 7, x - 4], [parent_y[lvl - 1] + 8, y, y], C["sep"], 1))
        if folder:
            parent_y[lvl] = y
            body.append(folder_icon(x, y - 9, 18, 14, C["sep"] if style == "ghost" else None))
        else:
            body.append(file_icon(x + 3, y - 9, 11, 14, C["primary"] if style == "hl" else C["muted"],
                                  C["info"] if style == "hl" else None))
        fill = {"hl": C["primary"], "rec": C["rec"], "ghost": C["sep"]}.get(style, C["text"])
        body.append(code(x + 24, y + 3, name, 10.5, fill, weight=600 if folder or style == "hl" else 400, side="left"))
    body.append(label(x0 + ind + 90, y0 + 6.5 * rh + 5, T_SBIDS["faded"][lang], lang, 12, C["muted"], side="left"))
    # participants.tsv excerpt, next to the file (two shaded rows)
    px, py_ = x0 + 206, y0 - 12
    body.append(rect(px, py_, 150, 66, C["surface"], C["strong"], 1, rx=5))
    body.append(code(px + 8, py_ + 15, "participant_id", 9, C["muted"], side="left"))
    body.append(code(px + 142, py_ + 15, "gender", 9, C["muted"], side="right"))
    for k, (s, g) in enumerate((("sub-002", "F"), ("sub-005", "M"))):
        y = py_ + 22 + k * 21
        body.append(rect(px + 3, y, 144, 19, GROUP_FILL[g], rx=3, opacity=0.16))
        body.append(code(px + 8, y + 14, s, 11, side="left"))
        body.append(code(px + 128, y + 14, g, 11, GROUP_FILL[g], weight=600))
    body.append(line(x0 + ind + 24 + 16 * 6.35 + 6, y0 + rh, px - 4, y0 + rh, C["rec"], 1, "2 2"))
    # arrow between the panels
    ay = 160
    if rtl:
        a0, a1 = xt - 6, xs + widths[1] + 6
    else:
        a0, a1 = xt + widths[0] + 6, xs - 6
    body.append(arrow(a0, ay, a1, C["primary"], 1.6))
    # after: the study file in derivatives/eeglab, then the datasetinfo rows
    sx = xs + 8
    body.append(folder_icon(sx, 56, 18, 14))
    body.append(code(sx + 24, 68, "derivatives/eeglab/", 10.5, weight=600, side="left"))
    body.append(file_icon(sx + 26, 86, 16, 20, C["primary"], C["info"]))
    body.append(code(sx + 50, 101, "gonogo_bids.study", 12, C["primary"], weight=600, side="left"))
    tx, ty = xs + 6, 200
    cols = [78, 60, 40, 60]
    edges = np.cumsum([0] + cols) + tx
    tw = sum(cols)
    body.append(code(tx, ty - 10, "STUDY.datasetinfo", 11, C["muted"], side="left"))
    body.append(rect(tx, ty, tw, 26 * 3, C["surface"], C["text"], 1.2, rx=5))
    for j, h in enumerate(("subject", "session", "run", "gender")):
        body.append(code((edges[j] + edges[j + 1]) / 2, ty + 17, h, 10.5, C["muted"]))
    for k, (s, g) in enumerate((("sub-002", "F"), ("sub-005", "M"))):
        y = ty + 26 * (k + 1)
        body.append(line(tx, y, tx + tw, y, C["sep"], 1))
        body.append(rect(edges[3] + 1, y + 1, cols[3] - 2, 24, GROUP_FILL[g], opacity=0.16))
        for j, v in enumerate((s, "1", "1", g)):
            body.append(code((edges[j] + edges[j + 1]) / 2, y + 17, v, 11.5, GROUP_FILL[g] if j == 3 else C["text"],
                             weight=600 if j in (0, 3) else 400))
    # two arrows from the study file to its two rows, entering from the right edge of the table
    ex = tx + tw + 14
    body.append(path([sx + 50 + 17 * 7.2 + 6, ex, ex], [97, 97, ty + 26 * 2 + 13], C["primary"], 1.1))
    for k in range(2):
        body.append(arrow(ex, ty + 26 * (k + 1) + 13, tx + tw + 2, C["primary"], 1.1))
    save(out, f"study-from-bids/study-from-bids-tree.{lang}.svg", svg(W, H, body, T_SBIDS["aria"][lang]))


# --- 08-04 study-design ------------------------------------------------------------------

T_DESIGN = {
    "within": {"ar": "داخل المشارك", "en": "Within subjects"},
    "between": {"ar": "بين المجموعات", "en": "Between subjects"},
    "paired": {"ar": "نفس المشاركين:", "en": "same participants:"},
    "unpaired": {"ar": "مشاركون مختلفون:", "en": "different participants:"},
    "aria": {
        "ar": "شبكة 2×2. العمودان animal و distractor مظلّلان بلونين، وهما متغيّر داخل المشارك، وبينهما سهم مزدوج مكتوب عليه نفس المشاركين: paired. الصفان F و M متغيّر بين المجموعات، وبينهما خط فاصل مكتوب عليه مشاركون مختلفون: unpaired. في كل خلية دوائر صغيرة برموز المشاركين: سبع في كل صف، ونفس الدوائر تتكرر في العمودين.",
        "en": "A 2×2 grid. The columns animal and distractor are shaded in two colours, a within-subjects factor, with a double arrow between them labelled same participants: paired. The rows F and M are a between-subjects factor, separated by a dividing line labelled different participants: unpaired. Each cell holds small circles with participant codes: seven per row, and the same circles repeat in both columns.",
    },
}


def draw_study_design(out, lang):
    W, H = 720, 330
    X, S = mirror(lang, W)
    body = [rect(0, 0, W, H, C["surface"])]
    hw, cw, rh = 70, 210, 112
    x_head, x_c1, x_c2, x_end = 24, 24 + hw, 24 + hw + cw, 24 + hw + 2 * cw
    ty = 104
    col_fill = (C["core"], C["primary"])
    for (x0, name), f in zip(((x_c1, "animal"), (x_c2, "distractor")), col_fill):
        body.append(hbox(X, x0 + 3, x0 + cw - 3, ty - 34, 34 + 2 * rh, fill=f, rx=8, opacity=0.08))
        body.append(code(X(x0 + cw / 2), ty - 12, name, 13.5, f, weight=600))
    # within: double arrow across the column boundary
    mid = X(x_c2)
    body.append(label(X(x_c1 + cw), 26, T_DESIGN["within"][lang], lang, 14.5, C["core"], weight=600))
    body.append(arrow(mid - 30, 50, mid + 30, C["core"], 1.3))
    body.append(arrow(mid + 30, 50, mid - 30, C["core"], 1.3))
    body.append(label(X(x_c2 - 40), 55, T_DESIGN["paired"][lang], lang, 12.5, C["muted"], side=S("right")))
    body.append(code(X(x_c2 + 40), 55, "paired", 12, C["core"], weight=600, side=S("left")))
    # rows and the circles
    groups = {"F": [c for c, g in D6_CODES if g == "F"], "M": [c for c, g in D6_CODES if g == "M"]}
    for k, g in enumerate(("F", "M")):
        y = ty + k * rh
        body.append(code(X(x_head + hw / 2), y + rh / 2 + 5, g, 16, GROUP_FILL[g], weight=600))
        for x0 in (x_c1, x_c2):
            for i, c in enumerate(groups[g]):
                r_, q = divmod(i, 4)
                cx = x0 + 36 + q * 46 + (23 if r_ else 0)
                cy = y + 34 + r_ * 44
                body.append(f'<circle cx="{X(cx):.1f}" cy="{cy}" r="17" fill="{C["surface"]}" stroke="{GROUP_FILL[g]}" stroke-width="1.4"/>')
                body.append(code(X(cx), cy + 4, c, 10.5, weight=600))
    # between: dividing line between the rows, labelled at its end
    yl = ty + rh
    body.append(line(X(x_head), yl, X(x_end + 10), yl, C["text"], 1.6, "6 4"))
    body.append(label(X(x_end + 18), yl - 6, T_DESIGN["unpaired"][lang], lang, 12.5, C["muted"], side=S("left")))
    body.append(code(X(x_end + 18), yl + 14, "unpaired", 12, C["text"], weight=600, side=S("left")))
    body.append(label(X(x_end + 18), yl - 40, T_DESIGN["between"][lang], lang, 14, weight=600, side=S("left")))
    save(out, f"study-design/study-design-2x2.{lang}.svg", svg(W, H, body, T_DESIGN["aria"][lang]))


# --- 08-05 study-precompute --------------------------------------------------------------

T_PRE = {
    "before": {"ar": "قبل الحساب", "en": "Before precomputing"},
    "after": {"ar": "بعد الحساب", "en": "After precomputing"},
    "old": {"ar": "قديمة، لا تُستعمل", "en": "old, not used"},
    "new": {"ar": "ملفات جديدة", "en": "new files"},
    "size": {"ar": "طول الشريط = حجم الملف", "en": "Bar length = file size"},
    "est": {"ar": "طول الشريط = حجم الملف (تقدير قبل القياس)", "en": "Bar length = file size (estimate, not yet measured)"},
    "aria": {
        "ar": "قبل الحساب: مجلد المشارك sph فيه sphanimal.set و sphdistractor.set مع ملفي بياناتهما .dat، وتحتها باهتة ملفات EEGLAB 6 القديمة مثل sphanimal.daterp و sphanimal.icaerp بوسم قديمة، لا تُستعمل. بعد الحساب: نفس المجلد وفيه أيضاً ثلاثة ملفات جديدة مظلّلة: sph.daterp بحجم {0} MB، و sph.datspec بحجم {1} MB، و sph.dattimef بحجم {2} MB، وبجانب كل ملف شريط بطول حجمه.",
        "en": "Before precomputing: participant sph's folder holds sphanimal.set and sphdistractor.set with their .dat data files, and below them, faded, old EEGLAB 6 files such as sphanimal.daterp and sphanimal.icaerp, labelled old, not used. After: the same folder also holds three new shaded files: sph.daterp ({0} MB), sph.datspec ({1} MB) and sph.dattimef ({2} MB), each with a bar as long as its size.",
    },
}


# Sizes in MB of sph's precomputed files. Estimates until the run day; pass the measured ones with --precompute-mb.
PRECOMP_MB_ESTIMATE = (31, 16, 26)
PRECOMP_SETS = ("sphanimal.set", "sphanimal.dat", "sphdistractor.set", "sphdistractor.dat")
PRECOMP_OLD = ("sphanimal.daterp", "sphanimal.icaerp", "…")


def draw_study_precompute(out, lang, mb=None):
    measured = mb is not None
    mb = mb or PRECOMP_MB_ESTIMATE
    W, H = 720, 456
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    widths = [220, 420]
    xa, xb = flow_x(lang, W, widths, W - 32 - sum(widths), 16)
    for x, w, key in ((xa, widths[0], "before"), (xb, widths[1], "after")):
        body.append(label(x + w / 2, 30, T_PRE[key][lang], lang, 14.5, weight=600))
        body.append(rect(x, 46, w, 368 if key == "after" else 270, C["fill"], rx=10, opacity=0.4))
        body.append(folder_icon(x + 14, 60, 22, 16))
        body.append(code(x + 44, 73, "sph/", 13, weight=600, side="left"))

    def listing(x, w):
        b = []
        for j, name in enumerate(PRECOMP_SETS):
            y = 102 + j * 24
            b.append(file_icon(x + 34, y - 11, 11, 14, C["text"]))
            b.append(code(x + 54, y, name, 11.5, side="left"))
        # old EEGLAB 6 files: faded, in a dashed box with their label
        b.append(rect(x + 24, 192, w - 40, 90, "none", C["strong"], 1, rx=6, dash="3 3", opacity=0.8))
        for j, name in enumerate(PRECOMP_OLD):
            y = 212 + j * 22
            if name != "…":
                b.append(file_icon(x + 34, y - 11, 11, 14, C["strong"]))
            b.append(code(x + 54, y, name, 11.5, C["strong"], side="left"))
        b.append(label(x + w / 2, 300, T_PRE["old"][lang], lang, 12, C["muted"]))
        return b
    body += listing(xa, widths[0])
    body += listing(xb, widths[1])
    unit = 180 / max(mb)
    for j, (name, v) in enumerate(zip(("sph.daterp", "sph.datspec", "sph.dattimef"), mb)):
        L = v * unit
        y = 340 + j * 28
        body.append(rect(xb + 26, y - 17, widths[1] - 40, 24, C["primary"], rx=5, opacity=0.1))
        body.append(file_icon(xb + 34, y - 11, 11, 14, C["primary"], C["info"]))
        body.append(code(xb + 54, y, name, 11.5, C["primary"], weight=600, side="left"))
        body.append(rect(xb + 160, y - 8, L, 9, C["primary"], rx=2))
        body.append(code(xb + 168 + L, y, f"{v:g} MB", 11, C["muted"], side="left"))
    body.append(label(xb + widths[1] - 20, 318, T_PRE["new"][lang], lang, 12, C["primary"], weight=600, side="right"))
    body.append(label(W / 2, 442, T_PRE["size" if measured else "est"][lang], lang, 12, C["muted"]))
    ay = 150
    if rtl:
        body.append(arrow(xa - 6, ay, xb + widths[1] + 6))
    else:
        body.append(arrow(xa + widths[0] + 6, ay, xb - 6))
    aria = T_PRE["aria"][lang].format(*(f"{v:g}" for v in mb))
    save(out, f"study-precompute/study-precompute-files.{lang}.svg", svg(W, H, body, aria))


# --- 08-10 limo --------------------------------------------------------------------------

T_LIMO = {
    "l1": {"ar": "المستوى الأول: نموذج لكل مشارك", "en": "1st level: one model per participant"},
    "first": {"ar": "مستوى 1", "en": "1st level"},
    "trials": {"ar": "المحاولات المفردة", "en": "single trials"},
    "l2": {"ar": "المستوى الثاني: اختبار paired عبر المشاركين", "en": "2nd level: paired test across participants"},
    "chans": {"ar": "القنوات", "en": "Channels"},
    "time": {"ar": "الزمن", "en": "Time"},
    "clusters": {"ar": "كتل دالّة", "en": "significant clusters"},
    "aria": {
        "ar": "مستويان في LIMO. في الأعلى 14 مربعاً صغيراً، مربع لكل مشارك من cba إلى wpa، مكتوب على كل منها المستوى الأول، وفيها منحنيات محاولات رفيعة كثيرة تتحول إلى عمودين قصيرين: beta animal و beta distractor. أسهم تنزل إلى مربع عريض: المستوى الثاني، اختبار paired عبر المشاركين، وينتهي بصورة صغيرة للقنوات مقابل الزمن فيها بقع ملوّنة قليلة عليها كتل دالّة. الشكل توضيحي بلا بيانات.",
        "en": "Two levels in LIMO. At the top, 14 small boxes, one per participant from cba to wpa, each labelled 1st level, with many thin trial curves turning into two short bars, beta animal and beta distractor. Arrows lead down to one wide box, 2nd level: paired test across participants, which ends in a small channels by time image with a few coloured patches marked significant clusters. Illustrative, no data.",
    },
}


def draw_limo(out, lang):
    W, H = 720, 470
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    rng = np.random.default_rng(7)
    cols = (C["core"], C["rec"])
    body.append(label(W / 2, 28, T_LIMO["l1"][lang], lang, 15, weight=600))
    # legend for the two bars
    lx = W / 2 - 120
    for k, name in enumerate(("beta animal", "beta distractor")):
        x = lx + (k if not rtl else 1 - k) * 130
        body.append(rect(x, 42, 10, 10, cols[k], rx=2))
        body.append(code(x + 16, 51, name, 11, cols[k], weight=600, side="left"))
    # 14 participant boxes, in reading order
    n, bw, gap, x0 = 14, 44, 5.4, 14
    by, bh = 66, 124
    t = np.linspace(0, 1, 16)
    centres = []
    for i, (codev, _) in enumerate(D6_CODES):
        k = i if not rtl else n - 1 - i
        x = x0 + k * (bw + gap)
        centres.append(x + bw / 2)
        body.append(rect(x, by, bw, bh, C["surface"], C["strong"], 1, rx=6))
        body.append(code(x + bw / 2, by + 14, codev, 9.5, weight=600))
        body.append(label(x + bw / 2, by + 27, T_LIMO["first"][lang], lang, 7.5, C["muted"]))
        for j in range(4):
            v = 0.5 * np.sin(2 * np.pi * (t * 1.5 + rng.uniform())) + rng.normal(0, 0.25, t.size)
            body.append(path(x + 5 + t * (bw - 10), by + 46 + j * 3 - v * 4, C["sep"], 0.7, nd=0))
        body.append(varrow(x + bw / 2, by + 66, by + 80, C["muted"], 0.9))
        ba = rng.uniform(1.6, 2.6)
        bd = max(0.4, ba - rng.uniform(0.3, 1.1))
        base = by + bh - 10
        for j, v in enumerate((ba, bd)):
            body.append(rect(x + 10 + j * 14, base - v * 11, 10, v * 11, cols[j], rx=1.5))
        body.append(line(x + 6, base, x + bw - 6, base, C["strong"], 0.8))
    # arrows down to the second level
    gx, gy, gw, gh = 90, 250, 540, 200
    for cx in [centres[i] for i in (0, 4, 9, 13)]:
        body.append(line(cx, by + bh + 4, W / 2 + (cx - W / 2) * 0.45, gy - 4, C["muted"], 0.9))
    body.append(rect(gx, gy, gw, gh, C["info"], C["primary"], 1.8, rx=10))
    body.append(label(W / 2, gy + 26, T_LIMO["l2"][lang], lang, 14.5, C["primary"], weight=600))
    # channels x time image (time runs left to right in both languages)
    ix, iy, iw, ih = gx + 100, gy + 46, 260, 120
    nr, nc = 15, 40
    cw_, ch_ = iw / nc, ih / nr
    body.append(rect(ix, iy, iw, ih, C["fill"], C["strong"], 1))
    patches = [(3, 6, 14, 22), (9, 12, 18, 25), (5, 8, 30, 35)]
    for r0, r1, c0, c1 in patches:
        body.append(rect(ix + c0 * cw_, iy + r0 * ch_, (c1 - c0) * cw_, (r1 - r0) * ch_, C["primary"], rx=3, opacity=0.75))
    body.append(label(ix + iw / 2, iy + ih + 18, T_LIMO["time"][lang], lang, 11.5, C["muted"]))
    body.append(label(ix - 8, iy + ih / 2 + 4, T_LIMO["chans"][lang], lang, 11.5, C["muted"], side="right"))
    # callout to the patches
    r0, r1, c0, c1 = patches[2]
    px, py_ = ix + c1 * cw_, iy + (r0 + r1) / 2 * ch_
    body.append(line(px + 2, py_, ix + iw + 22, py_, C["primary"], 1))
    body.append(label(ix + iw + 28, py_ + 4, T_LIMO["clusters"][lang], lang, 12, C["primary"], weight=600, side="left"))
    save(out, f"limo/limo-two-levels.{lang}.svg", svg(W, H, body, T_LIMO["aria"][lang]))


# --- 01-04 alleeg-datasets -------------------------------------------------------------

T_ALLEEG = {
    "ch32": {"ar": "فيها 32 قناة", "en": "32 channels"},
    "ch30": {"ar": "فيها 30 قناة", "en": "30 channels"},
    "shelf": {"ar": "الرف: كل الداتاست في الذاكرة", "en": "The shelf: every dataset in memory"},
    "current": {"ar": "رقم الداتاست الحالية", "en": "Number of the current dataset"},
    "copy": {"ar": "نسخة الداتاست الحالية التي تعمل عليها", "en": "Copy of the current dataset you work on"},
    "aria": {
        "ar": "رف اسمه ALLEEG عليه صندوقان: 1 هو Continuous EEG Data بـ 32 قناة، و 2 هو D1 no EOG بـ 30 قناة. سهم CURRENTSET = 2 يشير إلى الصندوق 2، ونسخة منه أمام الرف اسمها EEG.",
        "en": "A shelf named ALLEEG holding two boxes: 1 is Continuous EEG Data with 32 channels, 2 is D1 no EOG with 30 channels. An arrow CURRENTSET = 2 points at box 2, and a copy of it in front of the shelf is named EEG.",
    },
}


def dataset_box(x, y, w, h, num, name, sub, lang, stroke, fill):
    b = [rect(x, y, w, h, fill, stroke, 1.5, rx=8)]
    b.append(f'<circle cx="{x + 18}" cy="{y + 18}" r="11" fill="{stroke}"/>')
    b.append(latin(x + 18, y + 22.5, num, 12, "var(--color-primary-on, #FFFFFF)", weight=600))
    b.append(code(x + w / 2 + 8, y + h / 2 + 2, name, 12.5, weight=600))
    b.append(label(x + w / 2 + 8, y + h / 2 + 24, sub, lang, 13, C["muted"]))
    return b


def draw_alleeg(out, lang):
    W, H = 720, 360
    body = [rect(0, 0, W, H, C["surface"])]
    bw, bh, py = 210, 84, 196
    bx = [150, 390]
    # shelf plank and its label
    body.append(rect(110, py, 530, 12, C["strong"], rx=3, opacity=0.5))
    body.append(line(130, py + 12, 130, py + 40, C["strong"], 3) + line(620, py + 12, 620, py + 40, C["strong"], 3))
    body.append(code(146, py + 34, "ALLEEG", 15, weight=600, side="left"))
    body.append(label(146, py + 56, T_ALLEEG["shelf"][lang], lang, 12.5, C["muted"], side="left"))
    body += dataset_box(bx[0], py - bh - 4, bw, bh, "1", "Continuous EEG Data", T_ALLEEG["ch32"][lang], lang, C["strong"], C["surface"])
    body += dataset_box(bx[1], py - bh - 4, bw, bh, "2", "D1 no EOG", T_ALLEEG["ch30"][lang], lang, C["primary"], C["info"])
    # CURRENTSET arrow
    ax = bx[1] + bw / 2
    body.append(varrow(ax, 52, py - bh - 10, C["primary"], 1.6))
    body.append(code(ax + 12, 50, "CURRENTSET = 2", 13.5, C["primary"], weight=600, side="left"))
    body.append(label(ax + 12, 72, T_ALLEEG["current"][lang], lang, 12.5, C["muted"], side="left"))
    # EEG copy in front of the shelf
    cy = py + 52
    body.append(line(ax, py + 14, ax, cy, C["primary"], 1.2, "4 3"))
    body.append(rect(bx[1], cy, bw, 64, C["surface"], C["primary"], 2, rx=8))
    body.append(code(bx[1] + bw / 2, cy + 26, "EEG", 15, C["primary"], weight=600))
    body.append(code(bx[1] + bw / 2, cy + 48, "D1 no EOG", 11.5, C["muted"]))
    body.append(label(bx[1] - 14, cy + 36, T_ALLEEG["copy"][lang], lang, 12.5, C["muted"], side="right"))
    save(out, f"alleeg-datasets/alleeg-shelf.{lang}.svg", svg(W, H, body, T_ALLEEG["aria"][lang]))


# --- 01-05 set-fdt-files ---------------------------------------------------------------

T_FILES = {
    "set": {"ar": ["الوصف: القنوات والأحداث", "ومعدل العيّنات والسجل"], "en": ["Description: channels,", "events, srate, history"]},
    "fdt": {"ar": "الإشارة: قنوات × عيّنات", "en": "Signal: channels × samples"},
    "link": {"ar": "نفس الاسم، نفس المجلد", "en": "Same name, same folder"},
    "one": {"ar": ["ملف واحد: الوصف", "والإشارة معاً", "(الإعداد الافتراضي)"], "en": ["One file: description", "and signal together", "(the default)"]},
    "mine": {"ar": "مجلد دروسك", "en": "Your lessons folder"},
    "two": {"ar": "ملفان", "en": "Two files"},
    "single": {"ar": "ملف واحد", "en": "One file"},
    "aria": {
        "ar": "مجلد sample_data فيه ملفان بنفس الاسم: eeglab_data.set (حوالي 0.35 MB) فيه الوصف، و eeglab_data.fdt (حوالي 3.9 MB) فيه الإشارة 32 × 30504. وفي مجلد دروسك ملف واحد D1_copy.set (حوالي 4 MB) فيه الوصف والإشارة معاً، وهذا الإعداد الافتراضي.",
        "en": "The sample_data folder holds two files with the same name: eeglab_data.set (about 0.35 MB) with the description and eeglab_data.fdt (about 3.9 MB) with the 32 × 30504 signal. Your lessons folder holds one file, D1_copy.set (about 4 MB), with description and signal together, which is the default.",
    },
}


def file_card(x, y, w, name, size, lines, lang, stroke=None, h=124):
    stroke = stroke or C["text"]
    b = [rect(x, y, w, h, C["surface"], stroke, 1.4, rx=8)]
    b.append(file_icon(x + 12, y + 12, 16, 20, stroke, C["info"]))
    b.append(code(x + 36, y + 27, name, 12.5, weight=600, side="left"))
    b.append(code(x + 36, y + 45, size, 11.5, C["muted"], side="left"))
    for i, (s, is_code) in enumerate(lines):
        yy = y + 72 + i * 20
        b.append(code(x + w / 2, yy, s, 12, C["primary"]) if is_code else label(x + w / 2, yy, s, lang, 12.5, C["muted"]))
    return b


def draw_set_fdt(out, lang):
    W, H = 720, 320
    body = [rect(0, 0, W, H, C["surface"])]
    pa, pb = (20, 474) if lang == "en" else (246, 20)   # sample_data panel (wide), your folder panel
    wa, wb = 454, 226
    for x, w, name, head in ((pa, wa, "sample_data/", "two"), (pb, wb, None, "single")):
        body.append(rect(x + 3, 54, w - 6, 250, C["fill"], rx=12, opacity=0.45))
        body.append(folder_icon(x + 16, 66))
        if name:
            body.append(code(x + 50, 80, name, 13, weight=600, side="left"))
        else:
            body.append(label(x + 50, 80, T_FILES["mine"][lang], lang, 13.5, weight=600, side="left"))
        body.append(label(x + w / 2, 34, T_FILES[head][lang], lang, 15, weight=600))
    cw = 196
    xs = [pa + 20, pa + wa - 20 - cw]
    if lang == "ar":
        xs = xs[::-1]
    body += file_card(xs[0], 104, cw, "eeglab_data.set", "≈ 0.35 MB", [(s, False) for s in T_FILES["set"][lang]], lang)
    body += file_card(xs[1], 104, cw, "eeglab_data.fdt", "≈ 3.9 MB", [(T_FILES["fdt"][lang], False), ("32 × 30504", True)], lang)
    x1, x2 = min(xs) + cw, max(xs)
    body.append(line(x1, 131, x2, 131, C["primary"], 2, "5 3"))
    body.append(line(pa + wa / 2, 135, pa + wa / 2, 254, C["primary"], 1, "2 3"))
    body.append(label(pa + wa / 2, 274, T_FILES["link"][lang], lang, 13, C["primary"], weight=600))
    body += file_card(pb + 15, 104, 196, "D1_copy.set", "≈ 4 MB", [(s, False) for s in T_FILES["one"][lang]], lang, C["primary"], h=144)
    save(out, f"set-fdt-files/set-fdt-files.{lang}.svg", svg(W, H, body, T_FILES["aria"][lang]))


# --- 02-04 bids-openneuro --------------------------------------------------------------

T_BIDS = {
    "desc": {"ar": "اسم الداتاست ورخصتها", "en": "Dataset name and licence"},
    "readme": {"ar": "وصف التجربة", "en": "What the study did"},
    "evjson": {"ar": "معنى أعمدة ملفات الأحداث", "en": "What the events columns mean"},
    "sub": {"ar": "مجلد لكل مشارك", "en": "One folder per participant"},
    "eeg": {"ar": "بيانات EEG لهذا المشارك", "en": "This participant's EEG"},
    "set": {"ar": "الإشارة، حوالي 235 ميغابايت", "en": "The signal (about 235 MB)"},
    "json": {"ar": "التسجيل: 250 هرتز، كهرباء 50 هرتز، مرجع الأنف", "en": "Recording: 250 Hz, 50 Hz mains, nose reference"},
    "chan": {"ar": "أسماء القنوات الـ 74 وأنواعها", "en": "74 channels: name and type"},
    "elec": {"ar": "مكان كل قطب في الفراغ", "en": "x, y, z position of each electrode"},
    "events": {"ar": "الأحداث، 1479 حدثاً، حدث في كل سطر", "en": "1479 events, one per line"},
    "aria": {
        "ar": "شجرة مجلد ds002718: في الجذر dataset_description.json و README و task-FaceRecognition_events.json، ثم sub-002 ثم eeg وفيه خمسة ملفات: ملف الإشارة set بحوالي 235 MB، و eeg.json بتفاصيل التسجيل، و channels.tsv بأسماء 74 قناة، و electrodes.tsv بمواقع الأقطاب، و events.tsv بـ 1479 حدثاً.",
        "en": "Folder tree of ds002718: at the root dataset_description.json, README and task-FaceRecognition_events.json; then sub-002, then eeg with five files: the .set signal of about 235 MB, eeg.json with recording details, channels.tsv with 74 channel names, electrodes.tsv with electrode positions and events.tsv with 1479 events.",
    },
}


def draw_bids(out, lang):
    W, H = 720, 400
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    p = "sub-002_task-FaceRecognition_"
    rows = [(0, "ds002718/", None, True), (1, "dataset_description.json", "desc", False), (1, "README", "readme", False),
            (1, "task-FaceRecognition_events.json", "evjson", False), (1, "sub-002/", "sub", True),
            (2, "eeg/", "eeg", True), (3, p + "eeg.set", "set", False), (3, p + "eeg.json", "json", False),
            (3, p + "channels.tsv", "chan", False), (3, p + "electrodes.tsv", "elec", False),
            (3, p + "events.tsv", "events", False)]
    x0, y0, rh, ind = 24, 34, 33, 22
    dx = 438 if not rtl else W - 20
    parent_y = {}
    for i, (lvl, name, key, folder) in enumerate(rows):
        y = y0 + i * rh
        x = x0 + lvl * ind
        if lvl > 0:
            py_ = parent_y[lvl - 1]
            body.append(path([x - ind + 7, x - ind + 7, x - 4], [py_ + 8, y, y], C["sep"], 1))
        if folder:
            parent_y[lvl] = y
            body.append(folder_icon(x, y - 9, 18, 14))
        else:
            body.append(file_icon(x + 3, y - 9, 11, 14, C["muted"]))
        tx = x + 24
        hl = key in ("set", "json", "chan", "elec", "events")
        body.append(code(tx, y + 3, name, 11, C["text"], weight=600 if folder else 400, side="left"))
        if key:
            body.append(line(tx + len(name) * 6.65 + 6, y, dx - (0 if rtl else 8) if not rtl else 470, y, C["sep"], 0.8, "1 3"))
            body.append(label(dx if rtl else dx, y + 4.5, T_BIDS[key][lang], lang, 12.5, C["primary"] if hl else C["muted"],
                              side="right" if rtl else "left"))
    save(out, f"bids-openneuro/bids-tree.{lang}.svg", svg(W, H, body, T_BIDS["aria"][lang]))


# --- 04-01 ica-concept -----------------------------------------------------------------

T_ICAC = {
    "s1": {"ar": "المصادر", "en": "Sources"},
    "s2": {"ar": "ما تسجّله القنوات", "en": "What the channels record"},
    "s3": {"ar": "بعد ICA", "en": "After ICA"},
    "brain": {"ar": "دماغ", "en": "Brain"},
    "blink": {"ar": "رمش", "en": "Blink"},
    "muscle": {"ar": "عضلة", "en": "Muscle"},
    "front": {"ar": "أمامي", "en": "Frontal"},
    "central": {"ar": "مركزي", "en": "Central"},
    "temporal": {"ar": "صدغي", "en": "Temporal"},
    "mix": {"ar": "خلط في الرأس", "en": "Mixing in the head"},
    "flip": {"ar": "مقلوب الإشارة", "en": "sign flipped"},
    "aria": {
        "ar": "ثلاث مراحل. المصادر: دماغ بموجة 10 هرتز منتظمة، ورمش بقمم كبيرة بطيئة، وعضلة بنشاط سريع. ما تسجّله القنوات: ثلاثة أقطاب أمامي ومركزي وصدغي، كل منها خليط من الثلاثة، والأمامي فيه الرمش بقوة. بعد ICA: ثلاثة مكوّنات تشبه المصادر بترتيب مختلف، والرمش مقلوب الإشارة.",
        "en": "Three stages. Sources: brain with a regular 10 Hz wave, blink with large slow peaks, muscle with fast activity. What the channels record: frontal, central and temporal electrodes, each a mix of the three, the frontal one with a strong blink. After ICA: three components that look like the sources, in a different order, with the blink sign flipped.",
    },
}


def lesson_sources():
    """The three sources and the mixing matrix of the ica-concept lesson script (first 5 s, 128 Hz)."""
    srate = 128
    t = np.arange(10 * srate) / srate
    brain = np.sin(2 * np.pi * 10 * t)
    n = round(0.3 * srate)
    win = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(n) / (n - 1))
    blink = np.zeros_like(t)
    blink[np.round(np.array([1.5, 4, 6.5, 9]) * srate).astype(int)] = 1
    blink = 5 * np.convolve(blink, win, "same")
    muscle = 0.5 * np.random.default_rng(7).standard_normal(t.size)
    A = np.array([[1.0, 0.8, 0.3], [0.9, 0.2, 0.4], [0.7, 0.1, 1.0]])
    keep = t < 5
    S = np.vstack([brain, blink, muscle])[:, keep]
    return t[keep], S, A @ S


def draw_ica_concept(out, lang):
    W, H = 720, 400
    t, S, X = lesson_sources()
    cols = {"brain": C["primary"], "blink": C["core"], "muscle": C["rec"]}
    names = ["brain", "blink", "muscle"]
    sw = 180
    xs = order([24, 270, 516], lang)
    ys = [190, 262, 334]
    body = [rect(0, 0, W, H, C["surface"])]
    for x, key in zip(xs, ("s1", "s2", "s3")):
        body.append(label(x + sw / 2, 34, T_ICAC[key][lang], lang, 15, weight=600))

    def trace(x, y, sig, stroke, lab, lab_is_code=False, note=None):
        b = [rect(x - 4, y - 28, sw + 8, 50, C["fill"], rx=8, opacity=0.5)]
        k = 22 / (np.abs(sig).max() or 1)
        b.append(path(x + t[::2] / t[-1] * sw, y - sig[::2] * k, stroke, 1.3, nd=0))
        b.append(label(x + sw / 2, y + 38, lab, lang, 12.5, C["muted"]))
        if note:
            b.append(label(x + sw - 2, y - 32, note, lang, 11.5, C["core"], side="right"))
        return b

    for name, y in zip(names, ys):
        body += trace(xs[0], y, S[names.index(name)], cols[name], T_ICAC[name][lang])
    # stage 2: head (top view) with three electrodes and their mixtures
    hx, hy, hr = xs[1] + sw / 2, 90, 44
    body.append(f'<circle cx="{hx}" cy="{hy}" r="{hr}" fill="none" stroke="{C["text"]}" stroke-width="1.4"/>')
    body.append(path([hx - 7, hx, hx + 7], [hy - hr + 1, hy - hr - 10, hy - hr + 1], C["text"], 1.4))
    elec = [(hx, hy - 28), (hx, hy), (hx - 34, hy + 6)]
    for i, (ex, ey) in enumerate(elec):
        body.append(f'<circle cx="{ex:.1f}" cy="{ey:.1f}" r="8" fill="{C["surface"]}" stroke="{C["text"]}" stroke-width="1.3"/>')
        body.append(latin(ex, ey + 4, str(i + 1), 10.5, weight=600))
    for i, (key, y) in enumerate(zip(("front", "central", "temporal"), ys)):
        body += trace(xs[1], y, X[i], C["text"], T_ICAC[key][lang])
        nx_ = xs[1] + 4 if lang == "en" else xs[1] + sw - 4
        body.append(f'<circle cx="{nx_:.1f}" cy="{y + 34:.1f}" r="8" fill="{C["surface"]}" stroke="{C["text"]}" stroke-width="1.1"/>')
        body.append(latin(nx_, y + 38, str(i + 1), 10.5, weight=600))
    # stage 3: same sources, new order, blink sign flipped (ICA cannot know order or sign)
    comps = [("muscle", 1), ("blink", -1), ("brain", 1)]
    for k, ((name, sgn), y) in enumerate(zip(comps, ys)):
        lab = f"IC {k + 1}"
        body += trace(xs[2], y, sgn * S[names.index(name)], cols[name], "", note=T_ICAC["flip"][lang] if sgn < 0 else None)
        body.append(latin(xs[2] + sw / 2, y + 38, lab, 12.5, C["muted"]))
    # arrows between stages
    for a, b, word, is_code in ((xs[0], xs[1], T_ICAC["mix"][lang], False), (xs[1], xs[2], "ICA", True)):
        if lang == "en":
            x1, x2 = a + sw + 10, b - 10
        else:
            x1, x2 = a - 10, b + sw + 10
        ym = ys[1] - 4
        body.append(arrow(x1, ym, x2))
        mid = (x1 + x2) / 2
        if is_code:
            body.append(latin(mid, 132, word, 12.5, C["text"], weight=600))
        else:
            body.append(label(mid, 132, word, lang, 12, C["text"], weight=600))
        body.append(line(mid, 140, mid, ym - 6, C["sep"], 1, "2 3"))
    save(out, f"ica-concept/ica-concept-stages.{lang}.svg", svg(W, H, body, T_ICAC["aria"][lang]))


# --- 04-04 ica-1hz-copy-weights --------------------------------------------------------

T_CW = {
    "main": {"ar": "النسخة الرئيسية", "en": "Main dataset"},
    "copy": {"ar": "نسخة ICA", "en": "ICA copy"},
    "filter": {"ar": "فلتر 1 هرتز", "en": "1 Hz filter"},
    "run": {"ar": "تشغيل ICA", "en": "Run ICA"},
    "weights": {"ar": "الأوزان", "en": "Weights"},
    "back": {"ar": "نسخ الأوزان", "en": "Copy weights"},
    "main_next": {"ar": "تكمل إلى ICLabel والـ ERP", "en": "Continues to ICLabel and the ERP"},
    "copy_use": {"ar": "لحساب ICA فقط", "en": "Used only to compute ICA"},
    "aria": {
        "ar": "نسختان من نفس البيانات: النسخة الرئيسية بفلتر high-pass عند 0.1 هرتز، ونسخة ICA بفلتر 1 هرتز. يُشغَّل ICA على النسخة الثانية، ثم تُنسخ الأوزان إلى الرئيسية التي تكمل إلى ICLabel والـ ERP، أما نسخة ICA فتُستخدم لحساب ICA فقط.",
        "en": "Two copies of the same data: the main dataset with a 0.1 Hz high-pass and the ICA copy with a 1 Hz high-pass. ICA runs on the copy, then the weights are copied back to the main dataset, which continues to ICLabel and the ERP; the copy is used only to compute ICA.",
    },
}


def draw_copy_weights(out, lang):
    W, H = 720, 330
    body = [rect(0, 0, W, H, C["surface"])]
    bw, bh, by = 230, 150, 60
    xm, xc = (40, 450) if lang == "en" else (450, 40)
    for x, key, hp, stroke, fill in ((xm, "main", "high-pass 0.1 Hz", C["text"], C["surface"]),
                                     (xc, "copy", "high-pass 1 Hz", C["primary"], C["info"])):
        body.append(rect(x, by, bw, bh, fill, stroke, 1.6, rx=10))
        body.append(label(x + bw / 2, by + 28, T_CW[key][lang], lang, 15, weight=600))
        body.append(code(x + bw / 2, by + 50, hp, 12.5, C["muted"]))
    # filter arrow from main to copy
    y = by + 40
    if lang == "en":
        body.append(arrow(xm + bw + 6, y, xc - 6))
    else:
        body.append(arrow(xm - 6, y, xc + bw + 6))
    body.append(label((min(xm, xc) + max(xm, xc) + bw) / 2, y - 12, T_CW["filter"][lang], lang, 13, weight=600))
    # inside the copy: Run ICA -> weights grid
    rx_, ry_ = xc + 20, by + 76
    body.append(rect(rx_, ry_, 90, 30, C["primary"], rx=6))
    body.append(label(rx_ + 45, ry_ + 20, T_CW["run"][lang], lang, 13, "var(--color-primary-on, #FFFFFF)", weight=600))
    gx, gy, cell = xc + bw - 80, ry_ - 6, 14
    for i in range(3):
        for j in range(4):
            body.append(rect(gx + j * cell, gy + i * cell, cell, cell, C["surface"], C["primary"], 0.8))
    body.append(label(gx + 2 * cell, gy + 3 * cell + 18, T_CW["weights"][lang], lang, 12.5, C["primary"], weight=600))
    if lang == "en":
        body.append(arrow(rx_ + 94, ry_ + 15, gx - 4, C["primary"], 1.2))
    else:
        body.append(arrow(rx_ + 94, ry_ + 15, gx - 4, C["primary"], 1.2))
    # curved arrow from the weights back to the main dataset, below the boxes
    sx, sy = gx + 2 * cell, by + bh
    ex, ey = xm + bw / 2, by + bh
    body.append(f'<path d="M{sx:.1f},{sy + 4:.1f} C{sx:.1f},{sy + 70:.1f} {ex:.1f},{ey + 70:.1f} {ex:.1f},{ey + 10:.1f}" '
                f'fill="none" stroke="{C["primary"]}" stroke-width="1.8"/>')
    body.append(f'<path d="M{ex:.1f},{ey + 2:.1f} l-5.5,10 h11 z" fill="{C["primary"]}"/>')
    body.append(label(W / 2, by + bh + 38, T_CW["back"][lang], lang, 13.5, C["primary"], weight=600))
    body.append(label(xm + bw / 2, H - 20, T_CW["main_next"][lang], lang, 12.5, C["muted"]))
    body.append(label(xc + bw / 2, H - 20, T_CW["copy_use"][lang], lang, 12.5, C["muted"]))
    save(out, f"ica-1hz-copy-weights/ica-copy-weights.{lang}.svg", svg(W, H, body, T_CW["aria"][lang]))


# --- 09-06 hpc -------------------------------------------------------------------------

T_HPC = {
    "pc": {"ar": "جهازك", "en": "Your computer"},
    "script": {"ar": "السكربت", "en": "The script"},
    "cluster": {"ar": "العنقود", "en": "The cluster"},
    "results": {"ar": "النتائج", "en": "Results"},
    "project": {"ar": "مجلد المشروع", "en": "Project folder"},
    "nogui": {"ar": "بلا واجهة", "en": "No GUI"},
    "jobs": {"ar": "ثلاث مهام متوازية", "en": "Three parallel jobs"},
    "where": {"ar": "جامعتك أو NSG", "en": "Your university or NSG"},
    "weights": {"ar": "أوزان ICA لكل مشارك", "en": "ICA weights per participant"},
    "aria": {
        "ar": "أربعة صناديق متتالية: جهازك فيه مجلد المشروع والسكربت، ثم السكربت run_ica_d4.m يعمل بلا واجهة، ثم العنقود بثلاث مهام متوازية sub-002 و sub-003 و sub-004 في جامعتك أو NSG، ثم النتائج: ملف أوزان ICA لكل مشارك ومجلد السجلات logs.",
        "en": "Four boxes in a row: your computer with the project folder and script, then the script run_ica_d4.m running without a GUI, then the cluster with three parallel jobs sub-002, sub-003 and sub-004 at your university or NSG, then the results: one ICA weights file per participant and the logs folder.",
    },
}


def draw_hpc(out, lang):
    W, H = 720, 280
    body = [rect(0, 0, W, H, C["surface"])]
    bw, gap, by, bh = 156, 22, 40, 176
    xs = order([12 + i * (bw + gap) for i in range(4)], lang)
    keys = ["pc", "script", "cluster", "results"]
    for i, (x, key) in enumerate(zip(xs, keys)):
        stroke = C["primary"] if key == "cluster" else C["text"]
        body.append(rect(x, by, bw, bh, C["info"] if key == "cluster" else C["surface"], stroke, 1.5, rx=10))
        body.append(label(x + bw / 2, by + 26, T_HPC[key][lang], lang, 14.5, stroke, weight=600))
        body.append(line(x + 12, by + 38, x + bw - 12, by + 38, C["sep"], 1))
        if i < 3:
            nx = xs[i + 1]
            if lang == "en":
                body.append(arrow(x + bw + 2, by + bh / 2, nx - 2, C["text"], 1.3))
            else:
                body.append(arrow(x - 2, by + bh / 2, nx + bw + 2, C["text"], 1.3))
    x = xs[0]
    body.append(folder_icon(x + 16, by + 56))
    body.append(label(x + 50, by + 71, T_HPC["project"][lang], lang, 12.5, side="left") if lang == "en"
                else label(x + 50, by + 71, T_HPC["project"][lang], lang, 12.5, side="left"))
    body.append(file_icon(x + 22, by + 92, 13, 16))
    body.append(code(x + 44, by + 104, "run_ica_d4.m", 11, side="left"))
    x = xs[1]
    body.append(code(x + bw / 2, by + 70, "run_ica_d4.m", 12, weight=600))
    body.append(label(x + bw / 2, by + 96, T_HPC["nogui"][lang], lang, 12.5, C["muted"]))
    body.append(rect(x + 10, by + 116, bw - 20, 26, C["fill"], rx=5))
    body.append(code(x + bw / 2, by + 133, "matlab -batch", 11, C["text"]))
    x = xs[2]
    for k, s in enumerate(("sub-002", "sub-003", "sub-004")):
        yy = by + 52 + k * 32
        body.append(rect(x + 18, yy, bw - 36, 24, C["surface"], C["primary"], 1.2, rx=12))
        body.append(code(x + bw / 2, yy + 16.5, s, 12, C["primary"], weight=600))
    body.append(label(x + bw / 2, by + 164, T_HPC["jobs"][lang], lang, 12, C["muted"]))
    body.append(label(x + bw / 2, by + bh + 26, T_HPC["where"][lang], lang, 12.5, C["primary"]))
    x = xs[3]
    for k, s in enumerate(("002", "003", "004")):
        yy = by + 52 + k * 22
        body.append(file_icon(x + 12, yy, 10, 13, C["primary"], C["info"]))
        body.append(code(x + 28, yy + 11, f"sub-{s}_…desc-ica.mat", 9.5, side="left"))
    body.append(label(x + bw / 2, by + 132, T_HPC["weights"][lang], lang, 12, C["muted"]))
    body.append(folder_icon(x + 14, by + 144, 20, 14))
    body.append(code(x + 40, by + 156, "logs/", 11.5, side="left"))
    save(out, f"hpc/hpc-flow.{lang}.svg", svg(W, H, body, T_HPC["aria"][lang]))


# --- 09-02 single-subject-script -------------------------------------------------------

SECTIONS = ["Settings", "Load", "Filtering and line noise", "Bad channels and interpolation", "Average reference",
            "ICA on a 1-Hz copy", "ICLabel", "Epochs, baseline, rejection", "Summary"]
# map nodes used by each section: (station, slug, level, ar, en)
NODES = [
    (1, "set-fdt-files", "rec", "ملفات set و fdt", ".set and .fdt files"),
    (3, "filtering", "core", "فلترة high-pass و low-pass", "High-pass & low-pass filtering"),
    (3, "line-noise", "core", "إزالة ضوضاء الكهرباء", "Removing line noise"),
    (3, "bad-channels", "core", "القنوات السيئة", "Bad channels"),
    (3, "interpolation", "core", "الاستيفاء", "Channel interpolation"),
    (3, "rereferencing", "core", "إعادة المرجع", "Re-referencing"),
    (4, "run-ica", "core", "تشغيل ICA", "Running ICA"),
    (4, "ica-1hz-copy-weights", "core", "فلتر 1 هرتز ونسخ الأوزان", "1-Hz filtering & copying weights"),
    (4, "iclabel", "core", "ICLabel وحذف المكوّنات", "ICLabel & removing components"),
    (5, "extract-epochs", "core", "استخراج epochs", "Extracting epochs"),
    (5, "baseline-correction", "core", "تصحيح baseline", "Baseline correction"),
    (5, "epoch-rejection", "core", "رفض epochs السيئة", "Rejecting bad epochs"),
]
SECTION_NODES = {1: [0], 2: [1, 2], 3: [3, 4], 4: [5], 5: [6, 7], 6: [8], 7: [9, 10, 11]}
LEVEL = {"core": ("var(--level-core-soft, #ECE8FB)", "var(--level-core, #5A3FD6)", "var(--level-core-text, #4A30B8)"),
         "rec": ("var(--level-rec-soft, #E3F5EA)", "var(--level-rec, #1B7F45)", "var(--level-rec-text, #176B3B)")}
T_SCRIPT = {
    "editor": {"ar": "السكربت في المحرّر", "en": "The script in the editor"},
    "map": {"ar": "عُقد الخريطة", "en": "Map nodes"},
    "station": {"ar": "المحطة", "en": "Station"},
    "aria": {
        "ar": "أقسام سكربت المشارك الواحد في محرّر MATLAB، كل قسم يبدأ بسطر %%، وسهم من كل قسم إلى درسه في الخريطة: Load إلى ملفات set و fdt في المحطة 1، والفلترة والقنوات السيئة والمرجع إلى دروس المحطة 3، و ICA و ICLabel إلى المحطة 4، والتقطيع إلى المحطة 5.",
        "en": "The sections of the single-subject script in the MATLAB editor, each starting with a %% line, with an arrow from each section to its lesson on the map: Load to .set and .fdt files in station 1, filtering, bad channels and reference to station 3 lessons, ICA and ICLabel to station 4, and epoching to station 5.",
    },
}


def draw_single_script(out, lang):
    W, H = 720, 530
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    sw, nw = 262, 250
    sx, nx = (20, W - 20 - nw) if not rtl else (W - 20 - sw, 20)
    # editor panel (code, LTR in both languages)
    top, rh = 64, 46
    body.append(label(sx + sw / 2, 34, T_SCRIPT["editor"][lang], lang, 15, weight=600))
    body.append(rect(sx, top - 14, sw, rh * 9 + 18, "var(--color-code-bg, #F7F7FA)", C["sep"], 1, rx=10))
    sec_y = []
    for i, name in enumerate(SECTIONS):
        y = top + i * rh + 14
        sec_y.append(y)
        body.append(code(sx + 14, y, "%%", 12, "var(--syntax-comment, #5D6C79)", weight=600, side="left"))
        body.append(code(sx + 38, y, name, 11.5, weight=600, side="left"))
        body.append(rect(sx + 38, y + 9, [120, 90, 150, 160, 110, 170, 140, 150, 100][i] * 0.8, 5, C["sep"], rx=2, opacity=0.7))
        if i:
            body.append(line(sx + 10, y - 20, sx + sw - 10, y - 20, C["sep"], 0.6))
    # map nodes grouped by station
    body.append(label(nx + nw / 2, 34, T_SCRIPT["map"][lang], lang, 15, weight=600))
    node_y, y, last = [], 58, None
    for st, slug, lvl, ar, en in NODES:
        if st != last:
            y += 6 if last is not None else 0
            if rtl:
                body.append(label(nx + nw, y + 8, f'{T_SCRIPT["station"][lang]} {st}', lang, 12, C["muted"], side="right"))
            else:
                body.append(latin(nx, y + 8, f'{T_SCRIPT["station"][lang]} {st}', 12, C["muted"], side="left"))
            y += 16
            last = st
        fill, border, txt = LEVEL[lvl]
        body.append(rect(nx, y, nw, 26, fill, border, 1.2, rx=6))
        body.append(label(nx + nw / 2, y + 17.5, ar if rtl else en, lang, 12.5, txt, weight=600))
        node_y.append(y + 13)
        y += 31
    # connectors from each section to its node(s)
    x1 = sx + sw if not rtl else sx
    x2 = nx if not rtl else nx + nw
    s = 1 if not rtl else -1
    for si, nodes in SECTION_NODES.items():
        for ni in nodes:
            ya, yb = sec_y[si] - 4, node_y[ni]
            mx = (x1 + x2) / 2
            body.append(f'<path d="M{x1 + 4 * s:.1f},{ya:.1f} C{mx:.1f},{ya:.1f} {mx:.1f},{yb:.1f} {x2 - 9 * s:.1f},{yb:.1f}" '
                        f'fill="none" stroke="{C["primary"]}" stroke-width="1.2"/>')
            body.append(f'<path d="M{x2 - 1 * s:.1f},{yb:.1f} l{-8 * s},-4.5 v9 z" fill="{C["primary"]}"/>')
    save(out, f"single-subject-script/script-sections-map.{lang}.svg", svg(W, H, body, T_SCRIPT["aria"][lang]))


# --- 09-03 batch-processing ------------------------------------------------------------

T_BATCH = {
    "subjects": {"ar": "المشاركون", "en": "Participants"},
    "outputs": {"ar": "المخرجات", "en": "Outputs"},
    "steps": {"ar": ["فلترة", "ضوضاء الكهرباء", "القنوات السيئة", "المرجع", "ICA", "ICLabel", "التقطيع"],
              "en": ["filter", "line noise", "bad channels", "reference", "ICA", "ICLabel", "epoching"]},
    "next": {"ar": "المشارك التالي", "en": "Next participant"},
    "error": {"ar": "خطأ: سجّله وأكمل", "en": "Error: log and continue"},
    "aria": {
        "ar": "حلقة: ثلاثة مشاركين sub-002 و sub-003 و sub-004 يدخلون واحداً بعد الآخر إلى الدالة process_subject التي تطبّق خطوات البايبلاين، ومخرجاتها في derivatives/eeglab مجلد لكل مشارك مع batch_summary.csv. سهم دائري يعود إلى المشارك التالي، وسهم أحمر من الدالة إلى logs/batch_log.txt عند الخطأ: سجّله وأكمل.",
        "en": "A loop: three participants sub-002, sub-003 and sub-004 go one at a time into the function process_subject, which applies the pipeline steps; outputs go to derivatives/eeglab, one folder per participant, with batch_summary.csv. A circular arrow returns to the next participant, and a red arrow goes from the function to logs/batch_log.txt on error: log and continue.",
    },
}


def draw_batch(out, lang):
    W, H = 720, 420
    rtl = lang == "ar"
    red = "var(--status-danger, #B3261E)"
    body = [rect(0, 0, W, H, C["surface"])]
    pw, bw, ow = 120, 200, 210
    px, bx, ox = (16, 190, 480) if not rtl else (584, 330, 30)
    y0 = 92
    body.append(label(px + pw / 2, y0 - 14, T_BATCH["subjects"][lang], lang, 14, weight=600))
    body.append(label(ox + ow / 2, y0 - 14, T_BATCH["outputs"][lang], lang, 14, weight=600))
    subs = ["sub-002", "sub-003", "sub-004"]
    for k, s in enumerate(subs):
        yy = y0 + k * 42
        on = k == 0
        body.append(rect(px, yy, pw, 30, C["info"] if on else C["surface"], C["primary"] if on else C["strong"], 1.4, rx=15))
        body.append(code(px + pw / 2, yy + 20, s, 12.5, C["primary"] if on else C["text"], weight=600))
    # process_subject box
    by, bh = y0 - 6, 236
    body.append(rect(bx, by, bw, bh, C["surface"], C["text"], 1.6, rx=10))
    body.append(code(bx + bw / 2, by + 26, "process_subject", 14, C["primary"], weight=600))
    body.append(line(bx + 14, by + 38, bx + bw - 14, by + 38, C["sep"], 1))
    for i, st in enumerate(T_BATCH["steps"][lang]):
        yy = by + 60 + i * 24
        body.append(f'<circle cx="{bx + 30:.1f}" cy="{yy - 4:.1f}" r="3" fill="{C["muted"]}"/>' if not rtl else
                    f'<circle cx="{bx + bw - 30:.1f}" cy="{yy - 4:.1f}" r="3" fill="{C["muted"]}"/>')
        if st in ("ICA", "ICLabel"):
            body.append(latin(bx + 42 if not rtl else bx + bw - 42, yy, st, 12.5, side="left" if not rtl else "right"))
        else:
            body.append(label(bx + 42 if not rtl else bx + bw - 42, yy, st, lang, 12.5, side="left" if not rtl else "right"))
    # outputs: derivatives tree, summary, logs
    oy = y0
    body.append(folder_icon(ox, oy))
    body.append(code(ox + 32, oy + 15, "derivatives/eeglab/", 12, weight=600, side="left"))
    for k, s in enumerate(subs):
        yy = oy + 30 + k * 24
        body.append(path([ox + 10, ox + 10, ox + 22], [oy + 20, yy + 6, yy + 6], C["sep"], 1))
        body.append(folder_icon(ox + 26, yy - 2, 18, 14))
        body.append(code(ox + 50, yy + 9, s + "/", 11.5, side="left"))
    yy = oy + 30 + 3 * 24
    body.append(path([ox + 10, ox + 10, ox + 22], [oy + 20, yy + 6, yy + 6], C["sep"], 1))
    body.append(file_icon(ox + 29, yy - 2, 12, 15, C["primary"], C["info"]))
    body.append(code(ox + 50, yy + 9, "batch_summary.csv", 11.5, C["primary"], side="left"))
    ly = by + bh - 30
    body.append(folder_icon(ox, ly - 4, 20, 14))
    body.append(code(ox + 28, ly + 7, "logs/batch_log.txt", 11.5, red, weight=600, side="left"))
    # flow arrows
    ym = y0 + 15
    if not rtl:
        body.append(arrow(px + pw + 6, ym, bx - 6))
        body.append(arrow(bx + bw + 6, ym, ox - 6))
    else:
        body.append(arrow(px - 6, ym, bx + bw + 6))
        body.append(arrow(bx - 6, ym, ox + ow + 6))
    # error arrow: box -> log file
    ex1 = bx + bw if not rtl else bx
    ex2 = ox - 6 if not rtl else ox + ow + 6
    body.append(f'<path d="M{ex1:.1f},{ly:.1f} H{ex2:.1f}" stroke="{red}" stroke-width="1.6" stroke-dasharray="5 3"/>')
    s = 1 if not rtl else -1
    body.append(f'<path d="M{ex2 + 2 * s:.1f},{ly:.1f} l{-10 * s},-5.5 v11 z" fill="{red}"/>')
    body.append(label(ox + 28 if not rtl else ox + ow - 22, ly + 26, T_BATCH["error"][lang], lang, 12.5, red, weight=600,
                      side="left" if not rtl else "right"))
    # loop back: from the outputs, under everything, to the next participant
    lx1 = ox + ow - 10
    lx2 = px + pw / 2
    yb = by + bh + 34
    body.append(f'<path d="M{lx1:.1f},{ly + 10:.1f} V{yb - 14:.1f} Q{lx1:.1f},{yb:.1f} {lx1 - 14 * s:.1f},{yb:.1f} '
                f'H{lx2 + 14 * s:.1f} Q{lx2:.1f},{yb:.1f} {lx2:.1f},{yb - 14:.1f} V{y0 + 42 * 1 + 40:.1f}" '
                f'fill="none" stroke="{C["primary"]}" stroke-width="1.8"/>')
    body.append(f'<path d="M{lx2:.1f},{y0 + 42 + 32:.1f} l-5.5,10 h11 z" fill="{C["primary"]}"/>')
    body.append(label(W / 2, yb + 22, T_BATCH["next"][lang], lang, 13, C["primary"], weight=600))
    save(out, f"batch-processing/batch-loop.{lang}.svg", svg(W, H, body, T_BATCH["aria"][lang]))


# --- 09-05 file-organization -----------------------------------------------------------

T_ORG = {
    "raw": {"ar": "البيانات كما نزّلتها، للقراءة فقط", "en": "Data as downloaded, read only"},
    "deriv": {"ar": "كل ما تنتجه المعالجة", "en": "Everything processing produces"},
    "sub": {"ar": "مجلد لكل مشارك، بنفس أسماء BIDS", "en": "One folder per participant, BIDS names"},
    "clean": {"ar": "البيانات المستمرة النظيفة", "en": "Clean continuous data"},
    "epochs": {"ar": "المقاطع النظيفة", "en": "Clean epochs"},
    "code": {"ar": "السكربتات: تعيد إنتاج كل ما سبق", "en": "Scripts: they rebuild everything else"},
    "figures": {"ar": "الرسوم النهائية", "en": "Final figures"},
    "logs": {"ar": "ملفات الأخطاء من المعالجة بالدفعات", "en": "Error files from the batch run"},
    "aria": {
        "ar": "شجرة مجلد faces_project: rawdata للبيانات الخام وعليه قفل لأنه للقراءة فقط، و derivatives/eeglab فيه sub-002/eeg بملفين desc-clean و desc-epochs، و code للسكربتات، و figures للرسوم، و logs لملفات الأخطاء.",
        "en": "Folder tree of faces_project: rawdata for raw data with a lock because it is read only, derivatives/eeglab with sub-002/eeg holding the desc-clean and desc-epochs files, code for the scripts, figures for the figures and logs for error files.",
    },
}


def lock_icon(x, y, stroke):
    return (f'<path d="M{x + 2.5:.1f},{y + 6:.1f} v-2.5 a3.5,3.5 0 0 1 7,0 v2.5" fill="none" stroke="{stroke}" stroke-width="1.4"/>'
            + rect(x, y + 6, 12, 9, stroke, rx=1.5))


def draw_file_org(out, lang):
    W, H = 720, 420
    rtl = lang == "ar"
    body = [rect(0, 0, W, H, C["surface"])]
    p = "sub-002_task-FaceRecognition_"
    rows = [(0, "faces_project/", None, True), (1, "rawdata/", "raw", True), (1, "derivatives/eeglab/", "deriv", True),
            (2, "sub-002/eeg/", "sub", True), (3, p + "desc-clean_eeg.set", "clean", False),
            (3, p + "desc-epochs_eeg.set", "epochs", False), (1, "code/", "code", True),
            (2, "d1_pipeline.m", None, False), (2, "batch_d4.m", None, False), (1, "figures/", "figures", True),
            (1, "logs/", "logs", True)]
    x0, y0, rh, ind = 24, 34, 34, 22
    dx = W - 20 if rtl else 452
    parent_y = {}
    for i, (lvl, name, key, folder) in enumerate(rows):
        y = y0 + i * rh
        x = x0 + lvl * ind
        if lvl > 0:
            body.append(path([x - ind + 7, x - ind + 7, x - 4], [parent_y[lvl - 1] + 8, y, y], C["sep"], 1))
        if folder:
            parent_y[lvl] = y
            body.append(folder_icon(x, y - 9, 18, 14))
        else:
            body.append(file_icon(x + 3, y - 9, 11, 14, C["primary"] if key else C["muted"], C["info"] if key else None))
        body.append(code(x + 24, y + 3, name, 11, weight=600 if folder else 400, side="left"))
        end = x + 24 + len(name) * 6.65
        if name == "rawdata/":
            body.append(lock_icon(end + 8, y - 9, "var(--status-danger, #B3261E)"))
            end += 26
        if key:
            body.append(line(end + 6, y, (470 if rtl else dx - 8), y, C["sep"], 0.8, "1 3"))
            hl = key in ("raw", "code")
            body.append(label(dx, y + 4.5, T_ORG[key][lang], lang, 12.5, C["primary"] if hl else C["muted"],
                              side="right" if rtl else "left"))
    save(out, f"file-organization/project-tree.{lang}.svg", svg(W, H, body, T_ORG["aria"][lang]))


# --- main ------------------------------------------------------------------------------

# --- 04-02 ica-data-requirements --------------------------------------------------------

T_ICAREQ = {
    "title": {"ar": "أقصر تسجيل عند \u2066k = 30\u2069 و 250 هرتز", "en": "Shortest recording at k = 30 and 250 Hz"},
    "x": {"ar": "عدد المكوّنات", "en": "Number of components"},
    "y": {"ar": "دقائق التسجيل", "en": "Minutes of recording"},
    "note": {"ar": "قد لا يكفي \u2066k = 30\u2069 هنا (الدليل الرسمي)", "en": "k = 30 may not be enough here (official guide)"},
    "aria": {
        "ar": "منحنى أقصر تسجيل يحتاجه ICA مقابل عدد المكوّنات عند k = 30 ومعدل 250 هرتز. المحور الأفقي عدد المكوّنات 32 و 64 و 128 و 256، والرأسي دقائق التسجيل. النقاط: 32 مكوّناً 2.0 دقيقة، و 64 مكوّناً 8.2 دقيقة، و 128 مكوّناً 32.8 دقيقة، و 256 مكوّناً 131.1 دقيقة. عند 256 ملاحظة متقطّعة: قد لا يكفي k = 30 هنا (الدليل الرسمي).",
        "en": "Curve of the shortest recording ICA needs against the number of components, at k = 30 and 250 Hz. Horizontal axis: 32, 64, 128 and 256 components; vertical axis: minutes of recording. Points: 32 components 2.0 min, 64 components 8.2 min, 128 components 32.8 min, 256 components 131.1 min. At 256 a dashed note: k = 30 may not be enough here (official guide).",
    },
}


def ica_minutes(n, k=30, srate=250):
    """Shortest recording in minutes for n components: k * n^2 points per channel."""
    return k * n * n / srate / 60


def draw_ica_data_requirements(out, lang):
    W, H = 720, 400
    body = [rect(0, 0, W, H, C["surface"])]
    body.append(label(W / 2, 32, T_ICAREQ["title"][lang], lang, 15, weight=600))
    # chart axes stay left to right in both languages (a quantity axis, like a time axis)
    x0, x1, y0, y1 = 100, 640, 330, 70
    ymax = 140
    comps = (32, 64, 128, 256)
    xs = [x0 + 40 + i * (x1 - x0 - 80) / 3 for i in range(4)]
    Y = lambda m: y0 - (y0 - y1) * m / ymax
    for m in range(0, ymax + 1, 20):
        body.append(line(x0, Y(m), x1, Y(m), C["sep"], 0.8, None if m == 0 else "2 3"))
        body.append(latin(x0 - 10, Y(m) + 4, str(m), 11.5, C["muted"], side="right"))
    body.append(line(x0, y0, x0, y1 - 6, C["strong"], 1.2))
    mins = [ica_minutes(n) for n in comps]
    body.append(path(xs, [Y(m) for m in mins], C["primary"], 2.4))
    for x, n, m in zip(xs, comps, mins):
        body.append(line(x, y0, x, y0 + 5, C["strong"], 1.2))
        body.append(latin(x, y0 + 22, str(n), 12.5, weight=600))
        body.append(f'<circle cx="{x:.1f}" cy="{Y(m):.1f}" r="5" fill="{C["surface"]}" stroke="{C["primary"]}" stroke-width="2"/>')
        body.append(latin(x - 12, Y(m) - 4, f"{m:.1f}", 12.5, C["primary"], side="right", weight=600))
    body.append(label((x0 + x1) / 2, y0 + 50, T_ICAREQ["x"][lang], lang, 12.5, C["muted"]))
    body.append(label(x0 - 52, (y0 + y1) / 2, T_ICAREQ["y"][lang], lang, 12.5, C["muted"],
                      extra=f' transform="rotate(-90 {x0 - 52} {(y0 + y1) / 2})"'))
    # dashed note at 256
    xn, yn = xs[3], Y(mins[3])
    bx0, bx1, by = xn - 385, xn - 75, yn - 15
    body.append(rect(bx0, by, bx1 - bx0, 30, C["surface"], C["strong"], 1, rx=6, dash="4 3"))
    body.append(line(bx1, by + 15, xn - 62, by + 15, C["strong"], 1, "4 3"))
    body.append(label((bx0 + bx1) / 2, by + 20, T_ICAREQ["note"][lang], lang, 12))
    save(out, f"ica-data-requirements/ica-minutes-curve.{lang}.svg", svg(W, H, body, T_ICAREQ["aria"][lang]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--d1", help="eeglab_data.set (needed for extract-epochs and the eeg-struct values)")
    ap.add_argument("--only", nargs="*", help="lesson slugs to draw (default: all)")
    ap.add_argument("--precompute-mb", nargs=3, type=float, metavar=("DATERP", "DATSPEC", "DATTIMEF"),
                    help="measured sizes in MB of sph's precomputed files (study-precompute)")
    a = ap.parse_args()
    want = lambda slug: not a.only or slug in a.only
    facts = {"nbchan": 32, "pnts": 30504, "srate": 128, "nevent": 154}
    cz = None
    if a.d1:
        cz, sf, sq, facts = d1_cz(a.d1)
        print(f"D1: {facts}")
    for lang in ("ar", "en"):
        if want("eeg-origin"):
            draw_eeg_origin(a.out, lang)
        if want("electrode-10-20"):
            draw_10_20(a.out, lang)
        if want("matlab-basics"):
            draw_matlab(a.out, lang)
        if want("experiment-design"):
            draw_experiment(a.out, lang)
        if want("eeg-struct"):
            draw_eeg_struct(a.out, lang, facts)
        if want("extract-epochs"):
            if cz is None:
                print("extract-epochs skipped: pass --d1")
            else:
                draw_epochs(a.out, lang, cz, sf, sq, facts)
        if want("study-concepts"):
            draw_study_concepts(a.out, lang)
        if want("create-study"):
            draw_create_study(a.out, lang)
        if want("study-from-bids"):
            draw_study_from_bids(a.out, lang)
        if want("study-design"):
            draw_study_design(a.out, lang)
        if want("study-precompute"):
            draw_study_precompute(a.out, lang, a.precompute_mb)
        if want("limo"):
            draw_limo(a.out, lang)
        if want("alleeg-datasets"):
            draw_alleeg(a.out, lang)
        if want("set-fdt-files"):
            draw_set_fdt(a.out, lang)
        if want("bids-openneuro"):
            draw_bids(a.out, lang)
        if want("ica-concept"):
            draw_ica_concept(a.out, lang)
        if want("ica-data-requirements"):
            draw_ica_data_requirements(a.out, lang)
        if want("ica-1hz-copy-weights"):
            draw_copy_weights(a.out, lang)
        if want("hpc"):
            draw_hpc(a.out, lang)
        if want("single-subject-script"):
            draw_single_script(a.out, lang)
        if want("batch-processing"):
            draw_batch(a.out, lang)
        if want("file-organization"):
            draw_file_org(a.out, lang)


if __name__ == "__main__":
    main()
