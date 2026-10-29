function e = exp_alleeg_datasets()
% Expected results for lesson alleeg-datasets (01-04), D1. Values from notes_stations_1-2.md (t-25).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                         expected        tol
    'current set after retrieve', 'CURRENTSET',                     1,              0
    'channels after retrieve',   'EEG.nbchan',                      32,             0
    'dataset 1 channels',        'ALLEEG(1).nbchan',                32,             0
    'datasets in memory',        'numel(ALLEEG)',                   [],             0
    };
e.log = {
    'CURRENTSET = 2',            'CURRENTSET =\s+2'
    'channels 32 and 30',        '32\s+30'
    };
e.scripts = {};
end
