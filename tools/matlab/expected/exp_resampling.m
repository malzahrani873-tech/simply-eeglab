function e = exp_resampling()
% Expected results for lesson resampling (03-01), D1: a temporary copy at 64 Hz.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'original rate',                 'EEG.srate',                                      128,                     0
    'copy rate',                     'EEG_64.srate',                                   64,                      0
    'copy samples',                  'EEG_64.pnts',                                    [],                      0
    'same number of events',         'numel(EEG_64.event) == numel(EEG.event)',         true,                    0
    'main dataset still 128 Hz',     'EEG.srate == 128',                               true,                    0
    };
e.log = {
    'comparison printed',            'Resampled: 64 Hz'
    };
e.scripts = {'fig_resampling'};
end
