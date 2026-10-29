function e = exp_line_noise()
% Expected results for lesson line-noise (03-03), D1: band-stop 58-62 Hz after the 0.1 Hz high-pass.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'dataset name',                  'EEG.setname',                                    'D1 hp0.1 notch60',      0
    'channels',                      'EEG.nbchan',                                     32,                      0
    '60 Hz peak gone (dB)',          'sea_db(EEG, 60) - mean(sea_db(EEG, [56 57 63 64])) < 0', true,            0
    'saved D1_hp0.1_notch60.set',    'exist(fullfile(pwd, ''D1_hp0.1_notch60.set''), ''file'')', 2,              0
    };
e.log = {
    'band-stop order printed',       '\d+ point bandstop'
    };
e.scripts = {'fig_line_noise'};
end
