% Copied from lessons/en/02-02-channel-locations.md. The lesson is the reference.
for iChan = 1:EEG.nbchan
    EEG.chanlocs(iChan).labels = strrep(EEG.chanlocs(iChan).labels, '.', '');
end
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); eeglab redraw;
