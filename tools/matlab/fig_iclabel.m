% FIG_ICLABEL  Figures for lesson iclabel. Run fig_run_ica.m first (reads <cfg.work>/D1_main_ica.set).
% Steps as in the lesson: Label -> Flag (Muscle and Eye above 0.9) -> remove components -> 30 Hz low-pass.
%
% Output in assets-src/lessons/iclabel/:
%   iclabel-viewprops-20.png    first 20 components with their ICLabel class (Label components)
%   iclabel-eye-extended.png    extended properties of the clearest eye component
%   iclabel-before-after.png    5 s of FPz, EOG1, EOG2, F3, Fz, F4: before removal black, after red
%   iclabel-before.png          the same window before removal only  } a slider pair: same channels,
%   iclabel-after.png           the same window after removal only   } window, scale and pixel size
%   facts.txt                   ICLabel probabilities, blink confidence, flagged components, plot window
% Also saves <cfg.work>/D1_main_clean.set and D1_main_clean_lp30.set for the station 5 and 6 figures.

cfg = sea_init();
EEG = pop_loadset('filename', 'D1_main_ica.set', 'filepath', cfg.work);
rel = fullfile('lessons', 'iclabel');
if ~exist(fullfile(cfg.out, rel), 'dir'), mkdir(fullfile(cfg.out, rel)); end

% Tools > Classify components using ICLabel > Label components
EEG = pop_iclabel(EEG, 'default');
P = EEG.etc.ic_classification.ICLabel.classifications;     % components x 7
classes = EEG.etc.ic_classification.ICLabel.classes;

% --- Component grid with classes ----------------------------------------------------
pop_viewprops(EEG, 0, 1:min(20, size(P, 1)), {'freqrange', [2 60]}, {}, 1, 'ICLabel');
sea_export(gcf, cfg, fullfile(rel, 'iclabel-viewprops-20.png'), [1100 900]);

% --- Extended properties of the clearest eye component -------------------------------
[~, eyeIC] = max(P(:, 3));
pop_prop_extended(EEG, 0, eyeIC, NaN, {'freqrange', [1 60]}, {}, 1, 'ICLabel');
sea_export(gcf, cfg, fullfile(rel, 'iclabel-eye-extended.png'), [1100 760]);

% --- Tools > Classify components using ICLabel > Flag components as artifacts
%     dialog defaults: Muscle and Eye between 0.9 and 1
thresh = [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN];
EEG = pop_icflag(EEG, thresh);
rej = find(EEG.reject.gcompreject);

% Tools > Remove components from data, then the 30 Hz low-pass (as in the lesson)
EEGclean = pop_subcomp(EEG, rej, 0);
EEGclean.setname = 'D1 main clean';
pop_saveset(EEGclean, 'filename', 'D1_main_clean.set', 'filepath', cfg.work);   % read by sea_clean.m
EEGlp = pop_eegfiltnew(EEGclean, 'hicutoff', cfg.erp_lp);
EEGlp.setname = 'D1 main clean lp30';
pop_saveset(EEGlp, 'filename', 'D1_main_clean_lp30.set', 'filepath', cfg.work);

% --- Before/after: the 5-s window with the most blinks, in the style of the scroll overlay ----
% Compares the data right before and after removal (before the low-pass) to isolate its effect.
labels = {EEG.chanlocs.labels};
want = {'FPz', 'EOG1', 'EOG2', 'F3', 'Fz', 'F4'};
[ok, ch] = ismember(lower(want), lower(labels));
ch = ch(ok);
src = double(eeg_getdatact(EEG, 'component', eyeIC));
w = round(cfg.game.seconds * EEG.srate);
i0 = blink_window(src, EEG.srate, w);
idx = i0:(i0 + w - 1);
t = (idx - 1) / EEG.srate;
seg = double(EEG.data(ch, idx));
gap = 1.1 * max(max(seg, [], 2) - min(seg, [], 2));
before = double(EEG.data(ch, idx));
after  = double(EEGclean.data(ch, idx));
yl = [-(numel(ch) - 1) * gap - gap, gap];
plot_rows(t, {before, after}, {'k', 'r'}, labels(ch), gap, yl, {'Before', 'After'});
sea_export(gcf, cfg, fullfile(rel, 'iclabel-before-after.png'), [1000 520]);
% Slider pair: identical axes position, limits, ticks and pixel size; only the trace changes.
plot_rows(t, {before}, {'k'}, labels(ch), gap, yl, {});
sea_export(gcf, cfg, fullfile(rel, 'iclabel-before.png'), [1000 520]);
plot_rows(t, {after}, {'r'}, labels(ch), gap, yl, {});
sea_export(gcf, cfg, fullfile(rel, 'iclabel-after.png'), [1000 520]);

% --- Facts ----------------------------------------------------------------------------
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nclasses: %s\n', cfg.stamp, strjoin(classes, ' | '));
for k = 1:min(20, size(P, 1))
    [p, c] = max(P(k, :));
    fprintf(fid, 'IC%02d  %-14s %.2f\n', k, classes{c}, p);
end
fprintf(fid, 'blink IC: %d  Eye %.1f%%\nflagged (Muscle/Eye > 0.9): %s\nplot channels: %s\nwindow: %.2f-%.2f s\n', ...
    eyeIC, 100 * P(eyeIC, 3), mat2str(rej(:)'), strjoin(labels(ch), ' '), t(1), t(end));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));

function plot_rows(t, sets, colors, names, gap, yl, legendText)
% One trace per channel, stacked with a fixed gap; fixed axes position so paired images align.
figure;
ax = axes('Units', 'normalized', 'Position', [0.08 0.12 0.9 0.78]);
hold(ax, 'on');
h = gobjects(1, numel(sets));
for s = 1:numel(sets)
    for c = 1:size(sets{s}, 1)
        h(s) = plot(ax, t, sets{s}(c, :) - (c - 1) * gap, 'Color', colors{s}, 'LineWidth', 0.8);
    end
end
set(ax, 'YTick', -(numel(names) - 1:-1:0) * gap, 'YTickLabel', fliplr(names), 'TickLength', [0 0], ...
    'Box', 'off', 'YLim', yl, 'XLim', [t(1) t(end)]);
xlabel(ax, 'Time (s)');
if ~isempty(legendText)
    legend(h, legendText, 'Location', 'north', 'Orientation', 'horizontal', 'Box', 'off');
end
end

function start = blink_window(src, srate, n)
% Start sample of the window of n samples holding the most blink peaks of the eye component.
% Peaks: local maxima (within +/-0.3 s) above half of the 99.9th percentile, sign set by skewness.
x = src * sign(mean(src .^ 3));
v = sort(x);
thr = 0.5 * v(max(1, round(0.999 * numel(v))));
pk = find(x > thr & x == movmax(x, 2 * floor(0.3 * srate) + 1));
edge = round(10 * srate);                      % skip the recording edges
pk = pk(pk > edge & pk < numel(x) - edge - n);
start = edge; best = -1;
for p = pk(:)'
    s0 = max(edge, p - round(srate));
    c = sum(pk >= s0 & pk < s0 + n);
    if c > best, best = c; start = s0; end
end
end
