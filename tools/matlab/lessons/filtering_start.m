% Copied from lessons/en/03-02-filtering.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
eeglabRoot = fileparts(which('eeglab'));
EEG = pop_loadset('eeglab_data.set', fullfile(eeglabRoot, 'sample_data'));
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'Continuous EEG Data', 'gui', 'off');
eeglab redraw;
