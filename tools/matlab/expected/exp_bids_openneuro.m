function e = exp_bids_openneuro()
% Expected results for lesson bids-openneuro (02-04), ds002718 sub-002 downloaded by the Starting point.
% Values from notes_stations_1-2.md (t-29, t-30) and review_batch7-st1-2b.md (t-33). The extra step
% lists the downloaded files (README must keep no extension, t-4).

e.run = {'start', 1, [ ...
    'bidsList = dir(bidsFolder); bidsTop = setdiff({bidsList.name}, {''.'', ''..''}); ' ...
    'eegList = dir(fullfile(bidsFolder, ''sub-002'', ''eeg'')); nEegFiles = sum(~[eegList.isdir]);']};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                                   expected     tol
    'README without extension',  'exist(fullfile(bidsFolder, ''README''), ''file'')',         2,           0
    'top-level files',           'bidsTop',                                                    [],          0
    'description file',          'exist(fullfile(bidsFolder, ''dataset_description.json''), ''file'')', 2, 0
    'events sidecar',            'exist(fullfile(bidsFolder, ''task-FaceRecognition_events.json''), ''file'')', 2, 0
    'sub-002/eeg files',         'nEegFiles', 5, 0
    'study name',                'STUDY.name',                                                'ds002718',  0
    'channels',                  'EEG(1).nbchan',                                             74,          0
    'sampling rate',             'EEG(1).srate',                                              250,         0
    'points',                    'EEG(1).pnts',                                               747750,      0
    'events',                    'numel(EEG(1).event)',                                       1479,        0
    'event types',               'eeg_eventtypes(EEG(1))''',                                  [],          0
    'located channels',          'sum(~cellfun(@isempty, {EEG(1).chanlocs.X}))',              [],          0
    'setname',                   'EEG(1).setname',                                            [],          0
    };
e.log = {};
e.scripts = {};
end
