% Copied from lessons/en/03-03-line-noise.md. The lesson is the reference.
% Line frequency: 60 Hz in Saudi Arabia and the Americas, 50 Hz in Europe
lineFreq = 60;

% Spectrum before, with scalp maps at 10 Hz and at the line frequency
figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange', [1 64], 'freq', [10 lineFreq]);

% Notch: remove a narrow band around the line frequency (revfilt = 1)
EEG = pop_eegfiltnew(EEG, 'locutoff', lineFreq - 2, 'hicutoff', lineFreq + 2, 'revfilt', 1);
EEG.setname = 'D1 hp0.1 notch60';

% Spectrum after
figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange', [1 64], 'freq', [10 lineFreq]);

EEG = pop_saveset(EEG, 'filename', 'D1_hp0.1_notch60.set', 'filepath', pwd);
