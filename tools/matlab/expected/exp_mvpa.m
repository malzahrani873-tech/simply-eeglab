function e = exp_mvpa()
% Expected results for lesson mvpa (10-03): ERP CORE N170 participant 2, faces vs cars (D3, CC BY-SA 4.0).
% Needs ERPLAB (extension manager) and the ERP CORE N170 "intermediate-stage processed files" for
% participant 2 in <datadir>/ERP_CORE/N170/2/. Decoding results vary slightly between runs (random
% cross-validation folds), so the checks use ranges taken from the lesson's "How to check it worked".

cfg = sea_config();
e.run = {'start', 1};
e.paths = {'fullfile(pwd, ''N170''', sprintf('fullfile(''%s'', ''N170''', fullfile(cfg.datadir, 'ERP_CORE'))};
e.checks = {
    % label                          expression                                                  expected  tol
    'ERPLAB installed',              'exist(''pop_decoding'', ''file'')',                         2,        0
    'two bins',                      'numel(EEG.EVENTLIST.trialsperbin)',                         2,        0
    'trials per bin',                'EEG.EVENTLIST.trialsperbin',                                [],       0
    'trials per bin at most 80',     'all(EEG.EVENTLIST.trialsperbin <= 80)',                     true,     0
    'epoch window (ms)',             '[EEG.xmin EEG.xmax] * 1000',                                [-200 800], 4
    'scalp channels decoded',        'numel(chans)',                                              28,       0
    'chance level',                  'MVPC.chance',                                               0.5,      0
    'decoding unit',                 'strcmpi(MVPC.DecodingUnit, ''proportion correct'')',        true,     0
    'mean accuracy before zero',     'mean(MVPC.average_score(MVPC.times < 0))',                  0.5,      0.08
    'peak accuracy',                 'peakAcc',                                                   [],       0
    'peak clearly above chance',     'peakAcc > 0.6',                                             true,     0
    'peak latency 130-250 ms',       'postTimes(iPeak)',                                          @(v) v >= 130 && v <= 250, 0
    'saved N170_sub2_faces_cars.mvpc', 'exist(fullfile(pwd, ''N170_sub2_faces_cars.mvpc''), ''file'')', 2, 0
    };
e.log = {
    'trials per bin printed',        'Trials per bin:\s+\d+\s+\d+'
    'peak line printed',             'Peak accuracy \d\.\d\d at \d+ ms \(chance 0\.50\)'
    };
e.scripts = {'fig_mvpa'};   % its Plot MVPC Results window is closed after the run; run_checklist 4a reopens it
end
