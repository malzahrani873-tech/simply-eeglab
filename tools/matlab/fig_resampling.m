% FIG_RESAMPLING  Figure for lesson resampling from D1: the same 2 s of Cz at 128 Hz and at 64 Hz.
%
% Output in assets-src/lessons/resampling/:
%   resampling-cz-128-64.png   128 Hz as small connected dots, 64 Hz as larger connected circles
%   facts.txt                  rate, samples and events before and after, anti-alias cutoff from the log

cfg = sea_init();
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
reslog = evalc('EEG_64 = pop_resample(EEG, 64);');
rel = fullfile('lessons', 'resampling');

cz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));
t1 = (0:2 * EEG.srate - 1) / EEG.srate;
t2 = (0:2 * EEG_64.srate - 1) / EEG_64.srate;
figure;
ax = axes('Units', 'normalized', 'Position', [0.08 0.13 0.9 0.8]);
hold(ax, 'on');
plot(ax, t1, EEG.data(cz, 1:numel(t1)), '.-', 'Color', [0 0.3 0.75], 'MarkerSize', 8, 'LineWidth', 0.8);
plot(ax, t2, EEG_64.data(cz, 1:numel(t2)), 'o-', 'Color', [0.85 0.2 0.1], 'MarkerSize', 5, 'LineWidth', 1);
legend(ax, {'128 Hz', '64 Hz'}, 'Location', 'northeast', 'Box', 'off');
xlabel(ax, 'Time (s)'); ylabel(ax, 'Amplitude (\muV)');
set(ax, 'Box', 'off', 'XLim', [0 2]);
sea_export(gcf, cfg, fullfile(rel, 'resampling-cz-128-64.png'), [1000 460]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nOriginal : %g Hz, %d samples, %d events\nResampled: %g Hz, %d samples, %d events\n--- pop_resample ---\n%s\n', ...
    cfg.stamp, EEG.srate, EEG.pnts, numel(EEG.event), EEG_64.srate, EEG_64.pnts, numel(EEG_64.event), reslog);
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
