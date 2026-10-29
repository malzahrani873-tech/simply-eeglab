% Copied from lessons/en/08-07-study-statistics.md. The lesson is the reference.
% STUDY and ALLEEG come from the starting point script
names = {STUDY.changrp.name};
pz = names(strcmpi(names, 'Pz'));
STUDY = pop_erpparams(STUDY, 'plotconditions', 'together', 'plotgroups', 'apart', ...
    'timerange', [], 'topotime', []);

% Paired test of image category at Pz (design 3), without and with FDR correction
STUDY = pop_statparams(STUDY, 'condstats', 'on', 'groupstats', 'off', 'mode', 'eeglab', ...
    'method', 'param', 'alpha', 0.05, 'mcorrect', 'none');
[STUDY, ~, erptimes, ~, maskRaw] = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 3, 'noplot', 'on');
STUDY = pop_statparams(STUDY, 'mcorrect', 'fdr');
[STUDY, ~, erptimes, ~, maskFdr] = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 3);
fprintf('Significant time points at Pz: %d uncorrected, %d after FDR (of %d)\n', ...
    nnz(maskRaw{1}), nnz(maskFdr{1}), numel(erptimes));
sigTimes = erptimes(maskFdr{1} > 0);
if ~isempty(sigTimes)
    fprintf('First and last significant time after FDR: %g and %g ms\n', sigTimes(1), sigTimes(end));
end

% Window fixed before looking at the data: mean of 150-250 ms at every channel, FDR across channels
STUDY = pop_erpparams(STUDY, 'topotime', [150 250]);
[STUDY, ~, ~, ~, maskMap] = std_erpplot(STUDY, ALLEEG, 'channels', names, 'design', 3);
fprintf('Channels with a significant 150-250 ms difference after FDR: %s\n', strjoin(names(maskMap{1} > 0), ' '));
STUDY = pop_erpparams(STUDY, 'topotime', []);

% Cluster correction over time at Pz (requires the Fieldtrip-lite plugin)
if exist('ft_freqstatistics', 'file')
    STUDY = pop_statparams(STUDY, 'mode', 'fieldtrip', 'fieldtripmethod', 'montecarlo', ...
        'fieldtripmcorrect', 'cluster', 'fieldtripalpha', 0.05, 'fieldtripnaccu', 2000);
    [STUDY, ~, ~, ~, maskClust] = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 3);
    fprintf('Significant time points at Pz after cluster correction: %d\n', nnz(maskClust{1}));
    STUDY = pop_statparams(STUDY, 'mode', 'eeglab');
else
    disp('Fieldtrip-lite is not installed: use File > Manage EEGLAB extensions');
end

% 2 x 2 mixed design at Pz (design 2): picture, gender and their interaction
STUDY = pop_statparams(STUDY, 'groupstats', 'on', 'mcorrect', 'fdr');
[STUDY, ~, ~, ~, ~, pinter] = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 2);
fprintf('Interaction time points after FDR: %d\n', nnz(pinter{3}));

% Back to the image category test only
STUDY = pop_statparams(STUDY, 'groupstats', 'off');
