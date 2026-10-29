% Copied from lessons/en/07-04-publication-figures.md. The lesson is the reference.
EEG = pop_loadset('D1_epochs_clean.set', pwd);
pos = eeg_getepochevent(EEG, 'type', {'square'}, 'timewin', [-5 5], 'fieldname', 'position');
EEG_pos1 = pop_select(EEG, 'trial', find(pos == 1));
EEG_pos2 = pop_select(EEG, 'trial', find(pos == 2));
EEG_pos1.setname = 'D1 epochs clean pos1';
EEG_pos2.setname = 'D1 epochs clean pos2';
chan = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
scalp = find(~ismember({EEG.chanlocs.labels}, {'EOG1', 'EOG2'}));   % EOG is not on the average reference
erp1 = mean(EEG_pos1.data, 3);
erp2 = mean(EEG_pos2.data, 3);

% Figure 1: Pz waveforms at single-column size, 9-pt font, white background
fig1 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 9 7]);
hold on;
plot(EEG.times, erp1(chan, :), 'Color', [0 0.45 0.74], 'LineWidth', 1.2);
plot(EEG.times, erp2(chan, :), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2, 'LineStyle', '--');
xline(0, 'k:'); yline(0, 'k-');
xlim([-200 800]);
set(gca, 'YDir', 'normal', 'FontName', 'Arial', 'FontSize', 9, 'TickDir', 'out', 'Box', 'off');
xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend({sprintf('Position 1 (n = %d)', EEG_pos1.trials), ...
        sprintf('Position 2 (n = %d)', EEG_pos2.trials)}, 'Location', 'northeast', 'Box', 'off');
title('Pz', 'FontWeight', 'normal');
exportgraphics(fig1, 'fig_pz_erp.pdf', 'ContentType', 'vector', 'BackgroundColor', 'white');

% Figure 2: 300 to 500 ms maps for both conditions on one shared symmetric scale
win = EEG.times >= 300 & EEG.times <= 500;
map1 = mean(erp1(scalp, win), 2);
map2 = mean(erp2(scalp, win), 2);
lim = ceil(max(abs([map1; map2])));
fprintf('Shared color scale: -%d to %d uV\n', lim, lim);
fig2 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 12 6]);
subplot(1, 2, 1);
topoplot(map1, EEG.chanlocs(scalp), 'maplimits', [-lim lim], 'electrodes', 'on');
title('Position 1', 'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal');
ax = subplot(1, 2, 2);
topoplot(map2, EEG.chanlocs(scalp), 'maplimits', [-lim lim], 'electrodes', 'on');
title('Position 2', 'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal');
axPos = ax.Position;
cb = colorbar('FontName', 'Arial', 'FontSize', 9);
ax.Position = axPos;   % keep both maps the same size
cb.Position = [0.92 0.25 0.02 0.5];
ylabel(cb, '\muV');
exportgraphics(fig2, 'fig_maps_300_500.pdf', 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig2, 'fig_maps_300_500.png', 'Resolution', 600, 'BackgroundColor', 'white');

% The numbers behind the figures: one row per time point, one column per channel
pop_export(EEG_pos1, 'erp_pos1.txt', 'erp', 'on', 'transpose', 'on', 'elec', 'on', 'time', 'on', 'precision', 4);
pop_export(EEG_pos2, 'erp_pos2.txt', 'erp', 'on', 'transpose', 'on', 'elec', 'on', 'time', 'on', 'precision', 4);
