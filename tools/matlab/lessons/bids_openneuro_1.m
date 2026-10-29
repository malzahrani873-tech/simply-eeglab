% Copied from lessons/en/02-04-bids-openneuro.md. The lesson is the reference.
% Start EEGLAB (EEG-BIDS ships with EEGLAB 2026.1)
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Folder where you downloaded ds002718 with sub-002 (change it)
bidsFolder = 'C:\Users\me\Documents\eeg-course\ds002718';

% Import: events from the trial_type column, positions from electrodes.tsv
[STUDY, ALLEEG] = pop_importbids(bidsFolder, ...
    'eventtype', 'trial_type', 'bidsevent', 'on', 'bidschanloc', 'on', ...
    'outputdir', fullfile(bidsFolder, 'derivatives', 'eeglab'));

% Make the imported dataset the current one and show it
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = 1:numel(EEG);
eeglab redraw;

% Check what arrived
EEG(1).nbchan                % 74
EEG(1).srate                 % 250
numel(EEG(1).event)          % 1479
eeg_eventtypes(EEG(1))       % right_sym 500, famous_new 150, ...
