% Copied from lessons/en/08-02-create-study.md. The lesson is the reference.
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
fprintf('Go-nogo STUDY folder: %s\n', studyDir);
eeglab redraw;
