% Copied from lessons/en/10-03-mvpa.md. The lesson is the reference.
% ERPLAB is not bundled with EEGLAB: install it from the extension manager
plugin_askinstall('ERPLAB', 'pop_decoding', true);

% Encode stimulus position in the event type: square1 / square2
isSquare = find(strcmp({EEG.event.type}, 'square'));
for k = isSquare
    EEG.event(k).type = sprintf('square%d', EEG.event(k).position);
end

% EventList: digits are kept, so square1 -> code 1, square2 -> code 2
EEG = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', ...
    'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'});

% Bin descriptor file: one bin per stimulus position
bdfFile = fullfile(pwd, 'd1_position_bins.txt');
fid = fopen(bdfFile, 'w');
fprintf(fid, 'bin 1\nSquare at position 1\n.{1}\n\n');
fprintf(fid, 'bin 2\nSquare at position 2\n.{2}\n');
fclose(fid);

% Assign bins, then cut bin-based epochs with a pre-stimulus baseline
EEG = pop_binlister(EEG, 'BDF', bdfFile, 'IndexEL', 1, ...
    'SendEL2', 'EEG', 'Voutput', 'EEG');
EEG = pop_epochbin(EEG, [-200 800], 'pre');
EEG.setname = 'D1 position bins';
fprintf('Trials per bin: %s\n', num2str(EEG.EVENTLIST.trialsperbin));

% BEST: single trials per bin, ready for decoding
BEST = pop_extractbest(EEG, 'Bins', [1 2], 'Criterion', 'good', ...
    'ExcludeBoundary', 'on');

% SVM decoding: 3 cross-validation blocks, 100 iterations, EOG excluded
chans = find(~ismember({EEG.chanlocs.labels}, {'EOG1', 'EOG2'}));
MVPC = pop_decoding(BEST, 'Classes', [1 2], 'Channels', chans, ...
    'nIter', 100, 'nCrossblocks', 3, 'Method', 'SVM', ...
    'classcoding', 'OneVsAll', 'TrialsAVGs', 'EqtrlEqagclasses', ...
    'OutcomeMetric', 'ACC');

% Plot decoding accuracy over time against chance
figure;
plot(MVPC.times, MVPC.average_score, 'LineWidth', 1.5); hold on;
yline(MVPC.chance, '--');
xline(0, ':');
xlabel('Time (ms)'); ylabel('Proportion correct');
title('D1: position 1 vs position 2');

% Peak accuracy after stimulus onset
post = MVPC.times > 0;
[peakAcc, iPeak] = max(MVPC.average_score(post));
postTimes = MVPC.times(post);
fprintf('Peak accuracy %.2f at %d ms (chance %.2f)\n', ...
    peakAcc, round(postTimes(iPeak)), MVPC.chance);

% Save the results
MVPC = pop_savemymvpc(MVPC, 'mvpcname', 'D1_position', ...
    'filename', 'D1_position.mvpc', 'filepath', pwd, 'Warning', 'off');
