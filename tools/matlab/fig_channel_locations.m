% FIG_CHANNEL_LOCATIONS  Head plot for lesson channel-locations from D2 (EEGMMIDB S001R03).
%   Same steps as the lesson: names without trailing dots -> lookup in standard_1005.elc ->
%   Plot > Channel locations > By name (topoplot 'labelpoint').
%
% Requires the Biosig plugin. Output in assets-src/lessons/channel-locations/:
%   channel-locations-by-name.png   64 electrodes with names, nose at the top
%   facts.txt                       channels with coordinates, electrodes outside the head circle
% The arrows (Cz, Fpz, Oz, lower edge of the cap) are added after conversion, not here.

cfg = sea_init();
if ~exist(cfg.d2, 'file')
    error('sea:nodata', 'File not found: %s\nDownload it from https://physionet.org/files/eegmmidb/1.0.0/S001/S001R03.edf', cfg.d2);
end
EEG = pop_biosig(cfg.d2);
for iChan = 1:EEG.nbchan
    EEG.chanlocs(iChan).labels = strrep(EEG.chanlocs(iChan).labels, '.', '');
end
EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');
EEG = eeg_checkset(EEG);
rel = fullfile('lessons', 'channel-locations');

figure;
topoplot([], EEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
sea_export(gcf, cfg, fullfile(rel, 'channel-locations-by-name.png'), [900 900]);

% Electrodes plotted on or outside the head circle (topoplot radius 0.5)
hasXYZ = ~cellfun(@isempty, {EEG.chanlocs.X});
rad = [EEG.chanlocs.radius];
outside = {EEG.chanlocs(rad >= 0.5).labels};
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nchannels with coordinates: %d of %d\non or outside the head circle (radius >= 0.5): %s\n', ...
    cfg.stamp, sum(hasXYZ), EEG.nbchan, strjoin(outside, ' '));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
