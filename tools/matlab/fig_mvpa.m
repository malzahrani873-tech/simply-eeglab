% FIG_MVPA  Figure for lesson mvpa (ERP CORE N170 participant 2, faces vs cars).
%   Run verify_batch('mvpa') first: it runs the lesson code and saves N170_sub2_faces_cars.mvpc in
%   <cfg.work>/mvpa. This script reads that file, so the figure shows exactly the checked result.
%
% Output:
%   assets-src/lessons/mvpa/mvpa-accuracy.png   accuracy over time, chance line, zero line (900 x 520)
%   assets-src/lessons/mvpa/facts.txt           trials per bin, chance, peak accuracy and latency
% The lesson image is a screenshot of ERPLAB > MVPC Tools > Plot MVPC Results. This script opens that
% window at the end; take the screenshot there (run_checklist). The PNG above is the fallback.

cfg = sea_init();
work = fullfile(cfg.work, 'mvpa');
file = fullfile(work, 'N170_sub2_faces_cars.mvpc');
assert(exist(file, 'file') == 2, 'Run verify_batch(''mvpa'') first: %s not found.', file);

% .mvpc files are MAT files holding the MVPC structure
S = load(file, '-mat');
MVPC = S.MVPC;

post = MVPC.times > 0;
postTimes = MVPC.times(post);
[peakAcc, iPeak] = max(MVPC.average_score(post));
preMean = mean(MVPC.average_score(MVPC.times < 0));

% --- Accuracy curve, same elements as the lesson figure ---------------------------------
fig = figure('Color', 'w');
plot(MVPC.times, MVPC.average_score, 'LineWidth', 1.5); hold on;
yline(MVPC.chance, '--');
xline(0, ':');
xlim([-200 800]); ylim([0 1]);
xlabel('Time (ms)'); ylabel('Proportion correct');
title('ERP CORE N170, participant 2: faces vs cars');
rel = fullfile('lessons', 'mvpa');
sea_export(fig, cfg, fullfile(rel, 'mvpa-accuracy.png'), [900 520]);

% --- Facts --------------------------------------------------------------------------------
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nsource      : %s\nchance      : %.2f\nunit        : %s\n', cfg.stamp, file, MVPC.chance, MVPC.DecodingUnit);
fprintf(fid, 'pre-zero    : %.3f (mean accuracy before 0 ms)\npeak        : %.3f at %d ms\n', ...
    preMean, peakAcc, round(postTimes(iPeak)));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

% --- ERPLAB window for the screenshot ------------------------------------------------------
% Same call as the menu ERPLAB > Multivariate Pattern Classification (MVPC) Tools > Plot MVPC Results
ALLMVPC = MVPC;
mvpcviewerGUI(ALLMVPC);
fprintf('[sea] Plot MVPC Results is open: take the screenshot mvpa-accuracy-erplab.png (run_checklist).\n');
