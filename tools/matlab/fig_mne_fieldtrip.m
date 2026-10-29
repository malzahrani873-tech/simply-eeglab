% FIG_MNE_FIELDTRIP  Figure for lesson mne-fieldtrip (10-05): the Cz ERP of D1 from FieldTrip
%   (ft_singleplotER, solid) with the EEGLAB curve on top (dashed black), as in the lesson script.
%   Needs FieldTrip on the MATLAB path (addpath + ft_defaults): plugin batch of the run day.
%
% Output in assets-src/lessons/mne-fieldtrip/:
%   mne-fieldtrip-cz.png   900 x 560 px
%   facts.txt              FieldTrip version, trials, channels, sampling rate, largest difference

cfg = sea_init();
assert(exist('ft_defaults', 'file') == 2, 'FieldTrip is not on the MATLAB path (addpath, then ft_defaults).');
ft_defaults;
rel = fullfile('lessons', 'mne-fieldtrip');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end

% Same epochs as station 5, as in the lesson
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);
data = eeglab2fieldtrip(EEG, 'raw', 'none');

ftcfg = [];
erp = ft_timelockanalysis(ftcfg, data);
erpEeglab = mean(EEG.data, 3);
maxDiff = max(abs(erpEeglab(:) - erp.avg(:)));

figure('Color', 'w');
ftcfg = [];
ftcfg.channel = 'Cz';
ft_singleplotER(ftcfg, erp);
hold on;
iCz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));
plot(EEG.times / 1000, erpEeglab(iCz, :), 'k--');
legend({'FieldTrip', 'EEGLAB'});
sea_export(gcf, cfg, fullfile(rel, 'mne-fieldtrip-cz.png'), [900 560]);

ftver = ft_version;
fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nFieldTrip %s\n%d trials, %d channels, %g Hz\nmax difference EEGLAB vs FieldTrip: %g uV\n', ...
    cfg.stamp, ftver, numel(data.trial), numel(data.label), data.fsample, maxDiff);
fclose(fid);
type(fullfile(out, 'facts.txt'));
