function e = exp_interpolation()
% Expected results for lesson interpolation (03-06), D1: the C3 exercise.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'channels after interpolation',  'EEG.nbchan',                                     32,                      0
    'C3 removed in the copy',        'EEG_drop.nbchan',                                31,                      0
    'C3 back',                       'EEG_back.nbchan',                                32,                      0
    'correlation original vs back',  'r(1, 2)',                                        [],                      0
    'correlation above 0.8',         'r(1, 2) > 0.8',                                  true,                    0
    'saved D1_interp.set',           'exist(fullfile(pwd, ''D1_interp.set''), ''file'')', 2,                      0
    };
e.log = {
    'correlation printed',           'Correlation between original and interpolated C3: \d\.\d\d'
    };
e.scripts = {'fig_interpolation'};
end
