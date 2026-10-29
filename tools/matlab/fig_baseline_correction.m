% FIG_BASELINE_CORRECTION  Before/after pair for lesson baseline-correction from D1.
%   20 epochs of Pz from 'D1 epochs' (before) and after pop_rmbase on -200 to 0 ms (after), thin gray
%   lines, -1000 to 1992 ms, -40 to 40 uV, the baseline period shaded. Same frame in both images.
%
% Needs 'D1 main clean lp30' (sea_clean: saved by fig_iclabel.m, or rebuilt with a fixed ICA seed).
% Output in assets-src/lessons/baseline-correction/:
%   baseline-correction-pz-before.png, baseline-correction-pz-after.png
%   facts.txt   baseline points, spread of the epoch means in the baseline before and after

cfg = sea_init();
ep = sea_epochs(cfg);
rel = fullfile('lessons', 'baseline-correction');
pz = find(strcmp({ep.raw.chanlocs.labels}, 'Pz'));
n = min(20, ep.raw.trials);
bl = ep.raw.times >= -200 & ep.raw.times <= 0;

xB = squeeze(ep.raw.data(pz, :, 1:n));
xA = squeeze(ep.bl.data(pz, :, 1:n));
plot_epochs(ep.raw.times, xB);
sea_export(gcf, cfg, fullfile(rel, 'baseline-correction-pz-before.png'), [1000 520]);
plot_epochs(ep.bl.times, xA);
sea_export(gcf, cfg, fullfile(rel, 'baseline-correction-pz-after.png'), [1000 520]);

mB = mean(xB(bl, :), 1); mA = mean(xA(bl, :), 1);
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nepochs shown: %d of %d\nbaseline points: %d\nbaseline means at Pz: before %.1f to %.1f uV | after %.2g to %.2g uV\nvalues outside -40..40 uV: before %d | after %d\n', ...
    cfg.stamp, n, ep.raw.trials, sum(bl), min(mB), max(mB), min(mA), max(mA), ...
    nnz(abs(xB) > 40), nnz(abs(xA) > 40));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

function plot_epochs(times, x)
% Thin gray epochs over a shaded baseline; fixed axes position and limits so the pair aligns.
figure;
ax = axes('Units', 'normalized', 'Position', [0.08 0.13 0.9 0.82]);
hold(ax, 'on');
patch(ax, [-200 0 0 -200], [-40 -40 40 40], [0.88 0.88 0.88], 'EdgeColor', 'none');
plot(ax, times, x, 'Color', [0.45 0.45 0.45], 'LineWidth', 0.6);
xline(ax, 0, ':'); yline(ax, 0, 'k');
set(ax, 'XLim', [times(1) times(end)], 'YLim', [-40 40], 'Box', 'off', 'Layer', 'top');
xlabel(ax, 'Time (ms)'); ylabel(ax, 'Amplitude (\muV)');
end
