% FIG_PUBLICATION_FIGURES  Before/after pair for lesson publication-figures (07-04), Pz of D1 epochs clean.
%
% Output in assets-src/lessons/publication-figures/ (both PNGs 1063 x 827 px = 9 x 7 cm at 300 dpi):
%   publication-before.png   a default MATLAB plot captured at screen size (560 x 420 px), shrunk to
%                            9 cm at screen resolution (96 dpi) and shown at the common frame without
%                            smoothing, so the jagged edges and small text are what the learner would get
%   publication-after.png    the lesson's figure 1 (9 x 7 cm, Arial 9 pt, 1.2 pt solid and dashed lines,
%                            unit on the vertical axis, trial counts) rendered from vector at 300 dpi
%   publication-after.pdf    the same figure as the vector PDF the lesson exports
%   facts.txt                trials per condition and the pixel sizes used

cfg = sea_init();
ep = sea_epochs(cfg);
EEG = ep.clean;
rel = fullfile('lessons', 'publication-figures');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end
frame = [1063 827];                    % 9 x 7 cm at 300 dpi
screenPx = [560 420];                  % MATLAB default figure size
shrinkPx = round([9 7] / 2.54 * 96);   % 9 x 7 cm at 96 dpi

pos = eeg_getepochevent(EEG, 'type', {'square'}, 'timewin', [-5 5], 'fieldname', 'position');
EEG_pos1 = pop_select(EEG, 'trial', find(pos == 1));
EEG_pos2 = pop_select(EEG, 'trial', find(pos == 2));
chan = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
erp1 = mean(EEG_pos1.data(chan, :, :), 3);
erp2 = mean(EEG_pos2.data(chan, :, :), 3);

% --- Before: default plot, no unit, no counts, captured from the screen -----------------
fig = figure('Color', 'w', 'Units', 'pixels', 'Position', [50 50 screenPx]);
plot(EEG.times, erp1); hold on;
plot(EEG.times, erp2);
xlim([-200 800]);
xlabel('Time (ms)'); ylabel('Potential');
legend({'Position 1', 'Position 2'});
title('Pz');
tmp = [tempname '.png'];
print(fig, tmp, '-dpng', '-r0');
close(fig);
img = imread(tmp); delete(tmp);
img = resizeNearest(img, shrinkPx);          % shrunk to 9 cm at screen resolution
img = resizeNearest(img, frame);             % shown at the common frame: every pixel becomes a block
imwrite(img, fullfile(out, 'publication-before.png'));

% --- After: the lesson's figure 1 --------------------------------------------------------
fig1 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 9 7]);
hold on;
plot(EEG.times, erp1, 'Color', [0 0.45 0.74], 'LineWidth', 1.2);
plot(EEG.times, erp2, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2, 'LineStyle', '--');
xline(0, 'k:'); yline(0, 'k-');
xlim([-200 800]);
set(gca, 'YDir', 'normal', 'FontName', 'Arial', 'FontSize', 9, 'TickDir', 'out', 'Box', 'off');
xlabel('Time (ms)'); ylabel('Potential (\muV)');
legend({sprintf('Position 1 (n = %d)', EEG_pos1.trials), ...
        sprintf('Position 2 (n = %d)', EEG_pos2.trials)}, 'Location', 'northeast', 'Box', 'off');
title('Pz', 'FontWeight', 'normal');
exportgraphics(fig1, fullfile(out, 'publication-after.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
set(fig1, 'PaperUnits', 'centimeters', 'PaperPosition', [0 0 9 7], 'PaperSize', [9 7], 'InvertHardcopy', 'off');
print(fig1, fullfile(out, 'publication-after.png'), '-dpng', '-r300');
close(fig1);
after = imread(fullfile(out, 'publication-after.png'));
if ~isequal([size(after, 2) size(after, 1)], frame)
    imwrite(resizeNearest(after, frame), fullfile(out, 'publication-after.png'));
end

fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nposition 1: %d epochs | position 2: %d epochs\n', cfg.stamp, EEG_pos1.trials, EEG_pos2.trials);
fprintf(fid, 'before: %d x %d screen capture -> %d x %d (9 cm at 96 dpi) -> %d x %d\n', screenPx, shrinkPx, frame);
fprintf(fid, 'after : 9 x 7 cm at 300 dpi = %d x %d (rendered %d x %d)\n', frame, size(after, 2), size(after, 1));
fclose(fid);
type(fullfile(out, 'facts.txt'));

function out = resizeNearest(img, sz)
% Nearest-neighbour resize to sz = [width height], without the Image Processing Toolbox.
r = max(1, min(size(img, 1), round(((1:sz(2)) - 0.5) * size(img, 1) / sz(2) + 0.5)));
c = max(1, min(size(img, 2), round(((1:sz(1)) - 0.5) * size(img, 2) / sz(1) + 0.5)));
out = img(r, c, :);
end
