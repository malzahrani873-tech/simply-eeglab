function e = exp_study_design()
% Expected results for lesson study-design (08-04), ready Go-nogo STUDY (D6).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'designs',                       'numel(STUDY.design)',                            3,                       0
    'design 2 name',                 'STUDY.design(2).name',                           'image x gender',        0
    'current design',                'STUDY.currentdesign',                            2,                       0
    'condition paired',              'STUDY.design(2).variable(1).pairing',            'on',                    0
    'group not paired',              'STUDY.design(2).variable(2).pairing',            'off',                   0
    };
e.log = {
    'current design printed',        'Current design: 2'
    };
e.scripts = {};
end
