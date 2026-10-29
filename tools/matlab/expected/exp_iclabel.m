function e = exp_iclabel()
% Expected results for lesson iclabel (04-05): label, flag Muscle/Eye above 0.9, remove, low-pass 30.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected        tol
    'ICLabel classes',           'numel(classes)',                                  7,              0
    'components labelled',       'size(probs, 1)',                                  31,             0
    'blink component (index)',   'find(probs(:, 3) == max(probs(:, 3)), 1)',        [],             0
    'blink Eye probability',     'max(probs(:, 3))',                                @(p) p > 0.9,   0
    'flagged components',        'artifactComps(:)''',                              @(c) ~isempty(c), 0
    'components left',           'size(EEG.icawinv, 2) + numel(artifactComps)',     31,             0
    'final dataset name',        'EEG.setname',                                     'D1 main clean lp30', 0
    'saved D1_main_clean_lp30',  'exist(fullfile(pwd, ''D1_main_clean_lp30.set''), ''file'')', 2,  0
    };
e.log = {
    'low-pass 30 after removal', 'performing 59 point lowpass filtering'
    };
e.scripts = {'fig_iclabel'};
end
