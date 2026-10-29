% Copied from lessons/en/02-03-events.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
% Folder where you keep the course data (change it)
dataFolder = 'C:\Users\me\Documents\eeg-course';
EEG = pop_loadset('filename', 'S001R03.set', 'filepath', dataFolder);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'S001R03', 'gui', 'off');
eeglab redraw;
