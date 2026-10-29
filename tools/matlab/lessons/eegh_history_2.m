% Copied from lessons/en/09-01-eegh-history.md. The lesson is the reference.
% Rebuilt from the EEGLAB session history (eegh)
eeglab nogui
eeglabRoot = fileparts(which('eeglab'));

% Load the sample dataset (portable path, works on any computer)
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fullfile(eeglabRoot, 'sample_data'));

% High-pass: passband edge at 0.1 Hz
[EEG, com] = pop_eegfiltnew(EEG, 'locutoff', 0.1);
EEG = eeg_hist(EEG, com);

% Line noise: notch between 58 and 62 Hz
[EEG, com] = pop_eegfiltnew(EEG, 'locutoff', 58, 'hicutoff', 62, 'revfilt', 1);
EEG = eeg_hist(EEG, com);
EEG.setname = 'D1 hp0.1 notch60';
EEG = eeg_checkset(EEG);

% Save the dataset history to a file, for your records
pop_saveh(EEG.history, 'D1_hp0.1_notch60_history.m', pwd);
