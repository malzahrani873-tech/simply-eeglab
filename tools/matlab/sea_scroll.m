function fig = sea_scroll(EEG, chans, t0, secs, spacing, colors)
% SEA_SCROLL  Plot > Channel data (scroll) for selected channels and seconds, ready for sea_export.
%   fig = sea_scroll(EEG, {'FPz','Cz'}, 10, 5, 50)          black traces, 50 uV between channels
%   fig = sea_scroll(EEG, labels, 10, 5, 50, {'k','r',...})  one color per channel
% Uses eegplot on the selected data so the figure has the EEGLAB scroll look. Paired images pass the
% same channels, start, length and spacing, so both share one frame and scale.

if nargin < 6 || isempty(colors), colors = repmat({'k'}, 1, numel(chans)); end
[ok, idx] = ismember(lower(chans), lower({EEG.chanlocs.labels}));
if ~all(ok)
    error('sea:chan', 'Channels not found: %s', strjoin(chans(~ok), ', '));
end
s = round(t0 * EEG.srate) + (1:round(secs * EEG.srate));
eegplot(double(EEG.data(idx, s)), 'srate', EEG.srate, 'winlength', secs, 'spacing', spacing, ...
    'eloc_file', EEG.chanlocs(idx), 'color', colors, 'title', '', 'submean', 'on', ...
    'position', [50 50 1000 520]);
fig = gcf;
% Hide the scroll controls; keep the traces, channel names, time axis and scale
delete(findobj(fig, 'Type', 'uicontrol'));
delete(findobj(fig, 'Type', 'uimenu'));
end
