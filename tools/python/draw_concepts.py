"""
draw_concepts.py - concept drawings for the lessons, as SVG in the site's visual identity.

Each drawing comes in two versions (ar and en) because text is part of the drawing. Colours are
CSS variables with a light-mode fallback, so an inlined drawing follows dark mode; as an <img>
the fallbacks apply.

Drawings:
  filtering/filtering-edge-vs-cutoff.{ar,en}.svg   1 Hz high-pass response using the pop_eegfiltnew rules
  run-ica/ica-mixing.{ar,en}.svg                   sources -> mixture on channels -> ICA -> separated sources
  iclabel/ic-three-panels.{ar,en}.svg              reading a component: three panels, three questions
  iclabel/iclabel-before-after.{ar,en}.svg         D1 before and after removing the eye component (needs --d1)
  import-raw/import-formats.{ar,en}.svg            the three file formats and how to import them
  run-ica/ica-two-copies.{ar,en}.svg               main dataset and ICA copy, weights copied back

Usage:
  python3 -I draw_concepts.py --out assets/lessons [--d1 path/to/eeglab_data.set]
"""
import argparse
import math
import os

import numpy as np
from scipy.signal import firwin, freqz

FONT = "Vazirmatn, 'Noto Sans Arabic', 'Segoe UI', sans-serif"
MONO = "'JetBrains Mono', ui-monospace, monospace"
C = {
    "text": "var(--color-text, #111114)",
    "muted": "var(--color-text-muted, #5C5C66)",
    "primary": "var(--color-primary, #0060DF)",
    "sep": "var(--color-separator, #C6C6C8)",
    "fill": "var(--color-surface-2, #E9E9EE)",
    "surface": "var(--color-surface, #FFFFFF)",
}
RED = "#D7263D"   # "after" trace: red as in EEGLAB overlays, readable on light and dark surfaces

T = {
    "edge_title": {"ar": "حافة النطاق ليست نقطة القطع", "en": "The edge is not the cutoff"},
    "edge_x": {"ar": "التردد (Hz)", "en": "Frequency (Hz)"},
    "edge_y": {"ar": "نسبة ما يمرّ", "en": "Amplitude passed"},
    "edge_edge": {"ar": "القيمة التي تكتبها", "en": "What you type"},
    "edge_cut": {"ar": "القطع الفعلي", "en": "Actual cutoff"},
    "edge_band": {"ar": "النطاق الانتقالي", "en": "Transition band"},
    "edge_pass": {"ar": "يمرّ كاملاً", "en": "Passes fully"},
    "edge_note": {
        "ar": "pop_eegfiltnew · high-pass · Hamming · 128 Hz · order {order}",
        "en": "pop_eegfiltnew · high-pass · Hamming · 128 Hz · order {order}",
    },
    "mix_sources": {"ar": "المصادر", "en": "Sources"},
    "mix_channels": {"ar": "القنوات (ما يسجّله الجهاز)", "en": "Channels (what is recorded)"},
    "mix_ica": {"ar": "مكوّنات ICA", "en": "ICA components"},
    "mix_brain": {"ar": "دماغ", "en": "Brain"},
    "mix_blink": {"ar": "رمش", "en": "Blink"},
    "mix_muscle": {"ar": "عضلة", "en": "Muscle"},
    "mix_mix": {"ar": "خلط", "en": "Mixing"},
    "mix_unmix": {"ar": "فصل", "en": "Unmixing"},
    "tp_topo": {"ar": "خريطة الرأس", "en": "Scalp map"},
    "tp_topo_q": {"ar": "من أين يأتي؟", "en": "Where is it?"},
    "tp_spec": {"ar": "الطيف", "en": "Spectrum"},
    "tp_spec_q": {"ar": "أي ترددات فيه؟", "en": "Which frequencies?"},
    "tp_time": {"ar": "السلسلة الزمنية", "en": "Time series"},
    "tp_time_q": {"ar": "كيف يتغيّر مع الوقت؟", "en": "How does it change over time?"},
    "ba_before": {"ar": "قبل الحذف", "en": "Before removal"},
    "ba_after": {"ar": "بعد حذف المكوّنات الموسومة", "en": "After removing flagged components"},
    "ba_time": {"ar": "الزمن (s)", "en": "Time (s)"},
    "fmt_cols": {"ar": ["امتداد الملف", "الجهاز المعتاد", "طريقة الاستيراد في EEGLAB"],
                 "en": ["File extension", "Usual system", "Import in EEGLAB"]},
    "fmt_rows": {"ar": [["أنظمة سريرية وبحثية كثيرة", "وبيانات PhysioNet"], ["أجهزة BioSemi"], ["أجهزة Brain Products"]],
                 "en": [["Many clinical and research", "systems, PhysioNet data"], ["BioSemi systems"], ["Brain Products systems"]]},
    "fmt_how": {"ar": [["الإضافة Biosig"], ["الإضافة Biosig", "مع اختيار قناة مرجع"], ["الإضافة bva-io من ملف", ".vhdr"]],
                "en": [["Biosig plugin"], ["Biosig plugin,", "choose a reference channel"], ["bva-io plugin,", "from the .vhdr file"]]},
    "cp_main": {"ar": "النسخة الرئيسية", "en": "Main dataset"},
    "cp_ica": {"ar": "نسخة ICA", "en": "ICA copy"},
    "cp_filter": {"ar": "فلتر 1 هرتز", "en": "1 Hz filter"},
    "cp_run": {"ar": "تشغيل ICA", "en": "Run ICA"},
    "cp_copy": {"ar": "نسخ الأوزان", "en": "Copy weights"},
}


