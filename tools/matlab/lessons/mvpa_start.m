% Copied from lessons/en/10-03-mvpa.md. The lesson is the reference.
% Starting point
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% ERP CORE N170, participant 2, from the "intermediate-stage processed
% files" download. ERP CORE already applied: event shift of 26 ms,
% resampling to 256 Hz, average reference, 0.1 Hz high-pass and ICA
% correction of blinks and eye movements. Continuous, not epoched.
dataDir = fullfile(pwd, 'N170', '2');
EEG = pop_loadset('filename', '2_N170_shifted_ds_reref_ucbip_hpfilt_ica_corr_cbip.set', ...
    'filepath', dataDir);

% Show the dataset in the main EEGLAB window
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'N170 sub2 ica corr', 'gui', 'off');
eeglab redraw;
