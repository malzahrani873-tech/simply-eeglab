% Copied from lessons/en/08-10-limo.md. The lesson is the reference.
% STUDY, ALLEEG and studyDir come from the starting point script
if ~exist('limo_random_select', 'file')
    error('Install the LIMO plugin first: File > Manage EEGLAB extensions');
end
if ~exist('ft_prepare_neighbours', 'file')
    error('Install Fieldtrip-lite first: LIMO needs it for the channel neighbours');
end

% 1st level: one linear model per participant on the single-trial ERPs (design 3)
STUDY = std_selectdesign(STUDY, ALLEEG, 3);
[STUDY, ~, limoFiles] = pop_limo(STUDY, ALLEEG, 'dat', 'method', 'OLS', 'measure', 'daterp', ...
    'erase', 'on', 'splitreg', 'off');
designName = STUDY.design(3).name(~isspace(STUDY.design(3).name));
glmName = [STUDY.filename(1:end-6) '_' designName '_GLM_Channels_Time_OLS'];
betaFile = fullfile(limoFiles.LIMO, ['Beta_files_' glmName '.txt']);
betaList = strtrim(splitlines(fileread(betaFile)));
fprintf('1st level done: %d participants listed in %s\n', nnz(~cellfun(@isempty, betaList)), betaFile);

% 2nd level: paired test of beta 1 (animal) against beta 2 (distractor), 1000 bootstraps
resDir = fullfile(limoFiles.LIMO, 'paired_animal_distractor');
if ~exist(resDir, 'dir'), mkdir(resDir); end
startDir = pwd;
cd(resDir);   % LIMO writes the 2nd-level files in the current folder
limo_random_select('paired t-test', STUDY.limo.chanloc, 'LIMOfiles', {betaFile}, ...
    'parameters', {[1 2]}, 'analysis_type', 'Full scalp analysis', 'type', 'Channels', ...
    'nboot', 1000, 'tfce', 0);

% Spatio-temporal cluster correction at p = 0.05
load(fullfile(resDir, 'LIMO.mat'), 'LIMO');
[~, mask] = limo_stat_values('Paired_Samples_Ttest_parameter_1_2.mat', 0.05, 2, LIMO);
cd(startDir);
neighbours = load(STUDY.limo.chanloc);
chanNames = {neighbours.expected_chanlocs.labels};
fprintf('Significant channel x time points after cluster correction: %d\n', nnz(mask));
fprintf('Channels inside a significant cluster: %s\n', strjoin(chanNames(any(mask, 2)), ' '));
