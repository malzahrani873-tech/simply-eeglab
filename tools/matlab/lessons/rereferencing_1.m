% Copied from lessons/en/03-07-rereferencing.md. The lesson is the reference.
% Keep a copy to compare before and after
EEG_before = EEG;

% Average reference, EOG channels excluded
eogIdx = find(ismember({EEG.chanlocs.labels}, {'EOG1', 'EOG2'}));
EEG = pop_reref(EEG, [], 'exclude', eogIdx);
EEG.setname = 'D1 main';

% Check: scalp channels now sum to (almost) zero at every time point
scalpIdx = setdiff(1:EEG.nbchan, eogIdx);
fprintf('Reference: %s\n', EEG.ref);
fprintf('Largest sum over scalp channels: %g uV\n', max(abs(sum(EEG.data(scalpIdx, :), 1))));

% Channel Oz over 5 seconds, before and after
oz = find(strcmp({EEG.chanlocs.labels}, 'Oz'));
t = 1:5*EEG.srate;
figure;
plot(t / EEG.srate, EEG_before.data(oz, t), t / EEG.srate, EEG.data(oz, t));
legend('Original reference (mastoid)', 'Average reference');
xlabel('Time (s)'); ylabel('Amplitude (uV)');

EEG = pop_saveset(EEG, 'filename', 'D1_main.set', 'filepath', pwd);
