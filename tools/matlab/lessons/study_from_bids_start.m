% Copied from lessons/en/08-03-study-from-bids.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% Folder for the BIDS subset (change it)
bidsFolder = 'C:\Users\me\Documents\eeg-course\ds002680';
baseUrl = 'https://s3.amazonaws.com/openneuro.org/ds002680/';

% Top-level files, then session 1 run 1 of two participants
files = {'dataset_description.json', 'README', 'participants.tsv', 'participants.json'};
parts = {'eeg.set', 'eeg.json', 'channels.tsv', 'electrodes.tsv', 'coordsystem.json', 'events.tsv', 'events.json'};
for subj = {'sub-002', 'sub-005'}
    for iPart = 1:numel(parts)
        files{end+1} = sprintf('%s/ses-01/eeg/%s_ses-01_task-gonogo_run-1_%s', subj{1}, subj{1}, parts{iPart});
    end
end
for iFile = 1:numel(files)
    target = fullfile(bidsFolder, files{iFile});
    if ~exist(target, 'file')
        if ~exist(fileparts(target), 'dir'), mkdir(fileparts(target)); end
        try
            websave(target, [baseUrl files{iFile}]);
        catch
            fprintf(2, 'Could not download %s\n', files{iFile});
        end
    end
end
fprintf('BIDS subset in %s\n', bidsFolder);
eeglab redraw;
