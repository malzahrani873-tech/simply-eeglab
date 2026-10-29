% Copied from lessons/en/08-05-study-precompute.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% Folder for the course data (change it)
dataFolder = 'C:\Users\me\Documents\eeg-course';

% Download the ready Go-nogo STUDY once and unzip it in its own folder
zipDir = fullfile(dataFolder, 'animal_study');
studyFile = dir(fullfile(zipDir, '**', 'animal.study'));
if isempty(studyFile)
    zipFile = fullfile(dataFolder, 'animal_study.zip');
    websave(zipFile, 'https://sccn.ucsd.edu/eeglab/download/animal_study.zip');
    unzip(zipFile, zipDir);
    studyFile = dir(fullfile(zipDir, '**', 'animal.study'));
end
studyDir = studyFile(1).folder;

% Rebuild animal_mine.study (create-study lesson) if it is missing
if ~exist(fullfile(studyDir, 'animal_mine.study'), 'file')
    gender = containers.Map( ...
        {'cba','clm','ega','fsa','gro','hth','lmi','mba','mma','mta','pla','sce','sph','wpa'}, ...
        {'F',  'F',  'F',  'M',  'M',  'M',  'F',  'F',  'M',  'F',  'M',  'F',  'M',  'M'});
    files = dir(fullfile(studyDir, '*', '*.set'));
    commands = {};
    for k = 1:numel(files)
        hdr = pop_loadset('filename', files(k).name, 'filepath', files(k).folder, 'loadmode', 'info');
        subj = hdr.subject;
        if isempty(subj), [~, subj] = fileparts(files(k).folder); end
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
    [STUDY, ALLEEG] = std_editset([], [], 'name', 'Go-nogo animal (mine)', ...
        'task', 'Go-nogo categorization', 'commands', commands, 'updatedat', 'on');
    STUDY = pop_savestudy(STUDY, ALLEEG, 'filename', 'animal_mine.study', ...
        'filepath', studyDir, 'resavedatasets', 'on');
end
[STUDY, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', studyDir);

% Designs 2 and 3 (study-design lesson); design 2 is the current one
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name', 'image x gender', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'group', 'values2', {'F', 'M'}, 'vartype2', 'categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name', 'image only', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'none');
STUDY = std_selectdesign(STUDY, ALLEEG, 2);
STUDY = pop_savestudy(STUDY, ALLEEG, 'savemode', 'resave');

CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = 1:length(EEG);
eeglab redraw;
