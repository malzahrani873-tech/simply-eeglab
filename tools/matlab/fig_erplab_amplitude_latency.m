% FIG_ERPLAB_AMPLITUDE_LATENCY  Figure for lesson erplab-amplitude-latency from Luck's chapter 10 data
%   (ERP CORE LRP difference waves, CC BY-SA 4.0). Grand average of the 40 ERPsets at C3/C4, bin 1
%   (Compatible), -200 to 800 ms, negative down. The 150-400 ms window is shaded, the mean amplitude
%   is a dashed line, and the negative local peak (3 points each side, as 'Neighborhood', 3) is a dot
%   with a vertical line to the time axis.
%
% Needs ERPLAB and <cfg.course_dir>/Chapter_10/Data/ERPsets_CI_Diff (run_checklist 0.2).
% Output in assets-src/lessons/erplab-amplitude-latency/:
%   erplab-lrp-grand-c3c4-measures.png
%   facts.txt   ERPsets, mean amplitude, peak amplitude and latency of the grand average

cfg = sea_init();
assert(exist('pop_loaderp', 'file') == 2, 'sea:plugin', 'ERPLAB not found (File > Manage EEGLAB extensions).');
dataDir = fullfile(cfg.course_dir, 'Chapter_10', 'Data', 'ERPsets_CI_Diff');
files = dir(fullfile(dataDir, '*.erp'));
assert(~isempty(files), 'sea:nodata', 'No .erp files in %s (run_checklist 0.2).', dataDir);
[~, ALLERP] = pop_loaderp('filename', {files.name}, 'filepath', dataDir, 'UpdateMainGui', 'off');
rel = fullfile('lessons', 'erplab-amplitude-latency');

chan = find(strcmp({ALLERP(1).chanlocs.labels}, 'C3/C4'));
times = ALLERP(1).times;
all1 = cell2mat(arrayfun(@(E) E.bindata(chan, :, 1), ALLERP(:), 'UniformOutput', false));   % ERPsets x time
ga = mean(all1, 1);
bl = times < 0;
ga = ga - mean(ga(bl));                            % baseline 'pre', as in the lesson's measures

win = times >= 150 & times <= 400;
meanAmp = mean(ga(win));
[peakAmp, peakLat] = local_neg_peak(ga, times, win, 3);

figure;
ax = axes('Units', 'normalized', 'Position', [0.09 0.13 0.88 0.82]);
hold(ax, 'on');
yl = [floor(min(ga) - 1), ceil(max(ga) + 1)];
patch(ax, [150 400 400 150], yl([1 1 2 2]), [0.88 0.88 0.88], 'EdgeColor', 'none');
plot(ax, times, ga, 'k', 'LineWidth', 1.6);
plot(ax, [150 400], [meanAmp meanAmp], '--', 'Color', [0 0.3 0.75], 'LineWidth', 1.2);
plot(ax, [peakLat peakLat], [0 peakAmp], '-', 'Color', [0.85 0.2 0.1], 'LineWidth', 1);
plot(ax, peakLat, peakAmp, 'o', 'MarkerFaceColor', [0.85 0.2 0.1], 'MarkerEdgeColor', 'none', 'MarkerSize', 7);
xline(ax, 0, ':'); yline(ax, 0, 'k');
set(ax, 'XLim', [-200 800], 'YLim', yl, 'Box', 'off', 'Layer', 'top');
xlabel(ax, 'Time (ms)'); ylabel(ax, 'Amplitude (\muV)');
sea_export(gcf, cfg, fullfile(rel, 'erplab-lrp-grand-c3c4-measures.png'), [1000 520]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nERPsets: %d, channel %s, bin 1 (%s)\ngrand average, 150-400 ms: mean %.2f uV, negative local peak %.2f uV at %.0f ms\n', ...
    cfg.stamp, numel(ALLERP), ALLERP(1).chanlocs(chan).labels, ALLERP(1).bindescr{1}, meanAmp, peakAmp, peakLat);
fprintf(fid, 'Data: ERP CORE (Kappenman et al., 2021) via Luck (2022), chapter 10. Image licence CC BY-SA 4.0.\n');
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

function [amp, lat] = local_neg_peak(y, t, win, nb)
% Most negative point in the window that is below its nb neighbours on each side and below the mean
% of each side (ERPLAB local peak). Falls back to the window minimum when no local peak exists.
idx = find(win);
amp = Inf; lat = NaN;
for i = idx
    if i - nb < 1 || i + nb > numel(y), continue; end
    L = y(i - nb:i - 1); R = y(i + 1:i + nb);
    if all(y(i) < L) && all(y(i) < R) && y(i) < mean(L) && y(i) < mean(R) && y(i) < amp
        amp = y(i); lat = t(i);
    end
end
if isnan(lat)
    [amp, k] = min(y(idx)); lat = t(idx(k));
end
end
