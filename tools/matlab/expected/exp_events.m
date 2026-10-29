function e = exp_events()
% Expected results for lesson events (02-03), D2 (S001R03.set). Values from notes_stations_1-2.md
% (t-17 to t-19) and review_batch7-st1-2b.md (t-20: no urevent field).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected                      tol
    'events',                    'numel(EEG.event)',                                30,                           0
    'T0 count',                  'sum(strcmp({EEG.event.type}, ''T0''))',           15,                           0
    'T1 count',                  'sum(strcmp({EEG.event.type}, ''T1''))',           8,                            0
    'T2 count',                  'sum(strcmp({EEG.event.type}, ''T2''))',           7,                            0
    'first four types',          '{EEG.event(1:4).type}',                           {'T0', 'T2', 'T0', 'T1'},     0
    'first four latencies',      '[EEG.event(1:4).latency]',                        [1 673 1329 2001],            0
    'latencies in seconds',      '([EEG.event(1:4).latency] - 1) / EEG.srate',      [0 4.2 8.3 12.5],             0.01
    'durations in seconds',      '[EEG.event(1:2).duration] / EEG.srate',           [4.2 4.1],                    0.01
    'no urevent field',          '~isfield(EEG.event, ''urevent'')',                true,                         0
    'event fields',              'fieldnames(EEG.event)''',                         [],                           0
    };
e.log = {};
e.scripts = {};
end
