% FIG_INTERPOLATION  Before/after pair for lesson interpolation from D1 (the C3 exercise).
%   Before: scalp map of 'D1 noC3' (C3 removed). After: the same map of 'D1 C3 back' (spherical spline).
%   Both maps use the same time point, the same color limits and the same pixel size.
%
% The time point is the one between 10 and 60 s where C3 is at the 95th percentile of its absolute
% value: a clear value at C3 without picking an artifact.
%
% Output in assets-src/lessons/interpolation/:
%   interpolation-map-noC3.png, interpolation-map-C3-back.png
%   facts.txt   time point, color limits, correlation between original and interpolated C3

cfg = sea_init();
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
fullLocs = EEG.chanlocs;
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.notch(1), 'hicutoff', cfg.notch(2), 'revfilt', 1);
EEG.setname = 'D1 interp';
rel = fullfile('lessons', 'interpolation');

testChan = 'C3';
EEG_drop = pop_select(EEG, 'rmchannel', {testChan});
EEG_drop.setname = 'D1 noC3';
EEG_back = pop_interp(EEG_drop, fullLocs, 'spherical');
EEG_back.setname = 'D1 C3 back';
iOrig = find(strcmp({EEG.chanlocs.labels}, testChan));
iBack = find(strcmp({EEG_back.chanlocs.labels}, testChan));
r = corrcoef(double(EEG.data(iOrig, :)), double(EEG_back.data(iBack, :)));

% Fixed time point
seg = (10 * EEG.srate):(60 * EEG.srate);
a = abs(double(EEG.data(iOrig, seg)));
[~, order] = sort(a);
s = seg(order(round(0.95 * numel(order))));
lim = max(abs(double(EEG.data(:, s))));
clim = [-lim lim];

figure;
topoplot(double(EEG_drop.data(:, s)), EEG_drop.chanlocs, 'electrodes', 'on', 'maplimits', clim, ...
    'chaninfo', EEG_drop.chaninfo);
colormap(cfg.colormap);
sea_export(gcf, cfg, fullfile(rel, 'interpolation-map-noC3.png'), [700 700]);

figure;
topoplot(double(EEG_back.data(:, s)), EEG_back.chanlocs, 'electrodes', 'on', 'maplimits', clim, ...
    'chaninfo', EEG_back.chaninfo);
colormap(cfg.colormap);
sea_export(gcf, cfg, fullfile(rel, 'interpolation-map-C3-back.png'), [700 700]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\ntime point: %.3f s (sample %d)\ncolor limits: %s uV\nC3 original %.2f uV, interpolated %.2f uV\ncorrelation original vs interpolated C3 (whole recording): %.2f\n', ...
    cfg.stamp, (s - 1) / EEG.srate, s, mat2str(clim, 3), EEG.data(iOrig, s), EEG_back.data(iBack, s), r(1, 2));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
