function e = exp_sift()
% Expected results for lesson sift (10-02). Needs SIFT (plugin batch). The Time-Frequency Grid screenshot is a manual step after fig_sift.
% A FAIL on the ratio is a warning for the lesson text, not a run error. Values from the lesson script. The figure script writes the facts for the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'components modelled',           'numel(comps)',                                   4,                       0
    'parameter ratio below 0.1',     'ratio < 0.1',                                    true,                    0
    };
e.log = cell(0, 2);
e.scripts = {'fig_sift'};
end
