% Copied from lessons/en/01-04-alleeg-datasets.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
sampleFolder = fullfile(fileparts(which('eeglab')), 'sample_data');
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', sampleFolder);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'Continuous EEG Data', 'gui', 'off');
eeglab redraw;
