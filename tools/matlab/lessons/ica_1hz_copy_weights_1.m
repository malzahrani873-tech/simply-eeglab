% Copied from lessons/en/04-04-ica-1hz-copy-weights.md. The lesson is the reference.
% EEG_main: main dataset (0.1 Hz); EEG_ica: ICA copy (1 Hz) with weights
% Copy the decomposition back to the main dataset
EEG_main.icaweights  = EEG_ica.icaweights;
EEG_main.icasphere   = EEG_ica.icasphere;
EEG_main.icachansind = EEG_ica.icachansind;
EEG_main.icawinv     = [];   % recomputed by eeg_checkset
EEG_main.icaact      = [];
EEG = eeg_checkset(EEG_main);

% Check: same weights and scalp maps in both copies
fprintf('Same weights: %d\n', isequal(EEG.icaweights, EEG_ica.icaweights));
fprintf('Largest scalp map difference: %g\n', max(abs(EEG.icawinv(:) - EEG_ica.icawinv(:))));
fprintf('ICA components: %d\n', size(EEG.icawinv, 2));

% Why two copies: ERP at Pz around 'square' events in each copy
epMain = pop_rmbase(pop_epoch(EEG, {'square'}, [-0.2 0.8]), [-200 0]);
epIca  = pop_rmbase(pop_epoch(EEG_ica, {'square'}, [-0.2 0.8]), [-200 0]);
pz  = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
win = epMain.times >= 300 & epMain.times <= 600;
erpMain = mean(epMain.data(pz, :, :), 3);
erpIca  = mean(epIca.data(pz, :, :), 3);
fprintf('Mean at Pz, 300-600 ms: 0.1 Hz copy %.2f uV, 1 Hz copy %.2f uV\n', ...
    mean(erpMain(win)), mean(erpIca(win)));
figure;
plot(epMain.times, erpMain, epIca.times, erpIca);
legend('Main dataset (0.1 Hz)', 'ICA copy (1 Hz)');
xlabel('Time (ms)'); ylabel('Amplitude (uV)');

EEG = pop_saveset(EEG, 'filename', 'D1_main_ica.set', 'filepath', pwd);
