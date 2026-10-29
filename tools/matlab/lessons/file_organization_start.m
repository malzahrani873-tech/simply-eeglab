% Copied from lessons/en/09-05-file-organization.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Run from inside faces_project, where ds002718 sits in rawdata
bidsRoot = fullfile(pwd, 'rawdata');
EEG = pop_loadset('sub-002_task-FaceRecognition_eeg.set', fullfile(bidsRoot, 'sub-002', 'eeg'));

% Show the dataset in the main EEGLAB window
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'sub-002 raw', 'gui', 'off');
eeglab redraw;
