% Copied from lessons/en/07-02-channel-erp-plot.md. The lesson is the reference.
EEG = pop_loadset('D1_epochs_clean.set', pwd);

% All channels at their scalp positions, positive up
figure; pop_plottopo(EEG, 1:EEG.nbchan, 'D1 epochs clean', 0, 'ydir', 1);

% Stimulus position of the time-locking 'square' event in each epoch
pos = eeg_getepochevent(EEG, 'type', {'square'}, 'timewin', [-5 5], 'fieldname', 'position');
fprintf('Position 1: %d epochs, position 2: %d epochs\n', sum(pos == 1), sum(pos == 2));

% One dataset per condition, for later use
EEG_pos1 = pop_select(EEG, 'trial', find(pos == 1));
EEG_pos2 = pop_select(EEG, 'trial', find(pos == 2));
EEG_pos1.setname = 'D1 epochs clean pos1';
EEG_pos2.setname = 'D1 epochs clean pos2';

% Both conditions on one axis at Pz
chan = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
erp1 = mean(EEG_pos1.data(chan, :, :), 3);
erp2 = mean(EEG_pos2.data(chan, :, :), 3);

figure; hold on;
plot(EEG.times, erp1, 'LineWidth', 1.5);
plot(EEG.times, erp2, 'LineWidth', 1.5);
xline(0, 'k:');
yline(0, 'k-');
xlim([-200 800]);
set(gca, 'YDir', 'normal');   % positive up
xlabel('Time (ms)');
ylabel('Potential (\muV)');
legend({sprintf('Position 1 (n = %d)', EEG_pos1.trials), ...
        sprintf('Position 2 (n = %d)', EEG_pos2.trials)}, 'Location', 'best');
title('Pz');
