% FIG_STUDY_STATISTICS  Figure for lesson study-statistics (08-07), Go-nogo STUDY (D6).
%   Run verify_batch('st8') first: create-study saves animal_mine.study and study-precompute writes the
%   precomputed ERPs. This script loads that STUDY, rebuilds designs 2 and 3 as in the lesson's Starting
%   point, and draws the two statistics plots of the lesson (paired test, FDR) with std_erpplot.
%
% Output in assets-src/lessons/study-statistics/:
%   study-statistics.png      left: group ERP at Pz, design 3, animal and distractor together, with the
%                             bars of the times that pass FDR; right: 150-250 ms maps and p-value map
%   study-stats-pz.png        the left plot alone (760 x 560 px)
%   study-stats-topo.png      the right plot alone (900 x 560 px)
%   facts.txt                 significant time points (uncorrected, FDR), first and last, channels

cfg = sea_init();
hit = dir(fullfile(cfg.course_dir, '**', 'animal_mine.study'));
assert(~isempty(hit), 'animal_mine.study not found under %s. Run verify_batch(''st8'') first.', cfg.course_dir);
[STUDY, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', hit(1).folder);
rel = fullfile('lessons', 'study-statistics');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end

% Designs 2 and 3, as in the Starting point of the lesson
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name', 'image x gender', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'group', 'values2', {'F', 'M'}, 'vartype2', 'categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name', 'image only', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'none');
STUDY = std_selectdesign(STUDY, ALLEEG, 2);
first = STUDY.datasetinfo(1);
assert(exist(fullfile(first.filepath, [first.subject '.daterp']), 'file') == 2, ...
    'No precomputed ERP for %s. Run verify_batch(''st8'') first.', first.subject);

names = {STUDY.changrp.name};
pz = names(strcmpi(names, 'Pz'));
STUDY = pop_erpparams(STUDY, 'plotconditions', 'together', 'plotgroups', 'apart', ...
    'timerange', [], 'topotime', []);

% Left: paired test at Pz (design 3), uncorrected count first, then the FDR plot
STUDY = pop_statparams(STUDY, 'condstats', 'on', 'groupstats', 'off', 'mode', 'eeglab', ...
    'method', 'param', 'alpha', 0.05, 'mcorrect', 'none');
[STUDY, ~, erptimes, ~, maskRaw] = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 3, 'noplot', 'on');
STUDY = pop_statparams(STUDY, 'mcorrect', 'fdr');
[STUDY, ~, erptimes, ~, maskFdr] = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 3);
fileL = sea_export(gcf, cfg, fullfile(rel, 'study-stats-pz.png'), [760 560]);

% Right: mean of 150-250 ms at every channel, FDR across channels
STUDY = pop_erpparams(STUDY, 'topotime', [150 250]);
[STUDY, ~, ~, ~, maskMap] = std_erpplot(STUDY, ALLEEG, 'channels', names, 'design', 3);
fileR = sea_export(gcf, cfg, fullfile(rel, 'study-stats-topo.png'), [900 560]);
STUDY = pop_erpparams(STUDY, 'topotime', []);

% One image, left and right
imwrite([imread(fileL) imread(fileR)], fullfile(out, 'study-statistics.png'));

sigTimes = erptimes(maskFdr{1} > 0);
fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nSTUDY %s | design 3 | %d subjects\n', cfg.stamp, STUDY.name, numel(unique({STUDY.datasetinfo.subject})));
fprintf(fid, 'Pz significant time points: %d uncorrected, %d after FDR (of %d)\n', ...
    nnz(maskRaw{1}), nnz(maskFdr{1}), numel(erptimes));
if ~isempty(sigTimes)
    fprintf(fid, 'first and last significant time after FDR: %g and %g ms\n', sigTimes(1), sigTimes(end));
end
fprintf(fid, 'channels significant 150-250 ms after FDR: %s\n', strjoin(names(maskMap{1} > 0), ' '));
fclose(fid);
type(fullfile(out, 'facts.txt'));
