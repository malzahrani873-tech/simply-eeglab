function e = exp_epoch_rejection()
% Expected results for lesson epoch-rejection (05-03), D1 epochs after baseline correction.
% Values from notes_stations_5-6.md. The extra steps keep the epochs before rejection and count
% the epochs marked at +-75 and +-50 uV, for comparison (simulation: about 11 and about 70).
% The last step serves quiz question s05-q05: D1 hp0.1 notch60 epochs before ICA, baseline -200 to 0,
% +-100 uV on all channels; it needs four consecutive epochs where only the third is rejected.

e.run = {'start', 'EEG_bl = EEG;', 1, [ ...
    'EEG75 = pop_eegthresh(EEG_bl, 1, 1:EEG_bl.nbchan, -75, 75, EEG_bl.xmin, EEG_bl.xmax, 0, 0); ' ...
    'n75 = sum(EEG75.reject.rejthresh); ' ...
    'EEG50 = pop_eegthresh(EEG_bl, 1, 1:EEG_bl.nbchan, -50, 50, EEG_bl.xmin, EEG_bl.xmax, 0, 0); ' ...
    'n50 = sum(EEG50.reject.rejthresh); clear EEG75 EEG50'], [ ...
    'qEEG = pop_loadset(''filename'', ''eeglab_data.set'', ''filepath'', fullfile(fileparts(which(''eeglab'')), ''sample_data'')); ' ...
    'qEEG = pop_eegfiltnew(qEEG, ''locutoff'', 0.1); ' ...
    'qEEG = pop_eegfiltnew(qEEG, ''locutoff'', 58, ''hicutoff'', 62, ''revfilt'', 1); ' ...
    'qEEG = pop_epoch(qEEG, {''square''}, [-1 2]); qEEG = pop_rmbase(qEEG, [-200 0]); ' ...
    'qEEG = pop_eegthresh(qEEG, 1, 1:qEEG.nbchan, -100, 100, qEEG.xmin, qEEG.xmax, 0, 0); ' ...
    'qRej = find(qEEG.reject.rejthresh); qMask = double(qEEG.reject.rejthresh(:)''); ' ...
    'qStart = strfind(qMask, [0 0 1 0]); clear qEEG qMask']};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected                tol
    'marked at +-100 (N)',       'numel(badEpochs)',                                @(n) n >= 0 && n <= 3,  0
    'marked epoch numbers',      'badEpochs',                                       [],                     0
    'epochs left = 80 - N',      'EEG.trials + numel(badEpochs)',                   80,                     0
    'largest value below 100',   'max(abs(EEG.data(:)))',                           @(v) v < 100,           0
    'setname',                   'EEG.setname',                                     'D1 epochs clean',      0
    'saved D1_epochs_clean.set', 'exist(fullfile(pwd, ''D1_epochs_clean.set''), ''file'')', 2,           0
    'marked at +-75',            'n75',                                             [],                     0
    'marked at +-50',            'n50',                                             [],                     0
    'quiz s05-q05: 4 epochs, only the 3rd over +-100', 'sprintf(''windows starting at %s | rejected epochs %s'', mat2str(qStart), mat2str(qRej))', @(s) isempty(strfind(s, 'at []')), 0
    };
e.log = {
    'N/80 trials marked',        '\d+/80 trials marked for rejection'
    };
e.scripts = {};
end
