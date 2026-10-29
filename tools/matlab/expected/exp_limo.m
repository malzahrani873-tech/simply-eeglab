function e = exp_limo()
% Expected results for lesson limo (08-10), ready Go-nogo STUDY (D6). Needs the LIMO and
% Fieldtrip-lite plugins (run_checklist 0.4). Any dialog LIMO opens would stop an unattended run;
% the lesson script passes every option so none is expected (8.10-3, 8.10-4).

e.run = {'start', 1, ['pluginDir = dir(fullfile(fileparts(which(''eeglab'')), ''plugins'')); ' ...
    'limoFolders = strjoin({pluginDir(contains(lower({pluginDir.name}), ''limo'')).name}, '' '');']};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'beta file list written',        'exist(betaFile, ''file'')',                      2,                       0
    'participants at level 1',       'nnz(~cellfun(@isempty, betaList))',              14,                      0
    'paired t-test result',          'exist(fullfile(resDir, ''Paired_Samples_Ttest_parameter_1_2.mat''), ''file'')', 2, 0
    'significant points (8.10-6)',   'nnz(mask)',                                      [],                      0
    'LIMO plugin folder (y-15)',     'limoFolders',                                    [],                      0
    'back in the start folder (y-16)', 'strcmp(pwd, startDir)',                       true,                    0
    };
e.log = {
    'level 1 printed (8.10-3)',      '1st level done: \d+ participants listed in'
    'clusters printed (8.10-6)',     'Significant channel x time points after cluster correction: \d+'
    };
e.scripts = {};
end
