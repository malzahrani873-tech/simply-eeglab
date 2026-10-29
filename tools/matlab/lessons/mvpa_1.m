% Copied from lessons/en/10-03-mvpa.md. The lesson is the reference.
% ERPLAB is not bundled with EEGLAB: install it from the extension manager
plugin_askinstall('ERPLAB', 'pop_decoding', true);

% EventList, with the same options as the ERP CORE scripts
EEG = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', ...
    'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'});

% Bin descriptor file: bins 1 and 2 of BDF_N170.txt (correct trials only)
bdfFile = fullfile(pwd, 'n170_faces_cars_bins.txt');
fid = fopen(bdfFile, 'w');
fprintf(fid, 'bin 1\nFaces, Correct\n.{1-40}{t<200-1000>201}\n\n');
fprintf(fid, 'bin 2\nCars, Correct\n.{41-80}{t<200-1000>201}\n');
fclose(fid);

% Assign bins, then cut bin-based epochs with a pre-stimulus baseline
EEG = pop_binlister(EEG, 'BDF', bdfFile, 'IndexEL', 1, ...
    'SendEL2', 'EEG', 'Voutput', 'EEG');
EEG = pop_epochbin(EEG, [-200 800], 'pre');
EEG.setname = 'N170 sub2 faces cars';
fprintf('Trials per bin: %s\n', num2str(EEG.EVENTLIST.trialsperbin));

% BEST: single trials per bin, ready for decoding
BEST = pop_extractbest(EEG, 'Bins', [1 2], 'Criterion', 'good', ...
    'ExcludeBoundary', 'on');

% SVM decoding: 3 cross-validation blocks, 100 iterations
% Channels 1-28 are the scalp channels; 29-35 are eye and bipolar EOG
chans = 1:28;
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
title('ERP CORE N170, participant 2: faces vs cars');

% Peak accuracy after stimulus onset
post = MVPC.times > 0;
[peakAcc, iPeak] = max(MVPC.average_score(post));
postTimes = MVPC.times(post);
fprintf('Peak accuracy %.2f at %d ms (chance %.2f)\n', ...
    peakAcc, round(postTimes(iPeak)), MVPC.chance);

% Save the results
MVPC = pop_savemymvpc(MVPC, 'mvpcname', 'N170_sub2_faces_cars', ...
    'filename', 'N170_sub2_faces_cars.mvpc', 'filepath', pwd, 'Warning', 'off');
