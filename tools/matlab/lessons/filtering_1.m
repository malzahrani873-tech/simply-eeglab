% Copied from lessons/en/03-02-filtering.md. The lesson is the reference.
% High-pass: passband edge at 0.1 Hz (removes slow drift)
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
EEG.setname = 'D1 hp0.1';
EEG = eeg_checkset(EEG);
EEG = pop_saveset(EEG, 'filename', 'D1_hp0.1.set', 'filepath', pwd);

% Exercise only: low-pass with passband edge at 30 Hz (removes fast noise)
EEG_lp = pop_eegfiltnew(EEG, 'hicutoff', 30);
EEG_lp.setname = 'D1 hp0.1 lp30';
