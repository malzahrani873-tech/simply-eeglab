% FIG_FILTERING  Figures for lesson filtering from D1 (eeglab_data.set).
%
% Output in assets-src/lessons/filtering/:
%   filtering-spectra-before.png   Plot > Channel spectra and maps before filtering (1-64 Hz)
%   filtering-spectra-after.png    same plot after high-pass 0.1 then low-pass 30 (the lesson exercise, EEG_lp)
%   filtering-freqz-hp1.png        response of a 1 Hz high-pass (Plot frequency response option)
%   facts.txt                      filter order and -6 dB cutoff as printed by firfilt, 60 Hz peak before/after
%
% In the course pipeline only the 0.1 Hz high-pass is kept here; the 30 Hz low-pass is applied after
% ICA component removal (fig_iclabel.m). The "after" spectrum matches the lesson's exercise figure.

cfg = sea_init();
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = eeg_checkset(EEG);
rel = fullfile('lessons', 'filtering');
specargs = {'percent', 100, 'freq', [6 10 22], 'freqrange', [1 64], 'electrodes', 'off'};

% --- Before ----------------------------------------------------------------------
figure;
pop_spectopo(EEG, 1, [0 EEG.xmax * 1000], 'EEG', specargs{:});
pk0 = peak60(EEG);
ylimBefore = ylim(findSpecAxes(gcf));
sea_export(gcf, cfg, fullfile(rel, 'filtering-spectra-before.png'), [900 560]);

% --- Filtering as in the lesson: one filter per step -------------------------------
log1 = evalc('EEG = pop_eegfiltnew(EEG, ''locutoff'', cfg.erp_hp);');
pkHP = peak60(EEG);
log2 = evalc('EEG = pop_eegfiltnew(EEG, ''hicutoff'', cfg.erp_lp);');
EEG = eeg_checkset(EEG);
pk1 = peak60(EEG);

% --- After (same vertical axis for comparison) ---------------------------------------
figure;
pop_spectopo(EEG, 1, [0 EEG.xmax * 1000], 'EEG', specargs{:});
ylim(findSpecAxes(gcf), ylimBefore);
sea_export(gcf, cfg, fullfile(rel, 'filtering-spectra-after.png'), [900 560]);

% --- 1 Hz high-pass response (passband edge is not the cutoff) ---------------------------
EEG0 = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
log3 = evalc('[~, ~, b] = pop_eegfiltnew(EEG0, ''locutoff'', 1, ''plotfreqz'', 1);');
sea_export(gcf, cfg, fullfile(rel, 'filtering-freqz-hp1.png'), [900 640]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nsrate %g Hz\n--- HP %g ---\n%s\n--- LP %g ---\n%s\n--- HP 1 (freqz) ---\n%s\norder %d\n', ...
    cfg.stamp, EEG.srate, cfg.erp_hp, log1, cfg.erp_lp, log2, log3, numel(b) - 1);
fprintf(fid, '60 Hz peak above 55-57/63-64 Hz neighbours (dB, channel mean): raw %.1f | hp0.1 %.1f | hp0.1+lp30 %.1f\n', pk0, pkHP, pk1);
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

function d = peak60(EEG)
% Height of the 60 Hz peak above its neighbours, channel average (dB).
d = sea_db(EEG, 60) - mean(sea_db(EEG, [56 57 63 64]));
end

function ax = findSpecAxes(fig)
% The spectrum axes is the widest axes in the figure (the small maps sit above it).
axs = findobj(fig, 'Type', 'axes');
w = arrayfun(@(a) a.Position(3), axs);
[~, k] = max(w);
ax = axs(k);
end
