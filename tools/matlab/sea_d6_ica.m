function sea_d6_ica(cfg)
% SEA_D6_ICA  Dipoles and ICLabel for every dataset of animal_mine.study, on the authors' ICA.
%   The ready STUDY (animal_study.zip) already holds ICA weights (31 components, 29 for cba), so ICA is
%   not run again: every learner gets the same decomposition. Its dipfit models point to an old
%   absolute hdmfile path, so dipoles are fitted again with the current template, and ICLabel is run.
%   Same steps as the Starting point of lesson ic-clustering (08-09). Run it before the lesson: the
%   Starting point then finds everything present and skips its long step.
%   Needs Fieldtrip-lite (dipole fitting). Nothing happens if dipoles and ICLabel are already current.
if nargin < 1, cfg = sea_init(); end
hit = dir(fullfile(cfg.course_dir, '**', 'animal_mine.study'));
assert(~isempty(hit), 'animal_mine.study not found under %s. Run verify_batch(''st8'') first.', cfg.course_dir);
[~, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', hit(1).folder);

noIca = find(cellfun(@isempty, {ALLEEG.icaweights}));
assert(isempty(noIca), 'No ICA weights in %s. Use the ready STUDY files (animal_study.zip).', ...
    strjoin({ALLEEG(noIca).filename}, ', '));
needDip = ~isfield(ALLEEG(1).dipfit, 'model') || isempty(ALLEEG(1).dipfit.model) || ...
    ~isfield(ALLEEG(1).dipfit, 'hdmfile') || ~exist(ALLEEG(1).dipfit.hdmfile, 'file');
needLab = ~isfield(ALLEEG(1).etc, 'ic_classification');
if ~(needDip || needLab)
    fprintf('[sea] D6: dipoles and ICLabel already present\n');
    return
end
if needDip && ~exist('ft_dipolefitting', 'file')
    error('sea:fieldtrip', 'Fieldtrip-lite is not installed (File > Manage EEGLAB extensions).');
end
tStart = tic;
dipfitdefs;                                         % template_models
subjects = unique({ALLEEG.subject});
for s = 1:numel(subjects)
    idx = find(strcmp({ALLEEG.subject}, subjects{s}));
    shared = all(arrayfun(@(k) isequal(ALLEEG(k).icaweights, ALLEEG(idx(1)).icaweights), idx));
    for k = idx
        TMP = eeg_checkset(ALLEEG(k), 'loaddata');
        if needDip
            if k == idx(1) || ~shared               % one fit per decomposition, copied when it is shared
                [~, coreg] = coregister(TMP.chanlocs, template_models(2).chanfile, 'warp', 'auto', 'manual', 'off');
                TMP = pop_dipfit_settings(TMP, 'model', 'standardBEM', 'coord_transform', coreg);
                TMP = pop_multifit(TMP, [], 'threshold', 100);
                fitted = TMP.dipfit;
            else
                TMP.dipfit = fitted;
            end
        end
        TMP = pop_iclabel(TMP, 'default');
        pop_saveset(TMP, 'savemode', 'resave');
    end
    fprintf('[sea] D6 participant %s done (%d of %d)\n', subjects{s}, s, numel(subjects));
end
fprintf('[sea] D6 dipoles and ICLabel: %.0f min\n', toc(tStart) / 60);
end
