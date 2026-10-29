% FIG_IC_CLUSTERING  Figure for lesson ic-clustering (08-09), Go-nogo STUDY (D6).
%   Run verify_batch('st8') first: sea_d6_ica runs ICA with the fixed seed before the lesson, and the
%   lesson clusters the components (rng(1)) and saves the clusters in animal_mine.study. This script
%   loads that STUDY, picks the cluster with the most participants as step 5 of the lesson does, and
%   draws its maps and dipoles.
%
% Output in assets-src/lessons/ic-clustering/:
%   ic-clustering.png         left: scalp maps of the cluster (mean map first); right: its dipoles
%   ic-cluster-maps.png       the left plot alone (900 x 700 px)
%   ic-cluster-dipoles.png    the right plot alone (700 x 700 px)
%   facts.txt                 every cluster: ICs, participants, median ICLabel brain probability

cfg = sea_init();
hit = dir(fullfile(cfg.course_dir, '**', 'animal_mine.study'));
assert(~isempty(hit), 'animal_mine.study not found under %s. Run verify_batch(''st8'') first.', cfg.course_dir);
[STUDY, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', hit(1).folder);
assert(numel(STUDY.cluster) > 1, 'No component clusters in %s. Run verify_batch(''st8'') first.', STUDY.filename);
rel = fullfile('lessons', 'ic-clustering');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end

% Cluster with the most participants, outliers left out (step 5 of the lesson)
best = 0; bestN = 0;
rows = {};
for c = 2:numel(STUDY.cluster)
    cl = STUDY.cluster(c);
    if strncmpi(cl.name, 'outlier', 7) || isempty(cl.comps), continue; end
    sets = cl.sets(1, :);
    brain = zeros(1, numel(sets));
    for m = 1:numel(sets)
        brain(m) = ALLEEG(sets(m)).etc.ic_classification.ICLabel.classifications(cl.comps(m), 1);
    end
    nSubj = numel(unique({STUDY.datasetinfo(sets).subject}));
    rows{end+1} = sprintf('%-10s %3d ICs from %2d participants, median brain probability %.2f', ...
        cl.name, numel(cl.comps), nSubj, median(brain)); %#ok<SAGROW>
    if nSubj > bestN, best = c; bestN = nSubj; end
end
assert(best > 0, 'Only outlier clusters in %s.', STUDY.filename);

% Left: maps of every member, mean first; right: dipoles, members and mean
std_topoplot(STUDY, ALLEEG, 'clusters', best, 'mode', 'apart');
fileL = sea_export(gcf, cfg, fullfile(rel, 'ic-cluster-maps.png'), [900 700]);
std_dipplot(STUDY, ALLEEG, 'clusters', best);
fileR = sea_export(gcf, cfg, fullfile(rel, 'ic-cluster-dipoles.png'), [700 700]);

% One image, left and right
imwrite([imread(fileL) imread(fileR)], fullfile(out, 'ic-clustering.png'));

fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nSTUDY %s | %d clusters (parent included)\n', cfg.stamp, STUDY.name, numel(STUDY.cluster));
fprintf(fid, '%s\n', rows{:});
fprintf(fid, 'drawn: %s, %d participants\n', STUDY.cluster(best).name, bestN);
fclose(fid);
type(fullfile(out, 'facts.txt'));
