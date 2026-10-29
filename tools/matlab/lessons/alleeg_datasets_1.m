% Copied from lessons/en/01-04-alleeg-datasets.md. The lesson is the reference.
% Start EEGLAB and load the sample dataset as dataset 1
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
sampleFolder = fullfile(fileparts(which('eeglab')), 'sample_data');
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', sampleFolder);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

% Remove the two eye channels and store the result as a new dataset
EEG = pop_select(EEG, 'rmchannel', {'EOG1', 'EOG2'});
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
    'setname', 'D1 no EOG', 'gui', 'off');

CURRENTSET                            % 2
[ALLEEG(1).nbchan ALLEEG(2).nbchan]   % 32 30

% Go back to dataset 1
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'retrieve', 1);
EEG.nbchan                            % 32

% Delete dataset 2 from memory (its file, if any, is not touched)
ALLEEG = pop_delset(ALLEEG, 2);
eeglab redraw;
