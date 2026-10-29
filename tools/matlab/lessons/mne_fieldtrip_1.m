% Copied from lessons/en/10-05-mne-fieldtrip.md. The lesson is the reference.
% FieldTrip is a separate toolbox: add its main folder only, then ft_defaults
% addpath('/path/to/fieldtrip'); ft_defaults;

eeglab nogui
eeglabRoot = fileparts(which('eeglab'));
EEG = pop_loadset('eeglab_data.set', fullfile(eeglabRoot, 'sample_data'));

% Same epochs as station 5, so both tools see the same trials
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);

% Convert to a FieldTrip raw data structure (eeglab2fieldtrip ships with DIPFIT)
data = eeglab2fieldtrip(EEG, 'raw', 'none');
fprintf('%d trials, %d channels, %g Hz\n', numel(data.trial), numel(data.label), data.fsample);

% Average across trials: the FieldTrip ERP
cfg = [];
erp = ft_timelockanalysis(cfg, data);

% Same ERP computed in EEGLAB, for comparison
erpEeglab = mean(EEG.data, 3);
fprintf('Max difference EEGLAB vs FieldTrip: %g uV\n', max(abs(erpEeglab(:) - erp.avg(:))));

% Plot channel Cz from FieldTrip, with the EEGLAB curve on top
cfg = [];
cfg.channel = 'Cz';
ft_singleplotER(cfg, erp);
hold on;
iCz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));
plot(EEG.times / 1000, erpEeglab(iCz, :), 'k--');
legend({'FieldTrip', 'EEGLAB'});
