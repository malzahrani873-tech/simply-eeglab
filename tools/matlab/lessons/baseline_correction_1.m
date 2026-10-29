% Copied from lessons/en/05-02-baseline-correction.md. The lesson is the reference.
% Subtract the mean of -200 to 0 ms from every channel and epoch
EEG = pop_rmbase(EEG, [-200 0]);
EEG.setname = 'D1 epochs bl';
EEG = eeg_checkset(EEG);

% Check: the baseline mean should now be close to zero everywhere
blIdx = EEG.times >= -200 & EEG.times <= 0;
blMeans = mean(EEG.data(:, blIdx, :), 2);
fprintf('Baseline points: %d, largest baseline mean: %.2g uV\n', sum(blIdx), max(abs(blMeans(:))));
