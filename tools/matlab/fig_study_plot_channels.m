% FIG_STUDY_PLOT_CHANNELS  Figure for lesson study-plot-channels (08-06), ready Go-nogo STUDY (D6).
%   Run verify_batch('st8') first: create-study saves animal_mine.study and study-precompute writes the
%   precomputed ERPs next to each dataset. This script loads that STUDY, rebuilds designs 2 and 3 as in
%   the lesson's Starting point, and draws the two plots of the lesson with std_erpplot.
%
% Output in assets-src/lessons/study-plot-channels/:
%   study-plot-channels.png   left: group ERP at Pz, design 2 (conditions together, one panel per gender);
%                             right: scalp maps of the 150-250 ms mean, design 3 (animal, distractor)
%   study-erp-pz.png          the left plot alone (760 x 560 px)
%   study-topo-150-250.png    the right plot alone (760 x 560 px)
%   facts.txt                 STUDY name, datasets, subjects per group, design names

cfg = sea_init();
hit = dir(fullfile(cfg.course_dir, '**', 'animal_mine.study'));
assert(~isempty(hit), 'animal_mine.study not found under %s. Run verify_batch(''st8'') first.', cfg.course_dir);
[STUDY, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', hit(1).folder);
rel = fullfile('lessons', 'study-plot-channels');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end
sizepx = [760 560];

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

% Left: group ERP at Pz, both pictures on one panel, one panel per gender (design 2)
STUDY = pop_erpparams(STUDY, 'plotconditions', 'together', 'plotgroups', 'apart', 'topotime', []);
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 2);
fileL = sea_export(gcf, cfg, fullfile(rel, 'study-erp-pz.png'), sizepx);

% Right: scalp maps of the mean ERP from 150 to 250 ms (design 3)
STUDY = pop_erpparams(STUDY, 'topotime', [150 250]);
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', names, 'design', 3);
fileR = sea_export(gcf, cfg, fullfile(rel, 'study-topo-150-250.png'), sizepx);
STUDY = pop_erpparams(STUDY, 'topotime', []);

% One image, left and right
imwrite([imread(fileL) imread(fileR)], fullfile(out, 'study-plot-channels.png'));

subj = {STUDY.datasetinfo.subject};
grp = {STUDY.datasetinfo.group};
fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nSTUDY %s | %d datasets | %d subjects\n', cfg.stamp, STUDY.name, numel(ALLEEG), numel(unique(subj)));
fprintf(fid, 'subjects F: %d | M: %d\n', numel(unique(subj(strcmp(grp, 'F')))), numel(unique(subj(strcmp(grp, 'M')))));
fprintf(fid, 'designs: %s\nchannel for the ERP: %s\n', strjoin({STUDY.design.name}, ' | '), strjoin(pz, ', '));
fclose(fid);
type(fullfile(out, 'facts.txt'));
