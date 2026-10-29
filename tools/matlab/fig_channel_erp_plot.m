% FIG_CHANNEL_ERP_PLOT  Before/after pair for lesson channel-erp-plot (07-02), D1 epochs clean.
%
% Output in assets-src/lessons/channel-erp-plot/ (both PNGs 900 x 560 px, same axes position,
% time window and vertical range):
%   channel-erp-before.png   Pz ERP for position 1 and 2, negative up, no labels, zero lines or legend
%   channel-erp-after.png    the lesson's plot: positive up, axis labels, lines at 0 ms and 0 uV,
%                            legend with trial counts, channel name as title
%   facts.txt                trials per condition, peak at Pz per condition

cfg = sea_init();
ep = sea_epochs(cfg);
EEG = ep.clean;
rel = fullfile('lessons', 'channel-erp-plot');
if ~exist(fullfile(cfg.out, rel), 'dir'), mkdir(fullfile(cfg.out, rel)); end
sizepx = [900 560];
axpos = [0.10 0.13 0.86 0.78];

% Conditions as in the lesson: position of the time-locking 'square' event
pos = eeg_getepochevent(EEG, 'type', {'square'}, 'timewin', [-5 5], 'fieldname', 'position');
EEG_pos1 = pop_select(EEG, 'trial', find(pos == 1));
EEG_pos2 = pop_select(EEG, 'trial', find(pos == 2));
chan = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
erp1 = mean(EEG_pos1.data(chan, :, :), 3);
erp2 = mean(EEG_pos2.data(chan, :, :), 3);
win = EEG.times >= -200 & EEG.times <= 800;
yl = [min([erp1(win) erp2(win)]) max([erp1(win) erp2(win)])];
yl = yl + [-0.1 0.1] * diff(yl);

% --- Before ----------------------------------------------------------------------------
fig = figure('Color', 'w');
ax = axes('Position', axpos); hold(ax, 'on');
plot(ax, EEG.times, erp1, 'LineWidth', 1.5);
plot(ax, EEG.times, erp2, 'LineWidth', 1.5);
xlim(ax, [-200 800]); ylim(ax, yl);
set(ax, 'YDir', 'reverse');
sea_export(fig, cfg, fullfile(rel, 'channel-erp-before.png'), sizepx);

% --- After (the lesson block) ------------------------------------------------------------
fig = figure('Color', 'w');
ax = axes('Position', axpos); hold(ax, 'on');
plot(ax, EEG.times, erp1, 'LineWidth', 1.5);
plot(ax, EEG.times, erp2, 'LineWidth', 1.5);
xline(ax, 0, 'k:');
yline(ax, 0, 'k-');
xlim(ax, [-200 800]); ylim(ax, yl);
set(ax, 'YDir', 'normal');
xlabel(ax, 'Time (ms)');
ylabel(ax, 'Potential (\muV)');
legend(ax, {sprintf('Position 1 (n = %d)', EEG_pos1.trials), ...
            sprintf('Position 2 (n = %d)', EEG_pos2.trials)}, 'Location', 'best');
title(ax, 'Pz');
set(ax, 'Position', axpos);
sea_export(fig, cfg, fullfile(rel, 'channel-erp-after.png'), sizepx);

% --- Facts --------------------------------------------------------------------------------
[p1, i1] = max(erp1(win)); [p2, i2] = max(erp2(win)); t = EEG.times(win);
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nposition 1: %d epochs | position 2: %d epochs\n', cfg.stamp, EEG_pos1.trials, EEG_pos2.trials);
fprintf(fid, 'Pz maximum: position 1 %.2f uV at %.0f ms | position 2 %.2f uV at %.0f ms\n', p1, t(i1), p2, t(i2));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
