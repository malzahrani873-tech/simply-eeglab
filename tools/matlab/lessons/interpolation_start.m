% Copied from lessons/en/03-06-interpolation.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
eeglabRoot = fileparts(which('eeglab'));
EEG = pop_loadset('eeglab_data.set', fullfile(eeglabRoot, 'sample_data'));
fullLocs = EEG.chanlocs;

% Main dataset: high-pass at 0.1 Hz, then 60 Hz line-noise removal
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
EEG = pop_eegfiltnew(EEG, 'locutoff', 58, 'hicutoff', 62, 'revfilt', 1);
EEG.filename = ''; EEG.filepath = ''; EEG.datfile = ''; EEG.saved = 'no';
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'D1 hp0.1 notch60', 'gui', 'off');

% Bad channels you removed earlier, e.g. {'T7'}; leave empty if none
badChans = {};
if ~isempty(badChans)
    EEG = pop_select(EEG, 'rmchannel', badChans);
end
EEG.filename = ''; EEG.filepath = ''; EEG.datfile = ''; EEG.saved = 'no';
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', 'D1 badch', 'gui', 'off');
eeglab redraw;
