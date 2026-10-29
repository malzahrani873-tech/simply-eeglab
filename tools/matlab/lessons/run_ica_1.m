% Copied from lessons/en/04-03-run-ica.md. The lesson is the reference.
% Main dataset (high-pass 0.1 Hz, line noise removed, average reference) is in EEG
EEG_main = EEG;

% ICA copy: same data, high-pass at 1 Hz
EEG_ica = pop_eegfiltnew(EEG_main, 'locutoff', 1);
EEG_ica.setname = 'D1 ica1hz';

% Expected rank: channels - interpolated channels - 1 (average reference)
% badChans: channels you interpolated (set in the starting script; {} if none)
if ~exist('badChans', 'var'), badChans = {}; end
expectedRank = EEG_ica.nbchan - numel(badChans) - 1;
fprintf('Expected data rank: %d\n', expectedRank);

% Extended Infomax on the ICA copy
EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1);
% If "Data rank (N)" is missing or N differs from expectedRank, run instead:
% EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1, 'pca', expectedRank);

% Copy the decomposition back to the main dataset
EEG_main.icaweights  = EEG_ica.icaweights;
EEG_main.icasphere   = EEG_ica.icasphere;
EEG_main.icachansind = EEG_ica.icachansind;
EEG_main.icawinv     = [];   % recomputed by eeg_checkset
EEG_main.icaact      = [];
EEG = eeg_checkset(EEG_main);

% Scalp maps of the first 20 components
pop_topoplot(EEG, 0, 1:20);

EEG = pop_saveset(EEG, 'filename', 'D1_main_ica.set', 'filepath', pwd);
