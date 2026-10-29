% FIG_DATA_QUALITY_SME  Figure for lesson data-quality-sme from Luck's chapter 10 data (ERP CORE,
%   CC BY-SA 4.0). aSME at C3, 200-300 ms window, bin 1, for each of the 40 participants: dots, a line
%   at the median and a dashed line at twice the median. Dots above the dashed line are in another
%   color with the participant number.
%
% Needs ERPLAB and <cfg.course_dir>/Chapter_10/Data/ERPsets (run_checklist 0.2). The ERPsets must hold
% aSME for a 200-300 ms window (checked by verify_batch, lesson data-quality-sme).
% Output in assets-src/lessons/data-quality-sme/:
%   data-quality-sme-c3-dots.png
%   facts.txt   median, RMS, participants above twice the median

cfg = sea_init();
assert(exist('pop_loaderp', 'file') == 2, 'sea:plugin', 'ERPLAB not found (File > Manage EEGLAB extensions).');
dataDir = fullfile(cfg.course_dir, 'Chapter_10', 'Data', 'ERPsets');
files = dir(fullfile(dataDir, '*.erp'));
assert(~isempty(files), 'sea:nodata', 'No .erp files in %s (run_checklist 0.2).', dataDir);
[~, ALLERP] = pop_loaderp('filename', {files.name}, 'filepath', dataDir, 'UpdateMainGui', 'off');
rel = fullfile('lessons', 'data-quality-sme');

c3 = find(strcmp({ALLERP(1).chanlocs.labels}, 'C3'));
n = numel(ALLERP);
sme = nan(n, 1);
for k = 1:n
    dq = ALLERP(k).dataquality;
    iA = find(strcmpi({dq.type}, 'aSME'));
    assert(~isempty(iA), 'sea:noasme', 'ERPset %d has no aSME values', k);
    tw = dq(iA).times;
    iW = find(tw(:, 1) == 200 & tw(:, 2) == 300);
    assert(~isempty(iW), 'sea:noasme', 'ERPset %d has no aSME window 200-300 ms', k);
    sme(k) = dq(iA).data(c3, iW, 1);
end
med = median(sme);
out = find(sme > 2 * med);

figure;
ax = axes('Units', 'normalized', 'Position', [0.08 0.13 0.9 0.82]);
hold(ax, 'on');
plot(ax, [0.5 n + 0.5], [med med], '-', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
plot(ax, [0.5 n + 0.5], 2 * [med med], '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
in = setdiff(1:n, out);
plot(ax, in, sme(in), 'o', 'MarkerFaceColor', [0 0.3 0.75], 'MarkerEdgeColor', 'none', 'MarkerSize', 6);
plot(ax, out, sme(out), 'o', 'MarkerFaceColor', [0.85 0.2 0.1], 'MarkerEdgeColor', 'none', 'MarkerSize', 7);
for k = out(:)'
    text(ax, k + 0.6, sme(k), sprintf('%d', k), 'Color', [0.85 0.2 0.1], 'FontSize', 9);
end
set(ax, 'XLim', [0.5 n + 0.5], 'XTick', [1 5:5:n], 'YLim', [0 max(sme) * 1.1], 'Box', 'off');
xlabel(ax, 'Participant'); ylabel(ax, 'aSME (\muV)');
sea_export(gcf, cfg, fullfile(rel, 'data-quality-sme-c3-dots.png'), [1000 480]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nERPsets: %d\naSME at C3, 200-300 ms, bin 1: median %.2f uV, RMS %.2f uV, range %.2f to %.2f\nabove twice the median: %s\n', ...
    cfg.stamp, n, med, sqrt(mean(sme .^ 2)), min(sme), max(sme), mat2str(out'));
fprintf(fid, 'Data: ERP CORE (Kappenman et al., 2021) via Luck (2022), chapter 10. Image licence CC BY-SA 4.0.\n');
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
