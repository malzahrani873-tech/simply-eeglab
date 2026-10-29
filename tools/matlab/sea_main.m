function EEG = sea_main(cfg)
% SEA_MAIN  D1 main dataset, as in the Starting point of the run-ica and iclabel lessons:
%   high-pass 0.1 Hz -> 60 Hz line-noise removal (band-stop 58-62 Hz) -> average reference
%   without the two EOG channels.
% No bad channels are removed in D1 (badChans is empty in the lessons); the 30 Hz low-pass comes
% after ICA component removal.

EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.notch(1), 'hicutoff', cfg.notch(2), 'revfilt', 1);
eogIdx = find(ismember({EEG.chanlocs.labels}, cfg.d1_eog));
EEG = pop_reref(EEG, [], 'exclude', eogIdx);
EEG.setname = 'D1 main';
EEG = eeg_checkset(EEG);
end
