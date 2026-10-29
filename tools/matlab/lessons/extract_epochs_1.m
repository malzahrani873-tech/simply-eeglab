% Copied from lessons/en/05-01-extract-epochs.md. The lesson is the reference.
% Cut 3-s epochs around every 'square' event: 1 s before to 2 s after
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'newname', 'D1 epochs', 'epochinfo', 'yes');
EEG = eeg_checkset(EEG);

% Channels x time points x epochs
disp(size(EEG.data));
fprintf('Epochs: %d, from %.3f s to %.3f s\n', EEG.trials, EEG.xmin, EEG.xmax);
