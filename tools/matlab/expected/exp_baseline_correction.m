function e = exp_baseline_correction()
% Expected results for lesson baseline-correction (05-02), D1 epochs. Values from notes_stations_5-6.md.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                         expected        tol
    'baseline points',           'sum(blIdx)',                      26,             0
    'largest baseline mean',     'max(abs(blMeans(:)))',            @(v) v < 0.001, 0
    'epochs',                    'EEG.trials',                      80,             0
    'setname',                   'EEG.setname',                     'D1 epochs bl', 0
    };
e.log = {
    'baseline points printed',   'Baseline points: 26'
    };
e.scripts = {'fig_baseline_correction'};
end