def tx(x, y, s, lang, size=13, fill=None, anchor="middle", weight=400, mono=False):
    fam = MONO if mono else FONT
    # RTL direction only for centred Arabic text (it may contain a Latin term); a middle anchor is unaffected.
    d = ' direction="rtl"' if lang == "ar" and anchor == "middle" and not mono else ""
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{fam}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill or C["text"]}" text-anchor="{anchor}"{d}>{s}</text>')


def path(xs, ys, stroke, width=1.5, dash=None):
    """Path with relative coordinates rounded to 0.1 px: about three times smaller than a polyline."""
    xs, ys = np.round(np.asarray(xs, float), 1), np.round(np.asarray(ys, float), 1)
    d = [f"M{xs[0]:g} {ys[0]:g}l"]
    for dx, dy in zip(np.diff(xs), np.diff(ys)):
        d.append(f"{round(dx, 1):g} {round(dy, 1):g}")
    da = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<path d="{" ".join(d)}" fill="none" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"{da}/>'


def svg(w, h, body, label):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'role="img" aria-label="{label}">\n' + "\n".join(body) + "\n</svg>\n")


def save(out, rel, content):
    p = os.path.join(out, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w", encoding="utf-8").write(content)
    print(f"{rel}  {len(content.encode()) / 1024:.1f} KB")


# --- 1. filtering ----------------------------------------------------------------------

def firfilt_hp(edge, fs):
    """Same rules as pop_eegfiltnew: df = min(max(edge*0.25, 2), edge), order = 3.3*fs/df rounded up to even."""
    df = min(max(edge * 0.25, 2), edge)
    order = math.ceil(3.3 / (df / fs) / 2) * 2
    cutoff = edge - df / 2
    b = firwin(order + 1, cutoff, window="hamming", pass_zero=False, fs=fs)
    return b, order, cutoff, df


def draw_edge(out, lang):
    fs, edge = 128, 1.0
    b, order, cutoff, df = firfilt_hp(edge, fs)
    f, h = freqz(b, worN=np.linspace(0, 3, 600), fs=fs)
    a = np.abs(h)
    W, H = 720, 356
    L, R, Tp, B = 70, 690, 64, 280
    X = lambda v: L + (R - L) * v / 3.0
    Y = lambda v: B - (B - Tp) * v / 1.1
    body = [f'<rect width="{W}" height="{H}" fill="{C["surface"]}"/>']
    body.append(f'<rect x="{X(edge - df):.1f}" y="{Tp}" width="{X(edge) - X(edge - df):.1f}" height="{B - Tp}" fill="{C["fill"]}"/>')
    body.append(tx((X(edge - df) + X(edge)) / 2, Tp + 16, T["edge_band"][lang], lang, 12, C["muted"]))
    body.append(tx((X(edge) + R) / 2, Y(1.0) - 10, T["edge_pass"][lang], lang, 12, C["muted"]))
    for v in (0, 0.5, 1.0):
        body.append(f'<line x1="{L}" x2="{R}" y1="{Y(v):.1f}" y2="{Y(v):.1f}" stroke="{C["sep"]}" stroke-width="0.75"/>')
        body.append(tx(L - 8, Y(v) + 4, f"{v:g}", lang, 11, C["muted"], "end", mono=True))
    for v in (0, 0.5, 1, 1.5, 2, 2.5, 3):
        body.append(tx(X(v), B + 18, f"{v:g}", lang, 11, C["muted"], mono=True))
    body.append(f'<line x1="{L}" x2="{R}" y1="{B}" y2="{B}" stroke="{C["text"]}" stroke-width="1"/>')
    body.append(path([X(v) for v in f], [Y(v) for v in a], C["primary"], 2.2))
    body.append(f'<line x1="{X(edge):.1f}" x2="{X(edge):.1f}" y1="{Tp + 26}" y2="{B}" stroke="{C["text"]}" stroke-width="1.2" stroke-dasharray="5 4"/>')
    body.append(tx(X(edge) + 8, Tp + 42, "Lower edge = 1 Hz", lang, 12, anchor="start", mono=True))
    body.append(tx(X(edge) + 8, Tp + 60, T["edge_edge"][lang], lang, 12.5, C["muted"], anchor="start"))
    yc = Y(float(np.interp(cutoff, f, a)))
    body.append(f'<circle cx="{X(cutoff):.1f}" cy="{yc:.1f}" r="5" fill="{C["surface"]}" stroke="{C["text"]}" stroke-width="1.6"/>')
    lx, ly = X(edge) + 10, Y(0.28)
    body.append(f'<line x1="{X(cutoff) + 5:.1f}" x2="{lx - 4:.1f}" y1="{yc + 3:.1f}" y2="{ly - 4:.1f}" stroke="{C["text"]}" stroke-width="1"/>')
    body.append(tx(lx, ly, "−6 dB ≈ 0.5 Hz", lang, 12, anchor="start", weight=600, mono=True))
    body.append(tx(lx, ly + 18, T["edge_cut"][lang], lang, 12.5, C["muted"], anchor="start"))
    body.append(tx(W / 2, 30, T["edge_title"][lang], lang, 16, weight=600))
    body.append(tx(W / 2, B + 42, T["edge_x"][lang], lang, 12, C["muted"]))
    body.append(tx(18, (Tp + B) / 2, T["edge_y"][lang], lang, 12, C["muted"]).replace("<text ", f'<text transform="rotate(-90 18 {(Tp + B) / 2:.1f})" '))
    body.append(tx(W / 2, H - 8, T["edge_note"][lang].format(order=order), lang, 10.5, C["muted"], mono=True))
    label = {"ar": f"منحنى فلتر high-pass: كتبنا 1 هرتز، لكن الإشارة تنقص للنصف عند حوالي {cutoff:g} هرتز، والنطاق بين 0 و 1 هرتز انتقالي.",
             "en": f"High-pass filter response: you type 1 Hz, but the signal is halved at about {cutoff:g} Hz; 0 to 1 Hz is the transition band."}[lang]
    save(out, f"filtering/filtering-edge-vs-cutoff.{lang}.svg", svg(W, H, body, label))


# --- 2. ICA mixing ---------------------------------------------------------------------

def sources(n=180):
    t = np.linspace(0, 2, n)
    brain = np.sin(2 * np.pi * 10 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.7 * t))
    blink = sum(2.4 * np.exp(-((t - c) ** 2) / 0.004) for c in (0.45, 1.45))
    rng = np.random.default_rng(3)
    muscle = rng.normal(0, 1, n) * np.where((t > 0.8) & (t < 1.25), 1.1, 0.12)
    return t, [brain, blink, muscle]


