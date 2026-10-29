% Copied from lessons/en/03-04-bad-channels.md. The lesson is the reference.
% Detection with clean_rawdata channel criteria only:
% no drift removal, no ASR, no window rejection, EOG channels ignored
EEG_test = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian', ...
    'channels_ignore', {'EOG1', 'EOG2'});

% Names of the channels it removed
badChans = setdiff({EEG.chanlocs.labels}, {EEG_test.chanlocs.labels}, 'stable');

% Add channels you found by eye, e.g. badChans = [badChans {'T7'}];
fprintf('Bad channels: %s\n', strjoin(badChans, ', '));

% Remove them by name from the main dataset
if ~isempty(badChans)
    EEG = pop_select(EEG, 'rmchannel', badChans);
end
EEG.setname = 'D1 badch';
EEG = pop_saveset(EEG, 'filename', 'D1_badch.set', 'filepath', pwd);
