% FIG_SIFT  Lesson sift (10-02): runs the lesson's SIFT steps on D1 without any window and saves the result
%   for the Time-Frequency Grid screenshot. Needs SIFT (not bundled with EEGLAB): plugin batch of the run day.
%   Builds the lesson's Starting point from 'D1 main clean' (sea_clean.m: fixed ICA seed, Eye and Muscle
%   above 0.9 removed, no 30 Hz low-pass), then epochs around 'square' [-1 2] s,
%   baseline [-200 0] ms, rejection beyond +/-100 uV.
%
% Output:
%   assets-src/lessons/sift/facts.txt   components, model order, parameter ratio, validation, run times
%   <cfg.work>/D1_sift.set               the dataset with its SIFT results (EEG.CAT)
% Screenshot (run_checklist), after this script:
%   cfg = sea_config(); EEG = pop_loadset('filename', 'D1_sift.set', 'filepath', cfg.work);
%   pop_vis_TimeFreqGrid(EEG);   % Ok with the lesson's settings, then save the grid as
%                                % assets-src/lessons/sift/sift-timefreq-grid.png

cfg = sea_init();
assert(exist('pop_est_fitMVAR', 'file') == 2, 'SIFT is not installed (File > Manage EEGLAB extensions).');
rel = fullfile('lessons', 'sift');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end

% --- Starting point: components removed, no low-pass (sea_clean.m) ----------------------
EEG = sea_clean(cfg);
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'newname', 'D1 epochs', 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);
EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -100, 100, EEG.xmin, EEG.xmax, 0, 0);
if any(EEG.reject.rejthresh)
    EEG = pop_rejepoch(EEG, EEG.reject.rejthresh, 0);
end
EEG.setname = 'D1 epochs clean nolp';

% --- Lesson steps -------------------------------------------------------------------------
t0 = tic;
EEG = pop_iclabel(EEG, 'default');
brainProb = EEG.etc.ic_classification.ICLabel.classifications(:, 1);
[~, order] = sort(brainProb, 'descend');
comps = sort(order(1:4))';
EEG = pop_subcomp(EEG, comps, 0, 1);
EEG.setname = 'D1 sift';
EEG = pop_pre_prepData(EEG, 'nogui', ...
    'SignalType', {'Components'}, ...
    'Detrend', {'method', {'linear'}}, ...
    'NormalizeData', {'method', {'time', 'ensemble'}});
EEG = pop_est_selModelOrder(EEG, 'nogui', ...
    'modelingApproach', {'Segmentation VAR', 'algorithm', {'ARfit'}, ...
                         'winlen', 0.5, 'winstep', 0.03}, ...
    'morderRange', [1 15]);
modelOrder = ceil(mean(EEG.CAT.IC.hq.pelbow));
M = numel(comps);
ratio = (M^2 * modelOrder) / (0.5 * EEG.srate * EEG.trials);
tOrder = toc(t0);
EEG = pop_est_fitMVAR(EEG, 'nogui', ...
    EEG.CAT.configs.est_selModelOrder.modelingApproach, ...
    'ModelOrder', modelOrder);
validLog = evalc('EEG = pop_est_validateMVAR(EEG, ''nogui'');');
EEG = pop_est_mvarConnectivity(EEG, 'nogui', ...
    'connmethods', {'dDTF08'}, 'freqs', 2:30);
siftSeconds = toc(t0);
pop_saveset(EEG, 'filename', 'D1_sift.set', 'filepath', cfg.work);

fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nepochs %d | components used %s (Brain p %s)\n', cfg.stamp, EEG.trials, num2str(comps), ...
    num2str(brainProb(comps)', '%.2f '));
fprintf(fid, 'model order %d | parameters/datapoints %.3f\n', modelOrder, ratio);
fprintf(fid, 'time: order selection %.0f s | all SIFT steps %.0f s\n', tOrder, siftSeconds);
fprintf(fid, 'validation output:\n%s\n', strtrim(validLog));
fclose(fid);
type(fullfile(out, 'facts.txt'));

