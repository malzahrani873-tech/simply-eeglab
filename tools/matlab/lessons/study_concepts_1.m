% Copied from lessons/en/08-01-study-concepts.md. The lesson is the reference.
% studyDir comes from the starting point script
files = dir(fullfile(studyDir, '*', '*.set'));
fprintf('%d dataset files under %s\n', numel(files), studyDir);

% Header only (no data) of two files from two different participants
A = pop_loadset('filename', files(1).name,   'filepath', files(1).folder,   'loadmode', 'info');
B = pop_loadset('filename', files(end).name, 'filepath', files(end).folder, 'loadmode', 'info');

% Side-by-side check of what must match before a STUDY
show = @(label, a, b) fprintf('%-20s %-14s %-14s\n', label, num2str(a), num2str(b));
fprintf('%-20s %-14s %-14s\n', 'Property', files(1).name, files(end).name);
show('Sampling rate (Hz)', A.srate,  B.srate);
show('Channels',           A.nbchan, B.nbchan);
show('Epoch start (s)',    A.xmin,   B.xmin);
show('Epoch end (s)',      A.xmax,   B.xmax);
show('Epochs',             A.trials, B.trials);
show('ICA weights',        ~isempty(A.icaweights), ~isempty(B.icaweights));
show('ICLabel results',    isfield(A.etc, 'ic_classification'), isfield(B.etc, 'ic_classification'));
show('Dipoles',            isfield(A.dipfit, 'model'), isfield(B.dipfit, 'model'));
fprintf('Same channel labels in the same order: %d\n', ...
    isequal({A.chanlocs.labels}, {B.chanlocs.labels}));

% Event types and their counts in each file
eeg_eventtypes(A);
eeg_eventtypes(B);
