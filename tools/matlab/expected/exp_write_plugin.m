function e = exp_write_plugin()
% Expected results for lesson write-plugin (10-04), D1. The lesson has the learner save blocks 2 and 3
% as pop_chanvar.m and eegplugin_chanvar.m in plugins/chanvar1.0 (block 1 creates the folder), then
% run block 4. The extra step answers review_batch8-st9-10.md y-6: a threshold so high that no channel
% is flagged must still plot without an error. The plugin folder stays installed, as for a learner.

e.run = {'start', 1, {'file', 2, 'pop_chanvar.m'}, {'file', 3, 'eegplugin_chanvar.m'}, 4, ...
    'com10 = pop_chanvar(EEG, 10);'};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected                    tol
    'plugin function found',     'exist(''pop_chanvar'', ''file'')',                2,                          0
    'history command',           'com',                                             'pop_chanvar(EEG, 3);',     0
    'no channel flagged (y-6)',  'com10',                                           'pop_chanvar(EEG, 10);',    0
    };
e.log = {};
e.scripts = {};
end
