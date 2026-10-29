% Copied from lessons/en/01-05-set-fdt-files.md. The lesson is the reference.
% Start EEGLAB and load the sample dataset
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
sampleFolder = fullfile(fileparts(which('eeglab')), 'sample_data');
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', sampleFolder);

% The sample keeps its signal in a separate file
EEG.datfile                                 % 'eeglab_data.fdt'
dir(fullfile(sampleFolder, 'eeglab_data.*'))   % the .fdt and the .set

% Save a copy in your own folder: one file by default
myFolder = 'C:\Users\me\Documents\eeg-course';   % change it
EEG = pop_saveset(EEG, 'filename', 'D1_copy.set', 'filepath', myFolder);
dir(fullfile(myFolder, 'D1_copy.*'))           % D1_copy.set only

% Ask for two files explicitly, if you ever need them
EEG = pop_saveset(EEG, 'filename', 'D1_twofiles.set', 'filepath', myFolder, ...
    'savemode', 'twofiles');
dir(fullfile(myFolder, 'D1_twofiles.*'))       % D1_twofiles.fdt and D1_twofiles.set
