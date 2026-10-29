% Copied from lessons/en/01-02-eeglab-gui.md. The lesson is the reference.
% Start EEGLAB and get its main variables
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Load the sample dataset that ships with EEGLAB
sampleFolder = fullfile(fileparts(which('eeglab')), 'sample_data');
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', sampleFolder);

% Register it in EEGLAB and refresh the main window
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
eeglab redraw;

% Scroll through the channel data
pop_eegplot(EEG, 1, 1, 1);
