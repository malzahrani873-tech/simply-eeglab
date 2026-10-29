% Copied from lessons/en/09-02-single-subject-script.md. The lesson is the reference.
%% D1 single-subject pipeline: raw data to clean epochs
% Each line comes from the lesson of its step (station in the section title)

%% Settings
eeglab nogui
eeglabRoot = fileparts(which('eeglab'));
dataDir    = fullfile(eeglabRoot, 'sample_data');
outDir     = pwd;
lineFreq   = 60;   % 60 Hz in Saudi Arabia and the Americas, 50 Hz in Europe

%% Load (station 1)
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', dataDir);
fullLocs = EEG.chanlocs;

%% Filtering and line noise (station 3)
% High-pass: passband edge at 0.1 Hz (removes slow drift)
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
% Notch: remove a narrow band around the line frequency (revfilt = 1)
EEG = pop_eegfiltnew(EEG, 'locutoff', lineFreq - 2, 'hicutoff', lineFreq + 2, 'revfilt', 1);

%% Bad channels and interpolation (station 3)
% Detection with clean_rawdata channel criteria only:
% no drift removal, no ASR, no window rejection, EOG channels ignored
EEG_test = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian', ...
    'channels_ignore', {'EOG1', 'EOG2'});

% Names of the channels it removed
badChans = setdiff({EEG.chanlocs.labels}, {EEG_test.chanlocs.labels}, 'stable');

% Add channels you found by eye, e.g. badChans = [badChans {'T7'}];
fprintf('Bad channels: %s\n', strjoin(badChans, ', '));

% Remove them by name, then rebuild them from the full channel list (fullLocs)
if ~isempty(badChans)
    EEG = pop_select(EEG, 'rmchannel', badChans);
end
if ~isempty(badChans)
    EEG = pop_interp(EEG, fullLocs, 'spherical');
end

%% Average reference (station 3)
% Average reference, EOG channels excluded
eogIdx = find(ismember({EEG.chanlocs.labels}, {'EOG1', 'EOG2'}));
EEG = pop_reref(EEG, [], 'exclude', eogIdx);
EEG.setname = 'D1 main';

%% ICA on a 1-Hz copy, weights copied back (station 4)
% Main dataset (high-pass 0.1 Hz, line noise removed, average reference) is in EEG
EEG_main = EEG;

% ICA copy: same data, high-pass at 1 Hz
EEG_ica = pop_eegfiltnew(EEG_main, 'locutoff', 1);
EEG_ica.setname = 'D1 ica1hz';

% Expected rank: channels - interpolated channels - 1 (average reference)
expectedRank = EEG_ica.nbchan - numel(badChans) - 1;
fprintf('Expected data rank: %d\n', expectedRank);

% Extended Infomax on the ICA copy
EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1);
% If "Data rank (N)" is missing or N differs from expectedRank, run instead:
% EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1, 'pca', expectedRank);

% Copy the decomposition back to the main dataset
EEG_main.icaweights  = EEG_ica.icaweights;
EEG_main.icasphere   = EEG_ica.icasphere;
EEG_main.icachansind = EEG_ica.icachansind;
EEG_main.icawinv     = [];   % recomputed by eeg_checkset
EEG_main.icaact      = [];
EEG = eeg_checkset(EEG_main);
clear EEG_main EEG_ica EEG_test   % free memory

%% ICLabel: remove eye and muscle components, then low-pass (station 4)
% Classify all components with the default ICLabel classifier
EEG = pop_iclabel(EEG, 'default');

% Flag components above 90% Muscle or Eye
% Row order: Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other
thresh = [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN];
EEG = pop_icflag(EEG, thresh);
artifactComps = find(EEG.reject.gcompreject);

% Remove them from the main dataset
if ~isempty(artifactComps)
    EEG = pop_subcomp(EEG, artifactComps, 0);
end
EEG.setname = 'D1 main clean';

% Low-pass at 30 Hz, postponed until after ICA cleaning
EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);
EEG.setname = 'D1 main clean lp30';
EEG = pop_saveset(EEG, 'filename', 'D1_main_clean_lp30.set', 'filepath', outDir);

%% Epochs, baseline, rejection (station 5)
% Cut 3-s epochs around every 'square' event: 1 s before to 2 s after
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'newname', 'D1 epochs', 'epochinfo', 'yes');
nEpochsAll = EEG.trials;

% Subtract the mean of -200 to 0 ms from every channel and epoch
EEG = pop_rmbase(EEG, [-200 0]);
EEG.setname = 'D1 epochs bl';

% Mark epochs where any channel goes beyond +/-100 uV anywhere in the epoch
EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -100, 100, EEG.xmin, EEG.xmax, 0, 0);
badEpochs = find(EEG.reject.rejthresh);
fprintf('Marked %d of %d epochs\n', numel(badEpochs), EEG.trials);

% Remove the marked epochs
if ~isempty(badEpochs)
    EEG = pop_rejepoch(EEG, EEG.reject.rejthresh, 0);
end
EEG.setname = 'D1 epochs clean';
EEG = eeg_checkset(EEG);
EEG = pop_saveset(EEG, 'filename', 'D1_epochs_clean.set', 'filepath', outDir);

%% Summary
fprintf('\n--- D1 pipeline summary ---\n');
fprintf('Bad channels interpolated: %d (%s)\n', numel(badChans), strjoin(badChans, ', '));
fprintf('ICA components removed:    %d (%s)\n', numel(artifactComps), num2str(artifactComps(:)'));
fprintf('Epochs kept:               %d of %d\n', EEG.trials, nEpochsAll);
fprintf('Saved: D1_main_clean_lp30.set and D1_epochs_clean.set in %s\n', outDir);
