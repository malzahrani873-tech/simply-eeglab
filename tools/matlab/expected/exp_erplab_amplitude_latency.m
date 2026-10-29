function e = exp_erplab_amplitude_latency()
% Expected results for lesson erplab-amplitude-latency (06-03): ERPLAB, Luck chapter 10 ERPsets
% (folder Chapter_10 inside the course data folder). Values from notes_stations_5-6.md (Luck 10.6 and
% 10.7) and review_batch6-st6.md A-1: the Starting point runs twice, and ALLERP is counted each time.

cfg = sea_config();
e.run = {'start', 'nERP_first = numel(ALLERP);', 'start', 'nERP_second = numel(ALLERP);', 1};
e.paths = {'fullfile(pwd, ''Chapter_10''', sprintf('fullfile(''%s'', ''Chapter_10''', cfg.course_dir)};
e.checks = {
    % label                      expression                                         expected    tol
    'ERPLAB installed',          'exist(''pop_geterpvalues'', ''file'')',           2,          0
    'ERPsets, first run',        'nERP_first',                                      40,         0
    'ERPsets, second run (A-1)', 'nERP_second',                                     [],         0
    'channel C3/C4 found',       '~isempty(chan)',                                  true,       0
    'channel names',             '{ALLERP(1).chanlocs.labels}',                     [],         0
    'mean amp 150-400, compatible',   'mean(meanAmp(1, :))',                        [],         0
    'mean amp 150-400, incompatible', 'mean(meanAmp(2, :))',                        [],         0
    'negative peak, compatible', 'mean(peakAmp(:))',                                -3.23,      0.3
    'peak latency, compatible',  'mean(peakLat(1, :))',                             318,        20
    'peak latency, incompatible', 'mean(peakLat(2, :))',                            375,        20
    'pre-stimulus mean',         'mean(blMean(:))',                                 0,          0.5
    'pre-stimulus negative peak', 'mean(blPeak(:))',                                -0.89,      0.2
    'saved mean_amp_150_400.txt', 'exist(fullfile(pwd, ''mean_amp_150_400.txt''), ''file'')', 2, 0
    };
e.log = {};
e.scripts = {'fig_erplab_amplitude_latency'};
end
