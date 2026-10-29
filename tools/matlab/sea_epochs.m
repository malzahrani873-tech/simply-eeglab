function ep = sea_epochs(cfg)
% SEA_EPOCHS  D1 epochs as in the station 5 lessons, from 'D1 main clean lp30' (sea_clean).
%   ep.raw    'D1 epochs'        epochs around 'square', -1 to 2 s, no baseline correction
%   ep.bl     'D1 epochs bl'     baseline -200 to 0 ms removed
%   ep.clean  'D1 epochs clean'  epochs beyond +/-100 uV rejected (pop_eegthresh, all channels)
% The three are saved (overwritten) in <cfg.work> as D1_epochs.set, D1_epochs_bl.set and D1_epochs_clean.set,
% fixed names that run_checklist 2.8 loads for the by-eye checks.

[~, EEG] = sea_clean(cfg);
ep.raw = pop_epoch(EEG, {'square'}, [-1 2], 'newname', 'D1 epochs', 'epochinfo', 'yes');
ep.raw = eeg_checkset(ep.raw);
ep.bl = pop_rmbase(ep.raw, [-200 0]);
ep.bl.setname = 'D1 epochs bl';
ep.clean = pop_eegthresh(ep.bl, 1, 1:ep.bl.nbchan, -100, 100, ep.bl.xmin, ep.bl.xmax, 0, 0);
if any(ep.clean.reject.rejthresh)
    ep.clean = pop_rejepoch(ep.clean, ep.clean.reject.rejthresh, 0);
end
ep.clean.setname = 'D1 epochs clean';
ep.clean = eeg_checkset(ep.clean);
names = {'raw', 'D1_epochs.set'; 'bl', 'D1_epochs_bl.set'; 'clean', 'D1_epochs_clean.set'};
for k = 1:size(names, 1)
    pop_saveset(ep.(names{k, 1}), 'filename', names{k, 2}, 'filepath', cfg.work);
end
end