def draw_mixing(out, lang):
    t, S = sources()
    M = np.array([[0.5, 1.0, 0.25], [0.8, 0.45, 0.35], [0.6, 0.12, 0.9]])
    X = M @ np.vstack(S)
    W, H = 720, 330
    cols = [40, 280, 520]
    cw, rh, top = 160, 76, 74
    body = [f'<rect width="{W}" height="{H}" fill="{C["surface"]}"/>']
    heads = [T["mix_sources"][lang], T["mix_channels"][lang], T["mix_ica"][lang]]
    names = [T["mix_brain"][lang], T["mix_blink"][lang], T["mix_muscle"][lang]]
    order = cols if lang == "en" else cols[::-1]
    for c, head in zip(order, heads):
        body.append(tx(c + cw / 2, 34, head, lang, 13.5, weight=600))
    for col, data, stroke, lab in ((order[0], S, C["text"], names), (order[1], list(X), C["muted"], ["Ch 1", "Ch 2", "Ch 3"]),
                                    (order[2], S, C["primary"], names)):
        for i, y in enumerate(data):
            yc = top + i * rh + rh / 2 - 8
            y = np.asarray(y)
            ys = yc - 17 * y / (np.abs(y).max() or 1)
            body.append(f'<rect x="{col - 6}" y="{yc - 24:.1f}" width="{cw + 12}" height="48" rx="8" fill="{C["fill"]}" opacity="0.55"/>')
            body.append(path(col + t / t[-1] * cw, ys, stroke, 1.4))
            mono = lab[i].startswith("Ch")
            body.append(tx(col + cw / 2, yc + 40, lab[i], lang, 11.5, C["muted"], mono=mono))
    for a, b, word in ((order[0], order[1], T["mix_mix"][lang]), (order[1], order[2], T["mix_unmix"][lang])):
        x1, x2 = (a + cw + 14, b - 14) if lang == "en" else (a - 14, b + cw + 14)
        ym = top + 1.5 * rh - 8
        body.append(f'<line x1="{x1}" x2="{x2}" y1="{ym}" y2="{ym}" stroke="{C["text"]}" stroke-width="1.4"/>')
        tip = x2
        sgn = 1 if x2 > x1 else -1
        body.append(f'<path d="M{tip},{ym} l{-9 * sgn},-5 v10 z" fill="{C["text"]}"/>')
        body.append(tx((x1 + x2) / 2, ym - 10, word, lang, 12, C["muted"]))
    body.append(tx(W / 2, H - 14, "EEG = A · S    →    S = W · EEG", lang, 12, C["muted"], mono=True))
    label = {"ar": "ثلاثة مصادر (دماغ، رمش، عضلة) تختلط على كل قناة، و ICA يفصلها مرة ثانية إلى مكوّنات مستقلة بدون حذف أي قناة.",
             "en": "Three sources (brain, blink, muscle) mix on every channel; ICA separates them back into independent components without deleting channels."}[lang]
    save(out, f"run-ica/ica-mixing.{lang}.svg", svg(W, H, body, label))


