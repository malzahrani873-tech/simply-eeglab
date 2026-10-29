% FIG_TOPOPLOT  Before/after pair for lesson topoplot (07-01), from D1 epochs clean (sea_epochs.m).
%
% Output in assets-src/lessons/topoplot/ (both PNGs 900 x 640 px, same grid and frame):
%   topoplot-scales-before.png   ERP maps at 0:100:500 ms, each drawn with topoplot 'maplimits' 'maxmin'
%                                and its own color bar
%   topoplot-scales-after.png    the same latencies from Plot > ERP map series > In 2-D (pop_topoplot):
%                                one shared symmetric scale and one color bar, as in the lesson
%   facts.txt                    per-map range, the shared limit, number of epochs
%
% Both images use the EEGLAB default colormap (icadefs DEFAULT_COLORMAP).

cfg = sea_init();
ep = sea_epochs(cfg);
EEG = ep.clean;
EEG = pop_select(EEG, 'rmchannel', cfg.d1_eog);      % scalp channels only, as in the lesson
EEG.setname = 'D1 epochs clean scalp';
rel = fullfile('lessons', 'topoplot');
if ~exist(fullfile(cfg.out, rel), 'dir'), mkdir(fullfile(cfg.out, rel)); end
lat = 0:100:500;
sizepx = [900 640];

erp = mean(EEG.data, 3);
[~, idx] = arrayfun(@(t) min(abs(EEG.times - t)), lat);

% --- Before: same 2 x 3 grid, but every map scaled to its own minimum and maximum -------
fig = figure('Color', 'w');
ranges = zeros(numel(lat), 2);
for k = 1:numel(lat)
    subplot(2, 3, k);
    v = erp(:, idx(k));
    ranges(k, :) = [min(v) max(v)];
    topoplot(v, EEG.chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
    title(sprintf('%d ms', lat(k)));
    colorbar;
end
textsc(0.5, 0.05, EEG.setname);
sea_export(fig, cfg, fullfile(rel, 'topoplot-scales-before.png'), sizepx);

% --- After: the lesson's map series, one shared scale -------------------------------------
pop_topoplot(EEG, 1, lat, EEG.setname, [2 3], 0, 'electrodes', 'on');
sea_export(gcf, cfg, fullfile(rel, 'topoplot-scales-after.png'), sizepx);

% --- Facts --------------------------------------------------------------------------------
shared = max(abs(erp(:, idx)), [], 'all');
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nepochs %d | scalp channels %d | colormap %s\n', cfg.stamp, EEG.trials, EEG.nbchan, cfg.colormap);
for k = 1:numel(lat)
    fprintf(fid, '%4d ms (sample %.1f ms): min %6.2f  max %6.2f uV\n', lat(k), EEG.times(idx(k)), ranges(k, 1), ranges(k, 2));
end
fprintf(fid, 'shared scale (after): -%.2f to %.2f uV\n', shared, shared);
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
