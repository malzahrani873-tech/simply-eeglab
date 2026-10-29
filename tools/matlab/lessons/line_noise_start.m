% Copied from lessons/en/03-03-line-noise.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
eeglabRoot = fileparts(which('eeglab'));
EEG = pop_loadset('eeglab_data.set', fullfile(eeglabRoot, 'sample_data'));

% Main dataset: high-pass at 0.1 Hz
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
EEG.filename = ''; EEG.filepath = ''; EEG.datfile = ''; EEG.saved = 'no';
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'D1 hp0.1', 'gui', 'off');
eeglab redraw;
