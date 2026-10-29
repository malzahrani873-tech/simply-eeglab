% Copied from lessons/en/02-01-import-raw.md. The lesson is the reference.
% Start EEGLAB and get its main variables
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Folder where you saved S001R03.edf (change it)
dataFolder = 'C:\Users\me\Documents\eeg-course';

% Biosig is required for EDF/BDF files
if ~exist('sopen', 'file')
    plugin_askinstall('Biosig', 'sopen', true);
end

% Import the EDF+ file (all channels, events from annotations)
EEG = pop_biosig(fullfile(dataFolder, 'S001R03.edf'));

% Store it as a new dataset and save it as .set
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, ...
    'setname', 'S001R03', 'gui', 'off');
EEG = pop_saveset(EEG, 'filename', 'S001R03.set', 'filepath', dataFolder);
eeglab redraw;
