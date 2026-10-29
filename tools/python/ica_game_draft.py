"""
ica_game_draft.py - ICA game images from OpenNeuro ds002718 (CC0) in Python.

Pipeline that produces the published ICA game images (no MATLAB needed):
  1. Read one subject's .set file (EEGLAB format inside BIDS).
  2. Channel types: EEG061=HEOG, EEG062=VEOG, EEG063/064=ECG (from channels.tsv).
  3. 1 Hz high-pass + 100 Hz low-pass (FIR, Hamming), each segment between boundary events separately.
  4. Average reference over EEG channels only (no EOG or ECG).
  5. ICA: Picard with extended=True and ortho=False (converges to the Extended Infomax solution).
  6. ICLabel through mne-icalabel (the same trained ICLabel network).
  7. Independent check: correlation of each component time course with HEOG, VEOG and ECG.
  8. One image per component: scalp map (turbo, as in EEGLAB 2026.1) + spectrum 1-80 Hz + 5 s.
     No title, component number or class (nothing that gives the answer away).

Usage:
  python3 -I ica_game_draft.py --set <path/to/sub-XXX_task-FaceRecognition_eeg.set> --out <outdir>

Output in outdir:
  candidates.csv   the seven ICLabel probabilities, correlations and suggested level per component
  png/ICxx.png     one image per component (720x280) before conversion
  webp/ICxx.webp   the same image as WebP, quality 80
"""
import argparse
import csv
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mne
import numpy as np
from mne.preprocessing import ICA
from mne_icalabel.iclabel import iclabel_label_components
from PIL import Image
from scipy.signal import welch

CLASSES = ["brain", "muscle", "eye", "heart", "line", "chan", "other"]
W, H, DPI = 720, 280, 100


def load(path):
    raw = mne.io.read_raw_eeglab(path, preload=True, verbose="error")
    raw.set_channel_types(
        {"EEG061": "eog", "EEG062": "eog", "EEG063": "ecg", "EEG064": "ecg"},
        verbose="error",
    )
    # EEGLAB boundary = discontinuity. Rename to edge so MNE filters each segment separately, like pop_eegfiltnew.
    ann = raw.annotations
    raw.set_annotations(
        mne.Annotations(
            ann.onset,
            ann.duration,
            ["edge" if d == "boundary" else d for d in ann.description],
        )
    )
    return raw


def preprocess(raw):
    raw.filter(1.0, 100.0, fir_window="hamming", fir_design="firwin", verbose="error")
    raw.set_eeg_reference("average", ch_type="eeg", verbose="error")
    return raw


def run_ica(raw, seed):
    eeg = raw.copy().pick("eeg")
    n = len(eeg.ch_names) - 1  # average reference lowers the rank by one
    ica = ICA(
        n_components=n,
        method="picard",
        fit_params=dict(extended=True, ortho=False),
        max_iter=1000,
        random_state=seed,
    )
    ica.fit(eeg, decim=2, verbose="error")
    return eeg, ica


def blink_window(raw, length=5.0):
    """One fixed 5-s window for all components: the first window after the first minute with two or
    more blinks in VEOG. A single objective rule, so the window never favours a component."""
    veog = raw.get_data(picks="EEG062")[0]
    sf = raw.info["sfreq"]
    thr = np.percentile(np.abs(veog), 99.5)
    step = int(length * sf)
    for start in range(int(60 * sf), len(veog) - step, step // 2):
        seg = np.abs(veog[start : start + step])
        peaks = np.flatnonzero((seg[1:-1] > thr) & (seg[1:-1] >= seg[:-2]) & (seg[1:-1] >= seg[2:]))
        if len(peaks) and (np.diff(peaks) > sf * 0.4).sum() + 1 >= 2:
            return start, start + step
    return int(60 * sf), int(60 * sf) + step


def corr_with(raw, sources, picks):
    ref = raw.get_data(picks=picks)
    out = []
    for s in sources:
        out.append(max(abs(np.corrcoef(s, r)[0, 1]) for r in ref))
    return np.array(out)


def render(ica, eeg, sources, k, win, path_png):
    sf = eeg.info["sfreq"]
    fig = plt.figure(figsize=(W / DPI, H / DPI), dpi=DPI, facecolor="white")
    gs = fig.add_gridspec(1, 3, width_ratios=[1.0, 1.35, 1.65], left=0.02, right=0.985, bottom=0.17, top=0.95, wspace=0.32)

    ax = fig.add_subplot(gs[0])
    mne.viz.plot_topomap(
        ica.get_components()[:, k],
        eeg.info,
        axes=ax,
        cmap="turbo",
        contours=6,
        sensors=True,
        show=False,
        extrapolate="head",
    )

    ax = fig.add_subplot(gs[1])
    f, p = welch(sources[k], fs=sf, nperseg=int(2 * sf))
    m = (f >= 1) & (f <= 80)
    ax.plot(f[m], 10 * np.log10(p[m]), color="#111114", lw=1.1)
    ax.set_xlim(1, 80)
    ax.set_xticks([1, 10, 20, 40, 60, 80])
    ax.set_xlabel("Frequency (Hz)", fontsize=8)
    ax.set_ylabel("Power (dB)", fontsize=8)
    ax.tick_params(labelsize=7)
    ax.grid(alpha=0.25, lw=0.5)

    ax = fig.add_subplot(gs[2])
    seg = sources[k, win[0] : win[1]]
    t = np.arange(len(seg)) / sf
    ax.plot(t, seg, color="#111114", lw=0.6)
    ax.set_xlim(0, t[-1])
    ax.set_yticks([])
    ax.set_xlabel("Time (s)", fontsize=8)
    ax.tick_params(labelsize=7)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)

    fig.savefig(path_png, dpi=DPI, facecolor="white")
    plt.close(fig)