# --- 3. three panels -------------------------------------------------------------------

def draw_three_panels(out, lang):
    W, H = 720, 250
    body = [f'<rect width="{W}" height="{H}" fill="{C["surface"]}"/>']
    xs = [40, 270, 500] if lang == "en" else [500, 270, 40]
    w = 180
    keys = [("tp_topo", "tp_topo_q"), ("tp_spec", "tp_spec_q"), ("tp_time", "tp_time_q")]
    for i, (x, (k, q)) in enumerate(zip(xs, keys)):
        body.append(f'<rect x="{x}" y="20" width="{w}" height="150" rx="12" fill="none" stroke="{C["sep"]}" stroke-width="1"/>')
        cx, cy = x + w / 2, 95
        if i == 0:
            body.append(f'<circle cx="{cx}" cy="{cy}" r="52" fill="none" stroke="{C["text"]}" stroke-width="1.4"/>')
            body.append(f'<path d="M{cx - 8},{cy - 51} L{cx},{cy - 64} L{cx + 8},{cy - 51}" fill="none" stroke="{C["text"]}" stroke-width="1.4"/>')
            body.append(f'<ellipse cx="{cx}" cy="{cy - 30}" rx="34" ry="16" fill="{C["primary"]}" opacity="0.28"/>')
            body.append(f'<ellipse cx="{cx}" cy="{cy - 32}" rx="18" ry="8" fill="{C["primary"]}" opacity="0.5"/>')
        elif i == 1:
            f = np.linspace(1, 40, 120)
            y = 30 - 18 * np.log10(f) + 6 * np.exp(-((f - 10) ** 2) / 4)
            body.append(path(x + 20 + (f - 1) / 39 * (w - 40), cy + 30 - (y - y.min()) / (y.max() - y.min()) * 70, C["text"], 1.6))
            body.append(f'<line x1="{x + 20}" x2="{x + w - 20}" y1="{cy + 34}" y2="{cy + 34}" stroke="{C["muted"]}" stroke-width="1"/>')
            body.append(tx(x + w - 20, cy + 50, "Hz", lang, 10.5, C["muted"], "end", mono=True))
        else:
            tt = np.linspace(0, 1, 300)
            y = 0.25 * np.sin(2 * np.pi * 9 * tt) + sum(np.exp(-((tt - c) ** 2) / 0.0015) for c in (0.3, 0.75))
            body.append(path(x + 15 + tt * (w - 30), cy + 20 - y * 45, C["text"], 1.3))
            body.append(tx(x + w - 15, cy + 50, "s", lang, 10.5, C["muted"], "end", mono=True))
        body.append(tx(x + w / 2, 196, T[k][lang], lang, 14, weight=600))
        body.append(tx(x + w / 2, 220, T[q][lang], lang, 12.5, C["muted"]))
    label = {"ar": "بطاقة مكوّن ICA فيها ثلاث لوحات: خريطة الرأس تقول من أين يأتي، والطيف يقول أي ترددات فيه، والسلسلة الزمنية تقول كيف يتغيّر مع الوقت.",
             "en": "An ICA component card has three panels: the scalp map shows where it is, the spectrum which frequencies it has, and the time series how it changes over time."}[lang]
    save(out, f"iclabel/ic-three-panels.{lang}.svg", svg(W, H, body, label))


