% FIG_ICA_1HZ_COPY_WEIGHTS  ERP figure for lesson ica-1hz-copy-weights from D1: why ICA runs on a
%   separate 1 Hz copy. ERP at Pz around the 80 'square' events, -200 to 800 ms, baseline -200 to 0,
%   in the main dataset (0.1 Hz) and in the ICA copy (1 Hz). No ICA is needed for this figure.
%
% Output in assets-src/lessons/ica-1hz-copy-weights/:
%   ica-1hz-erp-pz.png   both curves in one frame, positive up
%   facts.txt            epochs, mean at Pz between 300 and 600 ms in each copy
% The diagram of the two copies is a drawing (draw_concepts), not made here.

cfg = sea_init();
EEG_main = sea_main(cfg);
EEG_ica = pop_eegfiltnew(EEG_main, 'locutoff', cfg.ica_hp);
rel = fullfile('lessons', 'ica-1hz-copy-weights');

epMain = pop_rmbase(pop_epoch(EEG_main, {'square'}, [-0.2 0.8]), [-200 0]);
epIca  = pop_rmbase(pop_epoch(EEG_ica, {'square'}, [-0.2 0.8]), [-200 0]);
pz = find(strcmp({EEG_main.chanlocs.labels}, 'Pz'));
erpMain = mean(epMain.data(pz, :, :), 3);
erpIca  = mean(epIca.data(pz, :, :), 3);
win = epMain.times >= 300 & epMain.times <= 600;

figure;
ax = axes('Units', 'normalized', 'Position', [0.09 0.13 0.88 0.8]);
hold(ax, 'on');
plot(ax, epMain.times, erpMain, 'Color', [0 0.3 0.75], 'LineWidth', 1.6);
plot(ax, epIca.times, erpIca, 'Color', [0.85 0.2 0.1], 'LineWidth', 1.6);
xline(ax, 0, ':'); yline(ax, 0);
legend(ax, {'0.1 Hz', '1 Hz'}, 'Location', 'northwest', 'Box', 'off');
xlabel(ax, 'Time (ms)'); ylabel(ax, 'Amplitude (\muV)');
set(ax, 'Box', 'off', 'XLim', [-200 800]);
sea_export(gcf, cfg, fullfile(rel, 'ica-1hz-erp-pz.png'), [1000 520]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nepochs: %d (main) and %d (1 Hz copy)\nmean at Pz, 300-600 ms: 0.1 Hz %.2f uV | 1 Hz %.2f uV\n', ...
    cfg.stamp, epMain.trials, epIca.trials, mean(erpMain(win)), mean(erpIca(win)));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
