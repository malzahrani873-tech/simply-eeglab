% Copied from lessons/en/05-03-epoch-rejection.md. The lesson is the reference.
% Mark epochs where any channel goes beyond +/-100 uV anywhere in the epoch
EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -100, 100, EEG.xmin, EEG.xmax, 0, 0);
badEpochs = find(EEG.reject.rejthresh);
fprintf('Marked %d of %d epochs\n', numel(badEpochs), EEG.trials);

% Remove the marked epochs
if ~isempty(badEpochs)
    EEG = pop_rejepoch(EEG, EEG.reject.rejthresh, 0);
end
EEG.setname = 'D1 epochs clean';
EEG = eeg_checkset(EEG);
EEG = pop_saveset(EEG, 'filename', 'D1_epochs_clean.set', 'filepath', pwd);