# --- 4. before / after on D1 --------------------------------------------------------------

def blink_window(src, sf, seconds):
    """Start sample of the 5-s window holding the most blink peaks of the eye component.
    Peaks: local maxima (within +/-0.3 s) above half of the 99.9th percentile, sign set by skewness."""
    from scipy.ndimage import maximum_filter1d
    x = src * np.sign(np.mean(src ** 3))
    thr = 0.5 * np.quantile(x, 0.999)
    win = int(0.6 * sf) | 1
    pk = np.flatnonzero((x > thr) & (x == maximum_filter1d(x, win)))
    n, edge = int(seconds * sf), int(10 * sf)
    pk = pk[(pk > edge) & (pk < len(x) - edge - n)]
    best, start = -1, edge
    for p0 in pk:
        s0 = max(edge, p0 - int(1 * sf))
        c = int(np.sum((pk >= s0) & (pk < s0 + n)))
        if c > best:
            best, start = c, s0
    return start


def draw_before_after(out, d1, langs):
    import mne
    from mne.preprocessing import ICA
    from mne_icalabel.iclabel import iclabel_label_components

    raw = mne.io.read_raw_eeglab(d1, preload=True, verbose="error")
    raw.set_montage(raw.get_montage(), verbose="error")
    # Main dataset as in the lesson Starting point: 0.1 Hz high-pass, 58-62 Hz band-stop,
    # average reference computed without EOG1/EOG2 (those two are left unreferenced, as pop_reref 'exclude').
    main = raw.copy().filter(0.1, None, fir_window="hamming", verbose="error")
    main.filter(62, 58, l_trans_bandwidth=2, h_trans_bandwidth=2, fir_window="hamming", verbose="error")
    eog = [main.ch_names.index(c) for c in ("EOG1", "EOG2")]
    eeg = [i for i in range(len(main.ch_names)) if i not in eog]
    main._data[eeg] -= main._data[eeg].mean(axis=0, keepdims=True)
    fit = main.copy().filter(1, None, fir_window="hamming", verbose="error")
    ica = ICA(n_components=len(raw.ch_names) - 1, method="picard", fit_params=dict(extended=True, ortho=False),
              max_iter=1000, random_state=0)
    ica.fit(fit, verbose="error")
    p = iclabel_label_components(fit, ica)          # Brain, Muscle, Eye, ...
    flagged = [int(i) for i in np.flatnonzero((p[:, 1] > 0.9) | (p[:, 2] > 0.9))]
    eye = int(np.argmax(p[:, 2]))
    if eye not in flagged:
        flagged.append(eye)
    clean = ica.apply(main.copy(), exclude=flagged, verbose="error")
    chans = ["FPz", "EOG1", "EOG2", "F3", "Fz", "F4"]
    sf = raw.info["sfreq"]
    src = ica.get_sources(main).get_data()[eye]
    i0 = blink_window(src, sf, 5.0)
    sl = slice(i0, i0 + int(5 * sf))
    A = main.get_data(picks=chans)[:, sl] * 1e6
    Bc = clean.get_data(picks=chans)[:, sl] * 1e6
    t = np.arange(A.shape[1]) / sf
    W, H = 720, 492
    L, Rr, Tp = 70, 700, 120
    gap = 52
    scale = 1.6 * gap / np.abs(A).max()   # the largest blink spans about one and a half rows
    for lang in langs:
        body = [f'<rect width="{W}" height="{H}" fill="{C["surface"]}"/>']
        for i, ch in enumerate(chans):
            yc = Tp + 20 + i * gap
            xs = L + t / t[-1] * (Rr - L)
            body.append(tx(L - 10, yc + 4, ch, lang, 11, C["muted"], "end", mono=True))
            body.append(path(xs, yc - A[i] * scale, C["text"], 1.1))
            body.append(path(xs, yc - Bc[i] * scale, RED, 1.3))
        yb = Tp + 20 + len(chans) * gap - 10
        body.append(f'<line x1="{L}" x2="{Rr}" y1="{yb}" y2="{yb}" stroke="{C["text"]}" stroke-width="1"/>')
        for s in range(0, 6):
            body.append(tx(L + s / 5 * (Rr - L), yb + 16, f"{s}", lang, 10.5, C["muted"], mono=True))
        body.append(tx((L + Rr) / 2, yb + 34, T["ba_time"][lang], lang, 11.5, C["muted"]))
        lx = [L, L + 160] if lang == "en" else [Rr, Rr - 130]
        anc = "start" if lang == "en" else "end"
        sg = 1 if lang == "en" else -1
        body.append(path([lx[0], lx[0] + 26 * sg], [22, 22], C["text"], 1.6))
        body.append(tx(lx[0] + 32 * sg, 26, T["ba_before"][lang], lang, 12.5, anchor=anc))
        body.append(path([lx[1], lx[1] + 26 * sg], [22, 22], RED, 1.8))
        body.append(tx(lx[1] + 32 * sg, 26, T["ba_after"][lang], lang, 12.5, anchor=anc))
        label = {"ar": "خمس ثوانٍ من ست قنوات أمامية في eeglab_data.set: قبل الحذف (بالأسود) تظهر قمم رمش كبيرة، وبعد حذف مكوّن الرمش (بالأحمر) تختفي القمم ويبقى باقي الإشارة شبه مطابق.",
                 "en": "Five seconds of six frontal channels from eeglab_data.set: before removal (black) large blink peaks appear; after removing the blink component (red) the peaks are gone and the rest of the signal is almost identical."}[lang]
        save(out, f"iclabel/iclabel-before-after.{lang}.svg", svg(W, H, body, label))
    print(f"removed: {[e + 1 for e in flagged]}  blink IC{eye + 1} p_eye={p[eye, 2]:.2f}  window {i0 / sf:.2f}-{(i0 + int(5 * sf)) / sf:.2f} s")


