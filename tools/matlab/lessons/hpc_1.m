% Copied from lessons/en/09-06-hpc.md. The lesson is the reference.
% run_ica_d4.m - one subject per job, no display
% Local test:  matlab -batch "run_ica_d4"
% On SLURM:    the array index selects the subject
eeglab nogui

projectRoot = pwd;
outRoot     = fullfile(projectRoot, 'derivatives', 'eeglab');
logRoot     = fullfile(projectRoot, 'logs');
subjects    = {'sub-002', 'sub-003', 'sub-004'};

% Subject index from the cluster, or 1 when run locally
taskId = str2double(getenv('SLURM_ARRAY_TASK_ID'));
if isnan(taskId), taskId = 1; end
subj = subjects{taskId};
fprintf('Job %d: %s\n', taskId, subj);

cfg.lineFreq  = 50;                     % same settings as the batch lesson
cfg.eogLabels = {'EEG061', 'EEG062'};
cfg.dropLabels = {'EEG063', 'EEG064'};

try
    % File written by pop_importbids in the batch processing lesson
    outDir = fullfile(outRoot, subj, 'eeg');
    EEG = pop_loadset('filename', sprintf('%s_task-FaceRecognition_eeg.set', subj), ...
        'filepath', outDir);

    % Same steps as process_subject up to ICA, so the weights fit its main dataset
    EEG = pop_select(EEG, 'rmchannel', cfg.dropLabels);
    fullLocs = EEG.chanlocs;
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);
    EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.lineFreq - 2, 'hicutoff', cfg.lineFreq + 2, 'revfilt', 1);
    EEG_test = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian', ...
        'channels_ignore', cfg.eogLabels);
    badChans = setdiff({EEG.chanlocs.labels}, {EEG_test.chanlocs.labels}, 'stable');
    if ~isempty(badChans)
        EEG = pop_select(EEG, 'rmchannel', badChans);
    end
    if ~isempty(badChans)
        EEG = pop_interp(EEG, fullLocs, 'spherical');
    end
    clear EEG_test
    eogIdx = find(ismember({EEG.chanlocs.labels}, cfg.eogLabels));
    EEG = pop_reref(EEG, [], 'exclude', eogIdx);

    % ICA on a 1-Hz high-passed copy (the slow step worth a cluster)
    EEG_ica = pop_eegfiltnew(EEG, 'locutoff', 1);
    tic;
    % No one watches the job, so give the rank: channels - interpolated - 1 (average reference)
    expectedRank = EEG_ica.nbchan - numel(badChans) - 1;
    EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1, 'pca', expectedRank);
    fprintf('ICA finished in %.1f min\n', toc / 60);

    % Save only the small result: the ICA weights and the bad channel list
    icaInfo = struct('icaweights', EEG_ica.icaweights, 'icasphere', EEG_ica.icasphere, ...
                     'icachansind', EEG_ica.icachansind, 'badChans', {badChans});
    save(fullfile(outDir, sprintf('%s_task-FaceRecognition_desc-ica.mat', subj)), ...
         '-struct', 'icaInfo');
catch err
    % Write the error to a log file, then exit with an error code
    if ~exist(logRoot, 'dir'), mkdir(logRoot); end
    fid = fopen(fullfile(logRoot, sprintf('%s_error.txt', subj)), 'w');
    fprintf(fid, '%s\n', getReport(err, 'extended', 'hyperlinks', 'off'));
    fclose(fid);
    rethrow(err);
end
