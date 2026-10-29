function e = exp_study_from_bids()
% Expected results for lesson study-from-bids (08-03): ds002680 subset, sub-002 and sub-005,
% session 1 run 1 (d6_facts.m raw values).

ref = d6_facts();
% The starting point only downloads (no STUDY yet), so CURRENTSTUDY is checked after the lesson block.
e.run = {'start', ...
    ['bidsAll = dir(fullfile(bidsFolder, ''**'', ''*'')); nDownloaded = sum(~[bidsAll.isdir]); ' ...
     'd1 = dir(fullfile(bidsFolder, ''sub-002'', ''ses-01'', ''eeg'', ''*_eeg.set'')); ' ...
     'd2 = dir(fullfile(bidsFolder, ''sub-005'', ''ses-01'', ''eeg'', ''*_eeg.set'')); ' ...
     'bidsSetBytes = [d1.bytes d2.bytes]; ' ...
     'r = dir(fullfile(bidsFolder, ''README*'')); readmeNames = {r.name};'], ...
    1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'files downloaded (y-5)',        'nDownloaded',                                    18,                      0
    '.set sizes in bytes (y-5)',     'bidsSetBytes',                                   [27111528 28284024],     0
    'README name on disk (y-6)',     'readmeNames',                                    [],                      0
    'CURRENTSTUDY',                  'CURRENTSTUDY',                                   1,                       0
    'all datasets selected',         'numel(CURRENTSET) == numel(ALLEEG)',              true,                    0
    'datasets',                      'numel(ALLEEG)',                                  2,                       0
    'subjects',                      '{STUDY.datasetinfo.subject}',                    {'sub-002', 'sub-005'},  0
    'sampling rate (Hz)',            'unique([ALLEEG.srate])',                         ref.raw.srate,           0
    'channels',                      'unique([ALLEEG.nbchan])',                        ref.raw.nbchan,          0
    'run 1 length sub-002 (s)',      'ALLEEG(1).xmax',                                 ref.raw.run1_seconds,    0.01
    'STUDY name',                    'STUDY.name',                                     'gonogo_bids',           0
    'design 1 name',                 'STUDY.design(1).name',                           [],                      0
    'gender from participants.tsv',  '{STUDY.datasetinfo.gender}',                     [],                      0
    };
e.log = {
    'STUDY file printed',            'STUDY file: '
    };
e.scripts = {};
end