# --- 5. import formats table ---------------------------------------------------------------

def draw_formats(out, lang):
    W, H = 720, 300
    rtl = lang == "ar"
    widths = [150, 270, 260]
    xs = [20, 170, 440]
    if rtl:
        xs = [W - x - w for x, w in zip(xs, widths)]
    top, hh, rh = 20, 44, 76
    exts = [[".edf"], [".bdf"], [".vhdr", ".vmrk  .eeg"]]
    body = [f'<rect width="{W}" height="{H}" fill="{C["surface"]}"/>']
    body.append(f'<rect x="20" y="{top}" width="{W - 40}" height="{hh}" rx="8" fill="{C["fill"]}"/>')
    for x, w, head in zip(xs, widths, T["fmt_cols"][lang]):
        body.append(tx(x + w / 2, top + 28, head, lang, 13.5, weight=600))
    for r in range(3):
        y0 = top + hh + r * rh
        if r:
            body.append(f'<line x1="20" x2="{W - 20}" y1="{y0}" y2="{y0}" stroke="{C["sep"]}" stroke-width="1"/>')
        cells = [exts[r], T["fmt_rows"][lang][r], T["fmt_how"][lang][r]]
        for c, (x, w, lines) in enumerate(zip(xs, widths, cells)):
            y = y0 + rh / 2 - (len(lines) - 1) * 10 + 5
            for k, line in enumerate(lines):
                mono = c == 0 or line.startswith(".")
                body.append(tx(x + w / 2, y + k * 20, line, lang, 14 if c == 0 else 13, weight=600 if c == 0 else 400, mono=mono))
    yb = top + hh + 3 * rh
    body.append(f'<rect x="20" y="{top}" width="{W - 40}" height="{yb - top}" rx="8" fill="none" stroke="{C["sep"]}" stroke-width="1"/>')
    label = {"ar": "جدول صيغ الملفات: ملف .edf من أنظمة سريرية وبحثية كثيرة وبيانات PhysioNet يُستورد بالإضافة Biosig؛ ملف .bdf من أجهزة BioSemi بالإضافة Biosig مع اختيار قناة مرجع؛ وملفات .vhdr و .vmrk و .eeg من أجهزة Brain Products بالإضافة bva-io من ملف .vhdr.",
             "en": "File formats table: .edf from many clinical and research systems and PhysioNet data, imported with the Biosig plugin; .bdf from BioSemi systems, Biosig with a reference channel; .vhdr, .vmrk and .eeg from Brain Products systems, bva-io plugin from the .vhdr file."}[lang]
    save(out, f"import-raw/import-formats.{lang}.svg", svg(W, yb + 20, body, label))


