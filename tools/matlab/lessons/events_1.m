% Copied from lessons/en/02-03-events.md. The lesson is the reference.
% Start EEGLAB and load the file from the previous lesson
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
dataFolder = 'C:\Users\me\Documents\eeg-course';   % change it
EEG = pop_loadset('filename', 'S001R03.set', 'filepath', dataFolder);

% Event types and how many of each
eeg_eventtypes(EEG)          % T0 15, T1 8, T2 7
numel(EEG.event)             % 30

% Type and latency of the first four events (latency in samples)
{EEG.event(1:4).type}        % 'T0' 'T2' 'T0' 'T1'
[EEG.event(1:4).latency]     % 1 673 1329 2001

% The same latencies in seconds: (sample - 1) / sampling rate
([EEG.event(1:4).latency] - 1) / EEG.srate   % 0 4.2 8.3 12.5

% Duration is also stored in samples
[EEG.event(1:2).duration] / EEG.srate        % 4.2 4.1

% Scroll through the data with its events
pop_eegplot(EEG, 1, 1, 1);
