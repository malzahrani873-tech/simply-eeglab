% Copied from lessons/en/10-02-sift.md. The lesson is the reference.
% Install SIFT from the extension manager if it is missing
plugin_askinstall('SIFT', 'pop_est_fitMVAR', true);

% Pick the four components with the highest Brain probability
EEG = pop_iclabel(EEG, 'default');
brainProb = EEG.etc.ic_classification.ICLabel.classifications(:, 1);
[~, order] = sort(brainProb, 'descend');
comps = sort(order(1:4))';
fprintf('Components used: %s\n', num2str(comps));

% Keep only these components in a copy of the data
EEG = pop_subcomp(EEG, comps, 0, 1);
EEG.setname = 'D1 sift';

% Pre-process: detrend and normalize each component
EEG = pop_pre_prepData(EEG, 'nogui', ...
    'SignalType', {'Components'}, ...
    'Detrend', {'method', {'linear'}}, ...
    'NormalizeData', {'method', {'time', 'ensemble'}});

% Model order selection over orders 1 to 15, 0.5 s sliding windows
EEG = pop_est_selModelOrder(EEG, 'nogui', ...
    'modelingApproach', {'Segmentation VAR', 'algorithm', {'ARfit'}, ...
                         'winlen', 0.5, 'winstep', 0.03}, ...
    'morderRange', [1 15]);
modelOrder = ceil(mean(EEG.CAT.IC.hq.pelbow));

% Data points per free parameter: aim for a ratio below 0.1
M = numel(comps);
ratio = (M^2 * modelOrder) / (0.5 * EEG.srate * EEG.trials);
fprintf('Model order %d, parameters/datapoints = %.3f\n', modelOrder, ratio);

% Fit the model, then validate it before reading any connectivity
EEG = pop_est_fitMVAR(EEG, 'nogui', ...
    EEG.CAT.configs.est_selModelOrder.modelingApproach, ...
    'ModelOrder', modelOrder);
EEG = pop_est_validateMVAR(EEG, 'nogui');

% Directed connectivity (dDTF08) from 2 to 30 Hz
EEG = pop_est_mvarConnectivity(EEG, 'nogui', ...
    'connmethods', {'dDTF08'}, 'freqs', 2:30);

% Time-frequency grid (opens the options window)
pop_vis_TimeFreqGrid(EEG);
