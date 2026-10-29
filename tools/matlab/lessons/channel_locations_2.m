% Copied from lessons/en/02-02-channel-locations.md. The lesson is the reference.
% Start EEGLAB and load the file from the previous lesson
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
dataFolder = 'C:\Users\me\Documents\eeg-course';   % change it
EEG = pop_loadset('filename', 'S001R03.set', 'filepath', dataFolder);
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

% Remove the trailing dots from the names (Fc5. -> Fc5, Cz.. -> Cz)
for iChan = 1:EEG.nbchan
    EEG.chanlocs(iChan).labels = strrep(EEG.chanlocs(iChan).labels, '.', '');
end

% Look up the positions in the standard MNI template
% (case does not matter: Fc5 matches FC5)
EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');
EEG = eeg_checkset(EEG);

% Plot the electrodes by name (same as Plot > Channel locations > By name)
figure; topoplot([], EEG.chanlocs, 'style', 'blank', ...
    'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);

% Save over the lesson file and show the result in the main window
EEG = pop_saveset(EEG, 'savemode', 'resave');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw
