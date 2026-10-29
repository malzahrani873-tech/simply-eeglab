function e = exp_ica_1hz_copy_weights()
% Expected results for lesson ica-1hz-copy-weights (04-04), D1. The starting point runs ICA
% (3 to 5 minutes).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'same weights',                  'isequal(EEG.icaweights, EEG_ica.icaweights)',     true,                    0
    'components',                    'size(EEG.icawinv, 2)',                           31,                      0
    'largest map difference',        'max(abs(EEG.icawinv(:) - EEG_ica.icawinv(:)))',  0,                       1e-6
    'P3 lower in the 1 Hz copy',     'mean(erpIca(win)) < mean(erpMain(win))',         true,                    0
    'mean at Pz 300-600, 0.1 Hz',    'mean(erpMain(win))',                             [],                      0
    'mean at Pz 300-600, 1 Hz',      'mean(erpIca(win))',                              [],                      0
    'saved D1_main_ica.set',         'exist(fullfile(pwd, ''D1_main_ica.set''), ''file'')', 2,                     0
    };
e.log = {
    'means printed',                 'Mean at Pz, 300-600 ms: 0\.1 Hz copy -?\d+\.\d\d uV, 1 Hz copy -?\d+\.\d\d uV'
    };
e.scripts = {'fig_ica_1hz_copy_weights'};
end
