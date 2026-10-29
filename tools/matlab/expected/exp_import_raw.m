function e = exp_import_raw()
% Expected results for lesson import-raw (02-01), dataset D2: PhysioNet EEGMMIDB S001R03.edf.
% Source: the lesson section "How to check that the step worked".

e.run = {'start', 2};             % block 1 is a BDF/BrainVision example without data files
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected        tol
    'channels',                  'EEG.nbchan',                                      64,             0
    'sampling rate (Hz)',        'EEG.srate',                                       160,            0
    'duration (s)',              'EEG.pnts / EEG.srate',                            125,            1
    'event types',               'unique({EEG.event.type})',                        {'T0', 'T1', 'T2'}, 0
    'event types are text',      'all(cellfun(@ischar, {EEG.event.type}))',         true,           0
    'number of events',          'numel(EEG.event)',                                @(n) n > 0,     0
    'events per type',           'cellfun(@(t) sum(strcmp({EEG.event.type}, t)), {''T0'' ''T1'' ''T2''})', [], 0
    'no channel coordinates',    'all(cellfun(@isempty, {EEG.chanlocs.X}))',        true,           0
    'first five labels',         '{EEG.chanlocs(1:5).labels}',                      [],             0
    'labels ending with a dot',  'sum(endsWith({EEG.chanlocs.labels}, ''.''))',     [],             0
    'dataset name',              'EEG.setname',                                     'S001R03',      0
    'saved .set file',           'exist(fullfile(dataFolder, ''S001R03.set''), ''file'')', 2,        0
    };
e.log = cell(0, 2);
e.scripts = {'fig_import_raw'};
end
