% Copied from lessons/en/10-04-write-plugin.md. The lesson is the reference.
function com = pop_chanvar(EEG, zThresh)
% POP_CHANVAR - Plot the standard deviation of each channel and
%               highlight channels far from the others.
%
% Usage:
%   >> pop_chanvar(EEG);           % ask for the threshold in a window
%   >> pop_chanvar(EEG, zThresh);  % plot directly
%
% Inputs:
%   EEG     - EEGLAB dataset
%   zThresh - robust z-score above which a channel is highlighted
%             (default in the window: 3)
%
% Output:
%   com     - command string for the EEGLAB history

com = '';
if nargin < 1
    help pop_chanvar;
    return;
end

% Missing threshold: ask for it
if nargin < 2
    res = inputgui('geometry', {[2 1]}, ...
        'uilist', { {'style', 'text', 'string', 'Robust z-score threshold'}, ...
                    {'style', 'edit', 'string', '3'} }, ...
        'title', 'Channel variance -- pop_chanvar()');
    if isempty(res), return; end   % user pressed Cancel
    zThresh = str2double(res{1});
end

% Standard deviation of each channel over all samples (and epochs)
data = double(reshape(EEG.data, EEG.nbchan, []));
sd   = std(data, 0, 2);

% Robust z-score based on the median absolute deviation
medSd = median(sd);
z = (sd - medSd) / (1.4826 * median(abs(sd - medSd)));
flagged = find(z > zThresh);

% Plot
figure('Name', 'Channel variance');
bar(sd, 'FaceColor', [0.6 0.6 0.6]); hold on;
if ~isempty(flagged)
    bar(flagged, sd(flagged), 'FaceColor', [0.85 0.2 0.2]);
end
set(gca, 'XTick', 1:EEG.nbchan, 'XTickLabel', {EEG.chanlocs.labels});
xtickangle(90);
ylabel('Standard deviation (\muV)');
title(sprintf('%s: %d channel(s) above z = %g', EEG.setname, ...
    numel(flagged), zThresh), 'Interpreter', 'none');
if ~isempty(flagged)
    fprintf('Channels above threshold: %s\n', ...
        strjoin({EEG.chanlocs(flagged).labels}, ' '));
end

% Command that reproduces this call
com = sprintf('pop_chanvar(EEG, %g);', zThresh);
