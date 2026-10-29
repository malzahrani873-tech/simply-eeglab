% FIG_ERP_AVERAGE  Figure for lesson erp-average from D1: why averaging works.
%   Three panels for Pz from 'D1 epochs clean', same axes (-200 to 800 ms, -30 to 30 uV, positive up):
%   one epoch, the average of the first 10 epochs, the average of all epochs. The single epoch is
%   clipped by the axis on purpose so the three axes stay identical.
%
% Output in assets-src/lessons/erp-average/:
%   erp-average-1-10-all.png   the trial count is written above each panel (n = ...)
%   facts.txt                  epochs, positive peak at Pz between 250 and 600 ms

cfg = sea_init();
ep = sea_epochs(cfg);
EEG = ep.clean;
rel = fullfile('lessons', 'erp-average');
pz = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
x = squeeze(EEG.data(pz, :, :));
counts = [1 10 EEG.trials];

figure;
for k = 1:3
    ax = subplot(1, 3, k);
    y = mean(x(:, 1:counts(k)), 2);
    plot(ax, EEG.times, y, 'k', 'LineWidth', 1.2);
    hold(ax, 'on');
    xline(ax, 0, ':'); yline(ax, 0);
    set(ax, 'XLim', [-200 800], 'YLim', [-30 30], 'Box', 'off', 'Clipping', 'on');
    title(ax, sprintf('n = %d', counts(k)), 'FontWeight', 'normal');
    xlabel(ax, 'Time (ms)');
    if k == 1, ylabel(ax, 'Amplitude (\muV)'); end
end
sea_export(gcf, cfg, fullfile(rel, 'erp-average-1-10-all.png'), [1200 420]);

erp = mean(x, 2);
win = EEG.times >= 250 & EEG.times <= 600;
wt = EEG.times(win);
[pk, i] = max(erp(win));
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nepochs: %d\npositive peak at Pz (250-600 ms): %.1f uV at %.0f ms\nsingle epoch range: %.1f to %.1f uV\n', ...
    cfg.stamp, EEG.trials, pk, wt(i), min(x(:, 1)), max(x(:, 1)));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