def line_peak(x, sf):
    """'50' or '60' when the peak there is 6 dB above its neighbours, otherwise ''."""
    f, p = welch(x, fs=sf, nperseg=int(2 * sf))
    db = 10 * np.log10(p)
    for hz in (50, 60):
        i = int(np.argmin(np.abs(f - hz)))
        nb = np.r_[i - 12 : i - 5, i + 6 : i + 13]
        nb = nb[(nb >= 0) & (nb < len(db))]
        if db[i] - np.median(db[nb]) > 6:
            return str(hz)
    return ""


def suggest_level(p):
    top = int(np.argmax(p))
    if p[top] >= 0.8:
        return 1
    if p[top] >= 0.6:
        return 2
    return 3


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--seed", type=int, default=97)
    ap.add_argument("--quality", type=int, default=80)
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "png"), exist_ok=True)
    os.makedirs(os.path.join(a.out, "webp"), exist_ok=True)

    raw = preprocess(load(a.set))
    cache = os.path.join(a.out, "ica.fif")
    if os.path.exists(cache):
        eeg = raw.copy().pick("eeg")
        ica = mne.preprocessing.read_ica(cache, verbose="error")
    else:
        eeg, ica = run_ica(raw, a.seed)
        ica.save(cache, overwrite=True, verbose="error")
    # Column order as in EEGLAB: Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other
    proba = iclabel_label_components(eeg, ica)

    sources = ica.get_sources(eeg).get_data()
    r_heog = corr_with(raw, sources, "EEG061")
    r_veog = corr_with(raw, sources, "EEG062")
    r_ecg = corr_with(raw, sources, ["EEG063", "EEG064"])
    win = blink_window(raw)

    sub = os.path.basename(a.set).split("_")[0]
    rows = []
    for k in range(ica.n_components_):
        name = f"IC{k + 1:02d}"
        png = os.path.join(a.out, "png", f"{sub}_{name}.png")
        webp = os.path.join(a.out, "webp", f"{sub}_{name}.webp")
        render(ica, eeg, sources, k, win, png)
        Image.open(png).convert("RGB").save(webp, "WEBP", quality=a.quality, method=6)
        p = proba[k]
        rows.append(
            dict(
                sub=sub,
                ic=name,
                img=f"{sub}_{name}.png",
                top=CLASSES[int(np.argmax(p))],
                top_p=round(float(p.max()), 3),
                level_suggested=suggest_level(p),
                **{c: round(float(v), 3) for c, v in zip(CLASSES, p)},
                r_heog=round(float(r_heog[k]), 2),
                r_veog=round(float(r_veog[k]), 2),
                r_ecg=round(float(r_ecg[k]), 2),
                line_hz=line_peak(sources[k], eeg.info["sfreq"]),
                webp_kb=round(os.path.getsize(webp) / 1024, 1),
            )
        )
    with open(os.path.join(a.out, "candidates.csv"), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"window samples {win}; components {ica.n_components_}")


if __name__ == "__main__":
    main()
