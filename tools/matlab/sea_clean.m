function [EEGclean, EEGlp] = sea_clean(cfg)
% SEA_CLEAN  D1 after ICA cleaning, as at the end of the iclabel lesson.
%   [EEGclean, EEGlp] = sea_clean(cfg)
%   EEGclean  'D1 main clean'       components removed, no low-pass (power-spectrum lesson)
%   EEGlp     'D1 main clean lp30'  the same after the 30 Hz low-pass (station 5 and 6 lessons)
% Reads <cfg.work>/D1_main_clean.set and D1_main_clean_lp30.set when fig_iclabel.m has saved them.
% Otherwise rebuilds them with the same steps (fixed ICA seed, cfg.ica_opts) and saves them.

fClean = fullfile(cfg.work, 'D1_main_clean.set');
fLp = fullfile(cfg.work, 'D1_main_clean_lp30.set');
if exist(fClean, 'file') && exist(fLp, 'file')
    EEGclean = pop_loadset('filename', 'D1_main_clean.set', 'filepath', cfg.work);
    EEGlp = pop_loadset('filename', 'D1_main_clean_lp30.set', 'filepath', cfg.work);
    return
end

fIca = fullfile(cfg.work, 'D1_main_ica.set');
if exist(fIca, 'file')
    EEG = pop_loadset('filename', 'D1_main_ica.set', 'filepath', cfg.work);
else
    EEG = sea_main(cfg);
    EEG_ica = pop_eegfiltnew(EEG, 'locutoff', cfg.ica_hp);
    EEG_ica = pop_runica(EEG_ica, cfg.ica_opts{:});
    EEG.icaweights  = EEG_ica.icaweights;
    EEG.icasphere   = EEG_ica.icasphere;
    EEG.icachansind = EEG_ica.icachansind;
    EEG.icawinv     = [];
    EEG.icaact      = [];
    EEG = eeg_checkset(EEG);
    pop_saveset(EEG, 'filename', 'D1_main_ica.set', 'filepath', cfg.work);
end

% Same thresholds as the lessons: Muscle and Eye between 0.9 and 1
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);
rej = find(EEG.reject.gcompreject);
EEGclean = EEG;
if ~isempty(rej)
    EEGclean = pop_subcomp(EEG, rej, 0);
end
EEGclean.setname = 'D1 main clean';
pop_saveset(EEGclean, 'filename', 'D1_main_clean.set', 'filepath', cfg.work);
EEGlp = pop_eegfiltnew(EEGclean, 'hicutoff', cfg.erp_lp);
EEGlp.setname = 'D1 main clean lp30';
pop_saveset(EEGlp, 'filename', 'D1_main_clean_lp30.set', 'filepath', cfg.work);
end
