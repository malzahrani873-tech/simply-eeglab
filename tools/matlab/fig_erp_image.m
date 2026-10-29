% FIG_ERP_IMAGE  Before/after pair for lesson erp-image (07-03), channel Pz of D1 epochs clean.
%
% Output in assets-src/lessons/erp-image/ (both PNGs 900 x 760 px, same frame and axes):
%   erp-image-before.png   trials in recording order, no smoothing (Smoothing = 1)
%   erp-image-after.png    trials sorted by the latency of 'rt', 10-trial moving average,
%                          with the response-time curve
%   facts.txt              epochs with a response, median RT, color limits printed by erpimage
% Both calls are the lesson's, with its ERP, color bar and scalp-map options.

cfg = sea_init();
ep = sea_epochs(cfg);
EEG = ep.clean;
rel = fullfile('lessons', 'erp-image');
if ~exist(fullfile(cfg.out, rel), 'dir'), mkdir(fullfile(cfg.out, rel)); end
sizepx = [900 760];
chan = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
rt = eeg_getepochevent(EEG, 'type', {'rt'}, 'timewin', [0 1000]);

figure;
logBefore = evalc(['pop_erpimage(EEG, 1, chan, [], ''Pz'', 1, 1, {}, [], '''', ' ...
    '''erp'', ''on'', ''cbar'', ''on'', ''limits'', [-200 800], ''topo'', {chan EEG.chanlocs EEG.chaninfo});']);
sea_export(gcf, cfg, fullfile(rel, 'erp-image-before.png'), sizepx);

figure;
logAfter = evalc(['pop_erpimage(EEG, 1, chan, [], ''Pz sorted by RT'', 10, 1, {''rt''}, [0 1000], ''latency'', ' ...
    '''erp'', ''on'', ''cbar'', ''on'', ''limits'', [-200 800], ''topo'', {chan EEG.chanlocs EEG.chaninfo});']);
sea_export(gcf, cfg, fullfile(rel, 'erp-image-after.png'), sizepx);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\n%d of %d epochs have a response, median RT %.0f ms\n', cfg.stamp, ...
    sum(~isnan(rt)), EEG.trials, median(rt, 'omitnan'));
fprintf(fid, 'before: %s\nafter : %s\n', caxisLine(logBefore), caxisLine(logAfter));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

function s = caxisLine(log)
% The line where erpimage reports the color limits it used.
s = strtrim(regexp(log, '[^\n]*caxis range[^\n]*', 'match', 'once'));
if isempty(s), s = 'caxis line not found'; end
end
