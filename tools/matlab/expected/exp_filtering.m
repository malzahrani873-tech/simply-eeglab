function e = exp_filtering()
% Expected results for lesson filtering (03-02), dataset D1: eeglab_data.set.
% Filter sizes follow pop_eegfiltnew.m (firfilt ff8227f) at 128 Hz.

% The extra step reloads the untouched sample file for the quiz questions on the main window (s01-q02,
% s01-q03, s01-q05).
e.run = {'start', 1, ['D1raw = pop_loadset(''filename'', ''eeglab_data.set'', ''filepath'', ' ...
    'fullfile(fileparts(which(''eeglab'')), ''sample_data''));']};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected        tol
    'channels',                  'EEG.nbchan',                                      32,             0
    'sampling rate (Hz)',        'EEG.srate',                                       128,            0
    'duration (s)',              'EEG.pnts / EEG.srate',                            238.3,          0.1
    'main dataset name',         'EEG.setname',                                     'D1 hp0.1',     0
    'exercise dataset name',     'EEG_lp.setname',                                  'D1 hp0.1 lp30', 0
    'saved D1_hp0.1.set',        'exist(fullfile(pwd, ''D1_hp0.1.set''), ''file'')', 2,             0
    '60 Hz peak after HP (dB)',  'sea_db(EEG, 60) - mean(sea_db(EEG, [56 57 63 64]))', @(d) d > 6, 0
    '60 Hz drop by LP30 (dB)',   'sea_db(EEG_lp, 60) - sea_db(EEG, 60)',            @(d) d < -20,   0
    'alpha kept by LP30 (dB)',   'sea_db(EEG_lp, 10) - sea_db(EEG, 10)',            0,              1
    'quiz: size(EEG.data)',      'size(D1raw.data)',                                [32 30504],     0
    'quiz: epochs',              'D1raw.trials',                                    1,              0
    'quiz: events',              'numel(D1raw.event)',                              154,            0
    'quiz: epoch start, end (s)', '[D1raw.xmin D1raw.xmax]',                        [0 238.305],    0.001
    'quiz: duration (s)',        'D1raw.pnts / D1raw.srate',                        238.3,          0.1
    };
e.log = {
    'high-pass 0.1: 4225 points', 'performing 4225 point highpass filtering'
    'high-pass 0.1: cutoff 0.05', 'cutoff frequency\(ies\) \(-6 dB\): 0\.05 Hz'
    'low-pass 30: 59 points',     'performing 59 point lowpass filtering'
    'low-pass 30: cutoff 33.64',  'cutoff frequency\(ies\) \(-6 dB\): 33\.64\d* Hz'
    };
e.scripts = {'fig_filtering', 'check_filter_reference'};
end
