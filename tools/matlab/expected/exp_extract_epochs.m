function e = exp_extract_epochs()
% Expected results for lesson extract-epochs (05-01), D1 main dataset after the lesson Starting point
% (through the 30 Hz low-pass). Values from notes_stations_5-6.md and review_batch4-st5.md.
% The two extra steps keep a continuous copy and epoch it with an empty event type, to check the
% "Common mistakes" number (153 epochs from 154 events; the last rt epoch runs past the end).

e.run = {'start', 'EEG_cont = EEG;', 1, 'EEG_all = pop_epoch(EEG_cont, {}, [-1 2]);'};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                         expected        tol
    'data size',                 'size(EEG.data)',                  [32 384 80],    0
    'epochs',                    'EEG.trials',                      80,             0
    'xmin',                      'EEG.xmin',                        -1,             0
    'xmax',                      'EEG.xmax',                        1.9922,         1e-3
    'events after epoching',     'length(EEG.event)',               157,            0
    'setname',                   'EEG.setname',                     'D1 epochs',    0
    'first epoch latency 0',     'any(cell2mat(EEG.epoch(1).eventlatency) == 0)', true, 0
    'empty type: epochs',        'EEG_all.trials',                  153,            0
    'empty type: events in',     'length(EEG_cont.event)',          154,            0
    };
e.log = {
    '80 epochs generated',       '80 epochs generated'
    'baseline warning',          'Do you also want to remove the single-trial ERP baseline'
    'empty type: 153 epochs',    '153 epochs generated'
    'empty type: boundary',      'event 154 out of data boundary'
    };
e.scripts = {};
end
