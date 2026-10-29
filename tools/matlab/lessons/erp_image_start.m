% Copied from lessons/en/07-03-erp-image.md. The lesson is the reference.
% Starting point
% Shortcut: if you saved D1_epochs_clean.set in the epoch rejection lesson, keep
% the first line and the last two lines (pop_newset, eeglab redraw), and replace
% every line between them with:
% EEG = pop_loadset('D1_epochs_clean.set', pwd);
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

% ICA on a 1-Hz copy, then copy the weights back
EEG_ica = pop_eegfiltnew(EEG, 'locutoff', 1);
EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1);
EEG.icaweights  = EEG_ica.icaweights;
EEG.icasphere   = EEG_ica.icasphere;
EEG.icachansind = EEG_ica.icachansind;
EEG.icawinv     = [];
EEG.icaact      = [];
EEG = eeg_checkset(EEG);

% Remove eye and muscle components, then low-pass at 30 Hz
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);
artifactComps = find(EEG.reject.gcompreject);
if ~isempty(artifactComps)
    EEG = pop_subcomp(EEG, artifactComps, 0);
end
EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);

% Epochs around 'square', baseline, and +/-100 uV rejection
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'newname', 'D1 epochs', 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);
EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -100, 100, EEG.xmin, EEG.xmax, 0, 0);
badEpochs = find(EEG.reject.rejthresh);
if ~isempty(badEpochs)
    EEG = pop_rejepoch(EEG, EEG.reject.rejthresh, 0);
end
EEG.setname = 'D1 epochs clean';
EEG = eeg_checkset(EEG);
EEG = pop_saveset(EEG, 'filename', 'D1_epochs_clean.set', 'filepath', pwd);
EEG.filename = ''; EEG.filepath = ''; EEG.datfile = ''; EEG.saved = 'no';
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'D1 epochs clean', 'gui', 'off');
eeglab redraw;
