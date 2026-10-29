% Copied from lessons/en/02-04-bids-openneuro.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% Folder for the BIDS dataset (change it)
bidsFolder = 'C:\Users\me\Documents\eeg-course\ds002718';
baseUrl = 'https://s3.amazonaws.com/openneuro.org/ds002718/';
files = {'dataset_description.json', 'README', 'task-FaceRecognition_events.json', ...
    'sub-002/eeg/sub-002_task-FaceRecognition_eeg.set', ...
    'sub-002/eeg/sub-002_task-FaceRecognition_eeg.json', ...
    'sub-002/eeg/sub-002_task-FaceRecognition_channels.tsv', ...
    'sub-002/eeg/sub-002_task-FaceRecognition_electrodes.tsv', ...
    'sub-002/eeg/sub-002_task-FaceRecognition_events.tsv'};
for iFile = 1:numel(files)
    target = fullfile(bidsFolder, files{iFile});
    if ~exist(fileparts(target), 'dir'), mkdir(fileparts(target)); end
    websave(target, [baseUrl files{iFile}]);
end
