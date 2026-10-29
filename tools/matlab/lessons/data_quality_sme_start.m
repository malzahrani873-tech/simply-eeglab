% Copied from lessons/en/06-05-data-quality-sme.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% The 40 single-participant ERPsets from chapter 10 of Luck's book
dataDir = fullfile(pwd, 'Chapter_10', 'Data', 'ERPsets');
files = dir(fullfile(dataDir, '*.erp'));
ALLERP = [];   % start from an empty ERPset list
[ERP, ALLERP] = pop_loaderp('filename', {files.name}, 'filepath', dataDir, ...
    'UpdateMainGui', 'on');
fprintf('Loaded %d ERPsets\n', numel(ALLERP));
eeglab redraw
