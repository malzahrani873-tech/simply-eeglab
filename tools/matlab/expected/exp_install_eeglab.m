function e = exp_install_eeglab()
% Expected results for lesson install-eeglab (01-01).
% The lesson script changes the saved MATLAB path, so it is run by hand (run_checklist.md);
% here only the resulting installation is checked.

e.run = {};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected        tol
    'EEGLAB version',            'eeg_getversion',                                  @(v) startsWith(v, '2026.1'), 0
    'one eeg_checkset on path',  'numel(which(''-all'', ''eeg_checkset''))',        1,              0
    'Biosig installed (sopen)',  'exist(''sopen'', ''file'')',                      2,              0
    'firfilt present',           'exist(''pop_eegfiltnew'', ''file'')',             2,              0
    'ICLabel version',           'char(regexp(fileread(which(''eegplugin_iclabel'')), ''ICLabel(\d+\.\d+)'', ''tokens'', ''once''))', '1.7', 0
    'MATLAB release',            'version(''-release'')',                           [],             0
    };
e.log = cell(0, 2);
e.scripts = {};
end
