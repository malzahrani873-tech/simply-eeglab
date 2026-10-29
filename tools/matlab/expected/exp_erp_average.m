function e = exp_erp_average()
% Expected results for lesson erp-average (06-01), D1 epochs clean. Values from notes_stations_5-6.md;
% the peak range is the writer's estimate (review simulation without ICA: 11.8 uV at 430 ms).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                         expected                    tol
    'ERP size',                  'size(erp)',                       [32 384],                   0
    'averaged epochs',           'EEG.trials',                      [],                         0
    'Pz peak amplitude (uV)',    'peakAmp',                         @(v) v >= 9 && v <= 12,     0
    'Pz peak latency (ms)',      'winTimes(iPeak)',                 @(t) t >= 380 && t <= 470,  0
    };
e.log = {
    'Averaged N epochs',         'Averaged \d+ epochs'
    'Positive peak at Pz',       'Positive peak at Pz: '
    };
e.scripts = {'fig_erp_average'};
end
