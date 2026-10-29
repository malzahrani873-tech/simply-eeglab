function e = exp_rereferencing()
% Expected results for lesson rereferencing (03-07), D1: average reference, EOG1 and EOG2 excluded.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'dataset name',                  'EEG.setname',                                    'D1 main',               0
    'reference',                     'EEG.ref',                                        [],                      0
    'scalp channels sum to zero',    'max(abs(sum(EEG.data(scalpIdx, :), 1))) < 1e-3', true,                    0
    'EOG1 unchanged',                'isequal(EEG.data(eogIdx(1), :), EEG_before.data(eogIdx(1), :))', true,    0
    'saved D1_main.set',             'exist(fullfile(pwd, ''D1_main.set''), ''file'')', 2,                         0
    };
e.log = {
    'sum line printed',              'Largest sum over scalp channels: '
    };
e.scripts = {'fig_rereferencing'};
end
