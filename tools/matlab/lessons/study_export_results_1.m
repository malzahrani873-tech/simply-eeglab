% Copied from lessons/en/08-08-study-export-results.md. The lesson is the reference.
% STUDY, ALLEEG and studyDir come from the starting point script
names = {STUDY.changrp.name};
chans = names(ismember(lower(names), {'fz', 'pz'}));
win = [150 250];   % window fixed before looking at the data (Thorpe et al., 1996)
d = 3;             % design 'image only': every participant appears in both conditions
subjects = STUDY.design(d).cases.value;
conds = STUDY.design(d).variable(1).value;

rows = {};
for c = 1:numel(chans)
    [STUDY, erp, times] = std_readdata(STUDY, ALLEEG, 'channels', chans(c), 'design', d, 'datatype', 'erp');
    inWin = times >= win(1) & times <= win(2);
    for k = 1:numel(conds)
        if size(erp{k}, 2) ~= numel(subjects)
            error('Condition %s does not hold every participant', conds{k});
        end
        amp = mean(erp{k}(inWin, :), 1);   % one mean amplitude per participant
        for s = 1:numel(subjects)
            info = STUDY.datasetinfo(strcmp({STUDY.datasetinfo.subject}, subjects{s}));
            rows(end+1, :) = {subjects{s}, info(1).group, conds{k}, chans{c}, double(amp(s))};
        end
    end
end

% Long format: one row per participant, condition and channel
T = cell2table(rows, 'VariableNames', {'subject', 'gender', 'condition', 'channel', 'mean_uV'});
csvFile = fullfile(studyDir, 'erp_150_250_mean.csv');
writetable(T, csvFile);
fprintf('%d rows written to %s\n', height(T), csvFile);
disp(T(1:4, :));

% Check: the group mean at Pz for each condition, to compare with the plot
for k = 1:numel(conds)
    sel = strcmpi(T.channel, 'Pz') & strcmp(T.condition, conds{k});
    fprintf('Pz %s: mean %.2f uV over %d participants\n', conds{k}, mean(T.mean_uV(sel)), nnz(sel));
end