# --- 6. two copies for ICA ---------------------------------------------------------------

def draw_two_copies(out, lang):
    W, H = 720, 260
    rtl = lang == "ar"
    bw, bh, by = 230, 110, 24
    left, right = 40, W - 40 - bw
    main_x, ica_x = (right, left) if rtl else (left, right)
    body = [f'<rect width="{W}" height="{H}" fill="{C["surface"]}"/>']
    for x, name, hp, stroke in ((main_x, T["cp_main"][lang], "high-pass 0.1 Hz", C["text"]),
                                (ica_x, T["cp_ica"][lang], "high-pass 1 Hz", C["primary"])):
        body.append(f'<rect x="{x}" y="{by}" width="{bw}" height="{bh}" rx="12" fill="{C["fill"]}" stroke="{stroke}" stroke-width="1.6"/>')
        body.append(tx(x + bw / 2, by + 44, name, lang, 15, weight=600))
        body.append(tx(x + bw / 2, by + 72, hp, lang, 12.5, C["muted"], mono=True))
    # main -> ICA copy (top), ICA copy -> main (bottom)
    a0, a1 = (main_x + bw, ica_x) if not rtl else (main_x, ica_x + bw)
    sg = 1 if a1 > a0 else -1
    for y, (x1, x2), word, stroke in ((by + 30, (a0 + 12 * sg, a1 - 12 * sg), T["cp_filter"][lang], C["text"]),
                                      (by + bh - 30, (a1 - 12 * sg, a0 + 12 * sg), T["cp_copy"][lang], C["primary"])):
        d = 1 if x2 > x1 else -1
        body.append(f'<line x1="{x1}" x2="{x2}" y1="{y}" y2="{y}" stroke="{stroke}" stroke-width="1.6"/>')
        body.append(f'<path d="M{x2},{y} l{-9 * d},-5 v10 z" fill="{stroke}"/>')
        body.append(tx((x1 + x2) / 2, y - 9, word, lang, 12.5, C["muted"]))
    cx = ica_x + bw / 2
    body.append(f'<rect x="{cx - 62}" y="{by + bh + 26}" width="124" height="34" rx="17" fill="{C["primary"]}"/>')
    body.append(tx(cx, by + bh + 48, T["cp_run"][lang], lang, 13, "#FFFFFF", weight=600))
    body.append(f'<line x1="{cx}" x2="{cx}" y1="{by + bh + 26}" y2="{by + bh + 2}" stroke="{C["primary"]}" stroke-width="1.6"/>')
    label = {"ar": "نسختان من نفس البيانات: النسخة الرئيسية بفلتر high-pass 0.1 هرتز، ونسخة ICA بفلتر 1 هرتز. نشغّل ICA على نسخة ICA، ثم ننسخ الأوزان إلى النسخة الرئيسية.",
             "en": "Two copies of the same data: the main dataset with a 0.1 Hz high-pass and the ICA copy with a 1 Hz high-pass. ICA runs on the ICA copy, then the weights are copied back to the main dataset."}[lang]
    save(out, f"run-ica/ica-two-copies.{lang}.svg", svg(W, by + bh + 80, body, label))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--d1")
    a = ap.parse_args()
    for lang in ("ar", "en"):
        draw_edge(a.out, lang)
        draw_mixing(a.out, lang)
        draw_three_panels(a.out, lang)
        draw_formats(a.out, lang)
        draw_two_copies(a.out, lang)
    if a.d1:
        draw_before_after(a.out, a.d1, ("ar", "en"))


if __name__ == "__main__":
    main()
