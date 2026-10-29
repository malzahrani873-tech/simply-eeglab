% FIG_LINE_NOISE  Before/after pair for lesson line-noise from D1 (60 Hz).
%   Before: Plot > Channel spectra and maps on 'D1 hp0.1'. After: the same plot on 'D1 hp0.1 notch60'.
%   Both images share the pixel size and the vertical axis limits of the "before" plot.
%
% Output in assets-src/lessons/line-noise/:
%   line-noise-spectra-before.png, line-noise-spectra-after.png
%   facts.txt   band-stop order and edges from the firfilt log, 60 Hz peak before and after

cfg = sea_init();
lineFreq = 60;
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
EEG.setname = 'D1 hp0.1';
rel = fullfile('lessons', 'line-noise');
specargs = {'freqrange', [1 64], 'freq', [10 lineFreq]};

figure;
pop_spectopo(EEG, 1, [], 'EEG', specargs{:});
ax = widest_axes(gcf);
yl = ylim(ax);
pk0 = sea_db(EEG, lineFreq) - mean(sea_db(EEG, [56 57 63 64]));
sea_export(gcf, cfg, fullfile(rel, 'line-noise-spectra-before.png'), [900 560]);

notchlog = evalc('EEG = pop_eegfiltnew(EEG, ''locutoff'', lineFreq - 2, ''hicutoff'', lineFreq + 2, ''revfilt'', 1);');
EEG.setname = 'D1 hp0.1 notch60';
figure;
pop_spectopo(EEG, 1, [], 'EEG', specargs{:});
ylim(widest_axes(gcf), yl);
pk1 = sea_db(EEG, lineFreq) - mean(sea_db(EEG, [56 57 63 64]));
sea_export(gcf, cfg, fullfile(rel, 'line-noise-spectra-after.png'), [900 560]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\n--- band-stop %g-%g Hz ---\n%s\n60 Hz peak above 56-57/63-64 Hz (dB, channel mean): before %.1f | after %.1f\nvertical axis (both): %s\n', ...
    cfg.stamp, lineFreq - 2, lineFreq + 2, notchlog, pk0, pk1, mat2str(yl, 4));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

function ax = widest_axes(fig)
% The spectrum axes is the widest axes in the figure (the small maps sit above it).
axs = findobj(fig, 'Type', 'axes');
w = arrayfun(@(a) a.Position(3), axs);
[~, k] = max(w);
ax = axs(k);
end
