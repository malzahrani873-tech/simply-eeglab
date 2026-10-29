% Copied from lessons/en/09-03-batch-processing.md. The lesson is the reference.
%% D4 batch pipeline: same steps for every subject, errors logged
eeglab nogui

%% Settings
projectRoot = pwd;
bidsRoot    = fullfile(projectRoot, 'rawdata');
derivRoot   = fullfile(projectRoot, 'derivatives', 'eeglab');
logRoot     = fullfile(projectRoot, 'logs');
subjects    = {'sub-002', 'sub-003', 'sub-004'};

cfg.lineFreq    = 50;                          % UK recording: 50 Hz mains
cfg.eogLabels   = {'EEG061', 'EEG062'};        % HEOG, VEOG
cfg.dropLabels  = {'EEG063', 'EEG064'};        % ECG channels
cfg.epochEvents = {'famous_new', 'unfamiliar_new', 'scrambled_new'};
cfg.epochWindow = [-1 2];
cfg.thresholdUv = 100;

if ~exist(logRoot, 'dir'), mkdir(logRoot); end
logFile = fullfile(logRoot, 'batch_log.txt');

%% Import BIDS data once: events from trial_type, locations from electrodes.tsv
[STUDY, ALLEEG] = pop_importbids(bidsRoot, 'eventtype', 'trial_type', ...
    'bidsevent', 'on', 'bidschanloc', 'on', 'subjects', subjects, ...
    'outputdir', derivRoot, 'studyName', 'faces');
clear STUDY ALLEEG   % each subject is reloaded from disk inside the loop

%% Loop over subjects
nSub    = numel(subjects);
status  = repmat({'not run'}, nSub, 1);
nBad    = nan(nSub, 1);
nIcRem  = nan(nSub, 1);
nEpochs = nan(nSub, 1);

for s = 1:nSub
    subj = subjects{s};
    fprintf('\n===== %s (%d of %d) =====\n', subj, s, nSub);
    try
        inFile = fullfile(derivRoot, subj, 'eeg', sprintf('%s_task-FaceRecognition_eeg.set', subj));
        res = process_subject(inFile, cfg);
        status{s}  = 'ok';
        nBad(s)    = res.nBadChans;
        nIcRem(s)  = res.nIcRemoved;
        nEpochs(s) = res.nEpochs;
    catch err
        status{s} = 'failed';
        fid = fopen(logFile, 'a');
        fprintf(fid, '%s  %s  %s\n', datestr(now, 'yyyy-mm-dd HH:MM'), subj, err.message);
        fclose(fid);
        fprintf(2, 'FAILED %s: %s\n', subj, err.message);
    end
end

%% Summary table, one row per subject
summary = table(subjects(:), status, nBad, nIcRem, nEpochs, ...
    'VariableNames', {'subject', 'status', 'bad_channels', 'ics_removed', 'epochs_kept'});
disp(summary);
writetable(summary, fullfile(derivRoot, 'batch_summary.csv'));

%% ------------------------------------------------------------------
function res = process_subject(inFile, cfg)
% Single-subject pipeline from stations 3 to 5, with project settings in cfg

[inDir, baseName] = fileparts(inFile);
baseName = strrep(baseName, '_eeg', '');
EEG = pop_loadset('filename', [baseName '_eeg.set'], 'filepath', inDir);

% Remove ECG channels, keep EOG for ICA
EEG = pop_select(EEG, 'rmchannel', cfg.dropLabels);
fullLocs = EEG.chanlocs;

% High-pass: passband edge at 0.1 Hz (removes slow drift)
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
% Notch: remove a narrow band around the line frequency (revfilt = 1)
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.lineFreq - 2, 'hicutoff', cfg.lineFreq + 2, 'revfilt', 1);

% Detection with clean_rawdata channel criteria only:
% no drift removal, no ASR, no window rejection, EOG channels ignored
EEG_test = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian', ...
    'channels_ignore', cfg.eogLabels);
badChans = setdiff({EEG.chanlocs.labels}, {EEG_test.chanlocs.labels}, 'stable');
fprintf('Bad channels: %s\n', strjoin(badChans, ', '));
if ~isempty(badChans)
    EEG = pop_select(EEG, 'rmchannel', badChans);
end
if ~isempty(badChans)
    EEG = pop_interp(EEG, fullLocs, 'spherical');
end
clear EEG_test

% Average reference, EOG channels excluded
eogIdx = find(ismember({EEG.chanlocs.labels}, cfg.eogLabels));
EEG = pop_reref(EEG, [], 'exclude', eogIdx);

% ICA copy: same data, high-pass at 1 Hz
EEG_main = EEG;
EEG_ica = pop_eegfiltnew(EEG_main, 'locutoff', 1);
EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1);

% Copy the decomposition back to the main dataset
EEG_main.icaweights  = EEG_ica.icaweights;
EEG_main.icasphere   = EEG_ica.icasphere;
EEG_main.icachansind = EEG_ica.icachansind;
EEG_main.icawinv     = [];   % recomputed by eeg_checkset
EEG_main.icaact      = [];
EEG = eeg_checkset(EEG_main);
clear EEG_main EEG_ica

% Flag components above 90% Muscle or Eye, then remove them
EEG = pop_iclabel(EEG, 'default');
thresh = [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN];
EEG = pop_icflag(EEG, thresh);
artifactComps = find(EEG.reject.gcompreject);
if ~isempty(artifactComps)
    EEG = pop_subcomp(EEG, artifactComps, 0);
end

% Low-pass at 30 Hz, postponed until after ICA cleaning
EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);
EEG.setname = [baseName ' clean'];
EEG = pop_saveset(EEG, 'filename', [baseName '_desc-clean_eeg.set'], 'filepath', inDir);

% Epochs, baseline, rejection of epochs beyond the threshold
EEG = pop_epoch(EEG, cfg.epochEvents, cfg.epochWindow, 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);
EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -cfg.thresholdUv, cfg.thresholdUv, EEG.xmin, EEG.xmax, 0, 0);
if any(EEG.reject.rejthresh)
    EEG = pop_rejepoch(EEG, EEG.reject.rejthresh, 0);
end
EEG.setname = [baseName ' epochs'];
EEG = pop_saveset(EEG, 'filename', [baseName '_desc-epochs_eeg.set'], 'filepath', inDir);

res.nBadChans  = numel(badChans);
res.nIcRemoved = numel(artifactComps);
res.nEpochs    = EEG.trials;
end
