function e = exp_bad_channels()
% Expected results for lesson bad-channels (03-04), D1. D1 is expected to have no bad channel; the
% lesson image comes from D3 (fig_bad_channels.m, ERP CORE N400).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'channels flagged in D1',        'badChans',                                       [],                      0
    'channels left',                 'EEG.nbchan',                                     [],                      0
    'dataset name',                  'EEG.setname',                                    'D1 badch',              0
    'saved D1_badch.set',            'exist(fullfile(pwd, ''D1_badch.set''), ''file'')', 2,                       0
    };
e.log = {
    'bad channel line printed',      'Bad channels: '
    };
e.scripts = {'fig_bad_channels'};
end
