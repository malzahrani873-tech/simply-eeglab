function e = exp_run_ica()
% Expected results for lesson run-ica (04-03), D1 main dataset as in the lesson Starting point:
% high-pass 0.1, notch 58-62 Hz, average reference without EOG1/EOG2, ICA on a 1 Hz copy.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected        tol
    'channels',                  'EEG.nbchan',                                      32,             0
    'mixing matrix size',        'size(EEG.icawinv)',                               [32 31],        0
    'weights copied',            'isequal(EEG.icaweights, EEG_ica.icaweights)',     true,           0
    'ICA copy name',             'EEG_ica.setname',                                 'D1 ica1hz',    0
    'saved D1_main_ica.set',     'exist(fullfile(pwd, ''D1_main_ica.set''), ''file'')', 2,          0
    };
e.log = {
    'notch 58-62: 213 points',   'performing 213 point bandstop filtering'
    'high-pass 1: 425 points',   'performing 425 point highpass filtering'
    'rank 31 of 32 detected',    'Data rank \(31\) is smaller than the number of channels \(32\)'
    };
e.scripts = {'fig_run_ica', 'check_ica_repeat'};
end
