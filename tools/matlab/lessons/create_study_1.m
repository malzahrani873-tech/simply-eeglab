% Copied from lessons/en/08-02-create-study.md. The lesson is the reference.
% studyDir comes from the starting point script
% Gender per participant code (participants.tsv of ds002680)
gender = containers.Map( ...
    {'cba','clm','ega','fsa','gro','hth','lmi','mba','mma','mta','pla','sce','sph','wpa'}, ...
    {'F',  'F',  'F',  'M',  'M',  'M',  'F',  'F',  'M',  'F',  'M',  'F',  'M',  'M'});

files = dir(fullfile(studyDir, '*', '*.set'));
commands = {};
for k = 1:numel(files)
    hdr = pop_loadset('filename', files(k).name, 'filepath', files(k).folder, 'loadmode', 'info');
    % Subject: dataset field, otherwise the folder name
    subj = hdr.subject;
    if isempty(subj)
        [~, subj] = fileparts(files(k).folder);
    end
    % Condition: dataset field, otherwise the file name
    cond = hdr.condition;
    if isempty(cond)
        if contains(files(k).name, 'distractor'), cond = 'distractor'; else, cond = 'animal'; end
    end
    if ~isKey(gender, lower(subj))
        error('No gender entry for subject %s (%s)', subj, files(k).name);
    end
    commands{end+1} = {'index', k, 'load', fullfile(files(k).folder, files(k).name), ...
        'subject', subj, 'condition', cond, 'group', gender(lower(subj))};
end

% Create, save (with datasets) and reload the STUDY
[STUDY, ALLEEG] = std_editset([], [], 'name', 'Go-nogo animal (mine)', ...
    'task', 'Go-nogo categorization', 'commands', commands, 'updatedat', 'on');
STUDY = pop_savestudy(STUDY, ALLEEG, 'filename', 'animal_mine.study', ...
    'filepath', studyDir, 'resavedatasets', 'on');
[STUDY, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', studyDir);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = 1:length(EEG);

fprintf('%d datasets, %d subjects, conditions: %s, groups: %s\n', numel(STUDY.datasetinfo), ...
    numel(STUDY.subject), strjoin(STUDY.condition, ' '), strjoin(STUDY.group, ' '));
eeglab redraw;
