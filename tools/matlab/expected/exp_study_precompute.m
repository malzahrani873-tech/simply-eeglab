function e = exp_study_precompute()
% Expected results for lesson study-precompute (08-05), ready Go-nogo STUDY (D6).
% Final state of the lesson: design 2 "image x gender" selected, measures precomputed and saved.
% std_ersp saves one .dattimef file per participant; ERSP and ITC are computed from it at plot time
% (std_ersp.m 361, review_batch10-st8a.md m-1), so no .datersp or .datitc file is expected.

ref = d6_facts();
e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'CURRENTSTUDY',                  'CURRENTSTUDY',                                   1,                       0
    'all datasets selected',         'numel(CURRENTSET) == numel(ALLEEG)',              true,                    0
    'datasets in STUDY',             'numel(STUDY.datasetinfo)',                       ref.ready.nfiles,        0
    'current design',                'STUDY.currentdesign',                            2,                       0
    'design 2 name',                 'STUDY.design(2).name',                           'image x gender',        0
    'channel groups',                'numel(STUDY.changrp)',                           [],                      0
    'measure files, participant 1',  'numel(measureFiles)',                            [],                      0
    'ERP file written',              'any(endsWith({measureFiles.name}, ''.daterp''))', true,                    0
    'spectrum file written',         'any(endsWith({measureFiles.name}, ''.datspec''))', true,                   0
    'time-frequency file written',   'any(endsWith({measureFiles.name}, ''.dattimef''))', true,                  0
    'no .datersp or .datitc file',   '~any(endsWith({measureFiles.name}, {''.datersp'', ''.datitc''}))', true,  0
    'measure file names',            '{measureFiles.name}',                            [],                      0
    'measure file sizes (MB)',       'round([measureFiles.bytes] / 1e6, 1)',           [],                      0
    'sizes MB daterp datspec dattimef', 'round([measureFiles(endsWith({measureFiles.name}, ''.daterp'')).bytes, measureFiles(endsWith({measureFiles.name}, ''.datspec'')).bytes, measureFiles(endsWith({measureFiles.name}, ''.dattimef'')).bytes] / 1e6, 1)', [], 0
    'ERSP channels',                 'erspChans',                                      [],                      0
    };
e.log = {
    'channel groups printed',        'Channel groups in the STUDY: \d+'
    };
e.scripts = {};
end
