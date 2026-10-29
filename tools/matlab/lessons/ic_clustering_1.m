% Copied from lessons/en/08-09-ic-clustering.md. The lesson is the reference.
% STUDY and ALLEEG come from the starting point script (ICA, dipoles and ICLabel present)
STUDY = std_selectdesign(STUDY, ALLEEG, 3);   % a design that holds every dataset

% 1. Keep components whose dipole explains the map well (residual variance below 15%)
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'commands', {'inbrain', 'on', 'dipselect', 0.15});
nComps = cellfun(@numel, {STUDY.datasetinfo.comps});
fprintf('Components kept per dataset: median %g, range %d to %d\n', median(nComps), min(nComps), max(nComps));

% 2. Component measures: scalp maps for clustering, spectra and ERPs for reading the clusters
baseline = [round(ALLEEG(1).xmin*1000) 0];
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, 'components', 'savetrials', 'on', 'recompute', 'on', ...
    'scalp', 'on', 'spec', 'on', 'specparams', {'specmode', 'fft', 'logtrials', 'off'}, ...
    'erp', 'on', 'erpparams', {'rmbase', baseline});

% 3. Preclustering on location only: dipole positions (weight 10) and scalp maps (3 PCA dimensions)
[STUDY, ALLEEG] = std_preclust(STUDY, ALLEEG, 1, {'dipoles', 'weight', 10}, ...
    {'scalp', 'npca', 3, 'weight', 1, 'abso', 1});

% 4. k-means with outliers; fixed seed so the clusters are the same on every run
rng(1);
if exist('kmeans', 'file'), alg = 'kmeans'; else, alg = 'kmeanscluster'; end
nClust = ceil(mean(nComps));
STUDY = pop_clust(STUDY, ALLEEG, 'algorithm', alg, 'clus_num', nClust, 'outliers', 3);

% 5. Size, participants and ICLabel brain probability of each cluster
best = 0; bestN = 0;
for c = 2:numel(STUDY.cluster)
    cl = STUDY.cluster(c);
    if strncmpi(cl.name, 'outlier', 7) || isempty(cl.comps), continue; end
    sets = cl.sets(1, :);
    brain = zeros(1, numel(sets));
    for m = 1:numel(sets)
        brain(m) = ALLEEG(sets(m)).etc.ic_classification.ICLabel.classifications(cl.comps(m), 1);
    end
    nSubj = numel(unique({STUDY.datasetinfo(sets).subject}));
    fprintf('%-10s %3d ICs from %2d participants, median brain probability %.2f\n', ...
        cl.name, numel(cl.comps), nSubj, median(brain));
    if nSubj > bestN, best = c; bestN = nSubj; end
end

% 6. Maps and dipoles of the cluster with the most participants, then save
STUDY = std_topoplot(STUDY, ALLEEG, 'clusters', best, 'mode', 'apart');
STUDY = std_dipplot(STUDY, ALLEEG, 'clusters', best);
STUDY = pop_savestudy(STUDY, ALLEEG, 'savemode', 'resave');
