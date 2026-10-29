function e = exp_ersp_itc()
% Expected results for lesson ersp-itc (06-04), D1 epochs clean, channel Cz. Values from
% notes_stations_5-6.md and review_batch6-st6.md (E-1).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                         expected        tol
    'first frequency (Hz)',      'freqs(1)',                        3,              0.5
    'last frequency (Hz)',       'freqs(end)',                      30,             1
    'first time (ms)',           'times(1)',                        -500,           150
    'last time (ms)',            'times(end)',                      1500,           150
    'time points',               'size(ersp, 2)',                   200,            0
    'ERSP size',                 'size(ersp)',                      [],             0
    'max ITC',                   'maxItc',                          [],             0
    'max ITC frequency (Hz)',    'freqs(fi)',                       [],             0
    'max ITC time (ms)',         'times(ti)',                       [],             0
    };
e.log = {
    'cycles line',               'Using 3 cycles at lowest frequency to 6 at highest'
    };
e.scripts = {'fig_ersp_itc'};
end
