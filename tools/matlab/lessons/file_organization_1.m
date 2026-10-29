% Copied from lessons/en/09-05-file-organization.md. The lesson is the reference.
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
eeglabRoot = fileparts(which('eeglab'));

% Project layout: raw data stay untouched, results go to derivatives
projectRoot = pwd;   % run from inside faces_project
bidsRoot    = fullfile(projectRoot, 'rawdata');            % ds002718 lives here
derivRoot   = fullfile(projectRoot, 'derivatives', 'eeglab');
folders = {bidsRoot, derivRoot, fullfile(projectRoot, 'code'), ...
           fullfile(projectRoot, 'figures'), fullfile(projectRoot, 'logs')};
for k = 1:numel(folders)
    if ~exist(folders{k}, 'dir'), mkdir(folders{k}); end
end

% Storage estimate from the raw files on disk
rawFiles  = dir(fullfile(bidsRoot, 'sub-*', 'eeg', '*_eeg.set'));
rawGB     = sum([rawFiles.bytes]) / 1e9;
nSubjects = numel(rawFiles);
fprintf('%d subject(s) on disk, %.2f GB of raw data\n', nSubjects, rawGB);

% Each continuous stage you save costs about one raw copy per subject
nSavedStages = 2;   % clean continuous + epochs
fprintf('Derivatives for these subjects: up to about %.1f GB\n', rawGB * nSavedStages);
fprintf('Full dataset (18 subjects): about %.1f GB raw\n', 18 * rawGB / max(nSubjects, 1));

% BIDS-style derivative name for one subject and one stage
subj   = 'sub-002';
stage  = 'clean';
outDir = fullfile(derivRoot, subj, 'eeg');
if ~exist(outDir, 'dir'), mkdir(outDir); end
outName = sprintf('%s_task-FaceRecognition_desc-%s_eeg.set', subj, stage);
fprintf('Save stage "%s" as %s\n', stage, fullfile(outDir, outName));

% Small files are cheap: keep ICA weights apart from the data
% icaInfo = struct('icaweights', EEG.icaweights, 'icasphere', EEG.icasphere, ...
%                  'icachansind', EEG.icachansind);
% save(fullfile(outDir, sprintf('%s_task-FaceRecognition_desc-ica.mat', subj)), '-struct', 'icaInfo');

% Convert a non-BIDS dataset (here D1) to BIDS with EEG-BIDS
data = struct('file', {fullfile(eeglabRoot, 'sample_data', 'eeglab_data.set')});
% Practice export only: delete d1_bids when you are done
bids_export(data, 'targetdir', fullfile(projectRoot, 'd1_bids'), ...
    'tInfo', struct('TaskName', 'attention', 'PowerLineFrequency', 60));
