% Copied from lessons/en/02-01-import-raw.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% Folder where you keep the course data (change it)
dataFolder = 'C:\Users\me\Documents\eeg-course';
if ~exist(dataFolder, 'dir'), mkdir(dataFolder); end
websave(fullfile(dataFolder, 'S001R03.edf'), ...
    'https://physionet.org/files/eegmmidb/1.0.0/S001/S001R03.edf');
