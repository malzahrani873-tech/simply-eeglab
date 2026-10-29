% Copied from lessons/en/04-07-amica-picard.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
eeglabRoot = fileparts(which('eeglab'));
EEG = pop_loadset('eeglab_data.set', fullfile(eeglabRoot, 'sample_data'));
fullLocs = EEG.chanlocs;

% Main dataset: high-pass at 0.1 Hz, then 60 Hz line-noise removal
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
EEG = pop_eegfiltnew(EEG, 'locutoff', 58, 'hicutoff', 62, 'revfilt', 1);

% Bad channels you removed earlier, e.g. {'T7'}; leave empty if none
badChans = {};
if ~isempty(badChans)
    EEG = pop_select(EEG, 'rmchannel', badChans);
    EEG = pop_interp(EEG, fullLocs, 'spherical');
end

% Average reference, EOG channels excluded
eogIdx = find(ismember({EEG.chanlocs.labels}, {'EOG1', 'EOG2'}));
EEG = pop_reref(EEG, [], 'exclude', eogIdx);
EEG.filename = ''; EEG.filepath = ''; EEG.datfile = ''; EEG.saved = 'no';
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'D1 main', 'gui', 'off');
eeglab redraw;
