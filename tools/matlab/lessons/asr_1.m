% Copied from lessons/en/03-05-asr.md. The lesson is the reference.
% ASR on a copy: no channel criteria (bad channels lesson), EOG channels ignored
EEG_asr = pop_clean_rawdata(EEG, 'FlatlineCriterion', 'off', 'ChannelCriterion', 'off', ...
    'LineNoiseCriterion', 'off', 'Highpass', 'off', 'BurstCriterion', 20, ...
    'WindowCriterion', 0.25, 'BurstRejection', 'on', 'Distance', 'Euclidian', ...
    'WindowCriterionTolerances', [-Inf 7], 'channels_ignore', {'EOG1', 'EOG2'});
EEG_asr.setname = 'D1 asr';

% How much data was kept, and how many boundary events were added
fprintf('Data kept: %.1f of %.1f s (%.1f%%)\n', EEG_asr.pnts / EEG_asr.srate, ...
    EEG.pnts / EEG.srate, 100 * EEG_asr.pnts / EEG.pnts);
fprintf('Boundary events: %d\n', sum(strcmp({EEG_asr.event.type}, 'boundary')));

% Effect on epochs: pop_epoch drops every epoch that contains a boundary event
epBefore = pop_epoch(EEG, {'square'}, [-0.2 0.8]);
epAfter  = pop_epoch(EEG_asr, {'square'}, [-0.2 0.8]);
fprintf('Epochs around square: %d before ASR, %d after\n', epBefore.trials, epAfter.trials);

% Original and cleaned data in one scrolling window
vis_artifacts(EEG_asr, EEG);
