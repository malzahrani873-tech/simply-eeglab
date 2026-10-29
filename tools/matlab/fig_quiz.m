function fig_quiz(ids)
% FIG_QUIZ  Images of the station quizzes that come from MATLAB (quizzes/notes.md section 4).
%   fig_quiz                    every image below
%   fig_quiz({'s03-q04'})       only the listed images
% Each image is written at the exact quiz size to assets-src/quiz/NN/<id>.png, ready for
% draw_quiz.py --convert. No image carries text that gives the answer away (no peak markers, no
% before/after wording, no design names). One image serves both languages.
%
%   id        size      needs                          content
%   s00-q06   720x360   -                              simulated signal spectrum, rng(0)
%   s02-q04   640x640   D2 + Biosig                    Plot > Channel locations > By name, no arrows
%   s03-q03   720x480   D1                             channel spectra of D1 hp0.1, 1-64 Hz, no maps
%   s03-q04   720x480   D1                             scroll of 6 channels, P4 zeroed in a copy
%   s05-q04   720x360   D1 epochs (sea_epochs)         panel 1 after baseline, panel 2 before
%   s05-q05   720x420   D1 hp0.1 notch60 epochs        4 epochs, the one over +/-100 uV in place 3
%   s06-q01   720x400   D1 epochs clean                Pz ERP, positive up, no peak marker
%   s06-q04   720x520   D1 main clean (sea_clean)      power-spectrum lesson figure at quiz size
%   s07-q01   720x360   D1 epochs clean                maps at 0 and 400 ms, each on its own scale
%   s07-q02   720x400   D1 epochs clean                channel-erp-plot "before" figure at quiz size
%   s08-q05   720x400   animal_mine.study (st8)        group ERP at Pz, design 2, no maps
% Errors in one image are reported at the end and do not stop the others.
% The two main-window screenshots (s01-q02, s02-q03) are taken by hand: see assets_plan_2.md.

all = {'s00-q06', 's02-q04', 's03-q03', 's03-q04', 's05-q04', 's05-q05', 's06-q01', 's06-q04', ...
    's07-q01', 's07-q02', 's08-q05'};
if nargin < 1 || isempty(ids), ids = all; end
if ischar(ids), ids = {ids}; end
unknown = setdiff(ids, all);
assert(isempty(unknown), 'Unknown quiz image: %s', strjoin(unknown, ', '));

cfg = sea_init();
failed = {};
for k = 1:numel(ids)
    id = ids{k};
    try
        info = feval(['q_' strrep(id, '-', '_')], cfg, id);
        fid = fopen(fullfile(cfg.out, 'quiz', id(2:3), [id '.txt']), 'w');
        fprintf(fid, '%s\n%s\n', cfg.stamp, info);
        fclose(fid);
        fprintf('[sea] %s: %s\n', id, info);
    catch err
        failed{end + 1} = sprintf('%s: %s', id, err.message); %#ok<AGROW>
        close all
    end
end
if ~isempty(failed)
    error('sea:quiz', 'Quiz images not written:\n%s', strjoin(failed, newline));
end
end

% --- helpers ---------------------------------------------------------------------------

function file = save_quiz(fig, cfg, id, sizepx)
file = sea_export(fig, cfg, fullfile('quiz', id(2:3), [id '.png']), sizepx);
end

function EEG = d1_hp_notch(cfg)
% 'D1 hp0.1 notch60': the first two steps of sea_main, before the average reference
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.notch(1), 'hicutoff', cfg.notch(2), 'revfilt', 1);
EEG.setname = 'D1 hp0.1 notch60';
end

function idx = chan(EEG, name)
idx = find(strcmpi({EEG.chanlocs.labels}, name));
assert(numel(idx) == 1, 'Channel %s not found', name);
end

% --- images ----------------------------------------------------------------------------

function info = q_s00_q06(cfg, id)
% The signal-basics lesson signal at 250 Hz with a 60 Hz wave added, amplitude spectrum to 70 Hz
srate = 250;
t = (0:10*srate-1) / srate;
rng(0);
sig = 20*sin(2*pi*10*t) + 8*sin(2*pi*6*t) + 10*sin(2*pi*60*t) + 5*randn(size(t));
n = numel(sig);
amp = abs(fft(sig)) / n * 2;
freqs = (0:n-1) * srate / n;
keep = freqs <= 70;
fig = figure;
ax = axes('Position', [0.09 0.16 0.88 0.78]);
plot(ax, freqs(keep), amp(keep), 'k', 'LineWidth', 1);
set(ax, 'XLim', [0 70], 'Box', 'off');
xlabel(ax, 'Frequency (Hz)'); ylabel(ax, 'Amplitude (\muV)');
save_quiz(fig, cfg, id, [720 360]);
[~, i10] = max(amp .* (freqs >= 8 & freqs <= 12));
[~, i60] = min(abs(freqs - 60));
info = sprintf('peak %.1f Hz, %.1f uV; 60 Hz %.1f uV', freqs(i10), amp(i10), amp(i60));
end

function info = q_s02_q04(cfg, id)
% Same steps as fig_channel_locations.m, exported at the quiz size
assert(exist(cfg.d2, 'file') == 2, 'File not found: %s', cfg.d2);
EEG = pop_biosig(cfg.d2);
for iChan = 1:EEG.nbchan
    EEG.chanlocs(iChan).labels = strrep(EEG.chanlocs(iChan).labels, '.', '');
end
EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');
EEG = eeg_checkset(EEG);
figure;
topoplot([], EEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
save_quiz(gcf, cfg, id, [640 640]);
[~, ~, th, rd] = readlocs(EEG.chanlocs); %#ok<ASGLU>
out = {EEG.chanlocs(rd >= 0.5).labels};
info = sprintf('%d channels; on or outside the circle: %s', EEG.nbchan, strjoin(out, ' '));
end

function info = q_s03_q03(cfg, id)
% Line-noise lesson "before" plot (D1 hp0.1), with the maps field empty
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
EEG.setname = 'D1 hp0.1';
figure;
pop_spectopo(EEG, 1, [0 EEG.xmax * 1000], 'EEG', 'freqrange', [1 64], 'electrodes', 'off');
save_quiz(gcf, cfg, id, [720 480]);
pk = sea_db(EEG, 60) - mean(sea_db(EEG, [56 57 63 64]));
info = sprintf('60 Hz peak %.1f dB above its neighbours', pk);
end

function info = q_s03_q04(cfg, id)
% Exercise copy of D1 hp0.1 notch60 with P4 set to zero; 10 s holding two or three blinks
EEG = d1_hp_notch(cfg);
EEG.data(chan(EEG, 'P4'), :) = 0;
fpz = EEG.data(chan(EEG, 'FPz'), :);
hit = abs(fpz - median(fpz)) > 6 * median(abs(fpz - median(fpz)));
on = find(diff([0 hit]) == 1);
on = on([true diff(on) > EEG.srate / 2]);          % one onset per blink
blinks = on / EEG.srate;
t0 = [];
for s = 0:floor(EEG.xmax) - 10
    nb = nnz(blinks >= s + 0.5 & blinks < s + 9.5);
    if nb >= 2 && nb <= 3, t0 = s; break; end
end
assert(~isempty(t0), 'No 10-s window with two or three blinks');
fig = sea_scroll(EEG, {'FPz', 'EOG1', 'Fz', 'Cz', 'P4', 'Oz'}, t0, 10, 80);
annotation(fig, 'textbox', [0 0 1 0.05], 'String', 'Simulated flat channel for this quiz', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', [0.35 0.35 0.35]);
save_quiz(fig, cfg, id, [720 480]);
info = sprintf('window %d-%d s, %d blinks in FPz', t0, t0 + 10, nnz(blinks >= t0 & blinks < t0 + 10));
end

function info = q_s05_q04(cfg, id)
% Baseline-correction lesson data in one figure: panel 1 = after, panel 2 = before
ep = sea_epochs(cfg);
pz = chan(ep.raw, 'Pz');
n = min(20, ep.raw.trials);
x = {squeeze(ep.bl.data(pz, :, 1:n)), squeeze(ep.raw.data(pz, :, 1:n))};
fig = figure;
for p = 1:2
    ax = axes('Position', [0.08 + (p - 1) * 0.47 0.15 0.42 0.74]);
    hold(ax, 'on');
    patch(ax, [-200 0 0 -200], [-40 -40 40 40], [0.88 0.88 0.88], 'EdgeColor', 'none');
    plot(ax, ep.raw.times, x{p}, 'Color', [0.45 0.45 0.45], 'LineWidth', 0.5);
    xline(ax, 0, ':'); yline(ax, 0, 'k');
    set(ax, 'XLim', ep.raw.times([1 end]), 'YLim', [-40 40], 'Box', 'off', 'Layer', 'top');
    title(ax, num2str(p), 'FontSize', 12);
    xlabel(ax, 'Time (ms)');
    if p == 1, ylabel(ax, 'Amplitude (\muV)'); end
end
save_quiz(fig, cfg, id, [720 360]);
bl = ep.raw.times >= -200 & ep.raw.times <= 0;
info = sprintf('%d epochs; baseline means: panel 1 max %.2g uV, panel 2 %.1f to %.1f uV', n, ...
    max(abs(mean(x{1}(bl, :), 1))), min(mean(x{2}(bl, :), 1)), max(mean(x{2}(bl, :), 1)));
end

function info = q_s05_q05(cfg, id)
% Epochs before ICA, baseline -200 to 0; four in a row with only the third over +/-100 uV
EEG = d1_hp_notch(cfg);
EEG = pop_epoch(EEG, {'square'}, [-1 2], 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);
over = squeeze(any(abs(EEG.data) > 100, [1 2]))';             % the lesson's test, all channels
shown = [chan(EEG, 'FPz') chan(EEG, 'EOG1') chan(EEG, 'Fz') chan(EEG, 'Cz')];
front = squeeze(any(abs(EEG.data(shown(1:2), :, :)) > 100, [1 2]))';
k0 = find(~over(1:end-3) & ~over(2:end-2) & over(3:end-1) & front(3:end-1) & ~over(4:end), 1);
assert(~isempty(k0), 'No four epochs with only the third over threshold');
sel = k0:k0 + 3;
lim = max(150, ceil(max(abs(EEG.data(shown, :, sel)), [], 'all') / 50) * 50);
names = {EEG.chanlocs(shown).labels};
fig = figure;
for r = 1:4
    for c = 1:4
        ax = axes('Position', [0.10 + (c - 1) * 0.225 0.10 + (4 - r) * 0.205 0.205 0.18]);
        hold(ax, 'on');
        yline(ax, -100, '--', 'Color', [0.4 0.4 0.4]);
        yline(ax, 100, '--', 'Color', [0.4 0.4 0.4]);
        plot(ax, EEG.times, EEG.data(shown(r), :, sel(c)), 'k', 'LineWidth', 0.8);
        set(ax, 'XLim', EEG.times([1 end]), 'YLim', [-lim lim], 'Box', 'off', 'XTick', [], 'YTick', []);
        if c == 1
            ylabel(ax, names{r}, 'Rotation', 0, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
            set(ax, 'YTick', [-100 0 100]);
        end
        if r == 1, title(ax, num2str(c), 'FontSize', 12); end
        if r == 4, set(ax, 'XTick', [-1000 0 1000]); xlabel(ax, 'Time (ms)'); end
    end
end
save_quiz(fig, cfg, id, [720 420]);
info = sprintf('epochs %d to %d of %d; over +/-100 uV: %s', sel(1), sel(end), EEG.trials, mat2str(over(sel)));
end

function info = q_s06_q01(cfg, id)
ep = sea_epochs(cfg);
EEG = ep.clean;
erp = mean(EEG.data(chan(EEG, 'Pz'), :, :), 3);
fig = figure;
ax = axes('Position', [0.10 0.15 0.86 0.80]);
hold(ax, 'on');
xline(ax, 0, '--', 'Color', [0.4 0.4 0.4]); yline(ax, 0, 'Color', [0.4 0.4 0.4]);
plot(ax, EEG.times, erp, 'k', 'LineWidth', 1.5);
set(ax, 'XLim', [-200 800], 'XTick', -200:200:800, 'Box', 'off');
xlabel(ax, 'Time (ms)'); ylabel(ax, 'Amplitude (\muV)');
save_quiz(fig, cfg, id, [720 400]);
win = EEG.times >= 0 & EEG.times <= 800;
tw = EEG.times(win); [pk, i] = max(erp(win));
info = sprintf('%d epochs; largest positive peak %.1f uV at %g ms', EEG.trials, pk, tw(i));
end

function info = q_s06_q04(cfg, id)
% Same call as fig_power_spectrum.m, exported at the quiz size
EEG = sea_clean(cfg);
figure;
pop_spectopo(EEG, 1, [0 EEG.xmax * 1000], 'EEG', 'freq', 10, 'freqrange', [1 64], 'electrodes', 'off');
colormap(cfg.colormap);
save_quiz(gcf, cfg, id, [720 520]);
info = 'D1 main clean, 1-64 Hz, map at 10 Hz';
end

function info = q_s07_q01(cfg, id)
% Maps at 0 and 400 ms, each with 'maplimits' 'maxmin' and its own color bar, no titles
ep = sea_epochs(cfg);
EEG = pop_select(ep.clean, 'rmchannel', cfg.d1_eog);
erp = mean(EEG.data, 3);
lat = [0 400];
fig = figure;
lims = zeros(2, 1);
for k = 1:2
    [~, i] = min(abs(EEG.times - lat(k)));
    subplot(1, 2, k);
    topoplot(erp(:, i), EEG.chanlocs, 'maplimits', 'maxmin', 'colormap', cfg.colormap);
    cb = colorbar; cb.Label.String = '\muV';
    lims(k) = max(abs(erp(:, i)));
end
save_quiz(fig, cfg, id, [720 360]);
info = sprintf('largest |value| at 0 ms %.2f uV, at 400 ms %.2f uV', lims(1), lims(2));
end

function info = q_s07_q02(cfg, id)
% The "before" figure of fig_channel_erp_plot.m at the quiz size
ep = sea_epochs(cfg);
EEG = ep.clean;
pos = eeg_getepochevent(EEG, 'type', {'square'}, 'timewin', [-5 5], 'fieldname', 'position');
c = chan(EEG, 'Pz');
erp1 = mean(EEG.data(c, :, pos == 1), 3);
erp2 = mean(EEG.data(c, :, pos == 2), 3);
win = EEG.times >= -200 & EEG.times <= 800;
yl = [min([erp1(win) erp2(win)]) max([erp1(win) erp2(win)])];
yl = yl + [-0.1 0.1] * diff(yl);
fig = figure;
ax = axes('Position', [0.10 0.13 0.86 0.78]); hold(ax, 'on');
plot(ax, EEG.times, erp1, 'LineWidth', 1.5);
plot(ax, EEG.times, erp2, 'LineWidth', 1.5);
xlim(ax, [-200 800]); ylim(ax, yl);
set(ax, 'YDir', 'reverse');
save_quiz(fig, cfg, id, [720 400]);
info = sprintf('position 1: %d trials, position 2: %d trials', nnz(pos == 1), nnz(pos == 2));
end

function info = q_s08_q05(cfg, id)
% Left plot of fig_study_plot_channels.m alone: Pz, design 2, conditions together, groups apart
hit = dir(fullfile(cfg.course_dir, '**', 'animal_mine.study'));
assert(~isempty(hit), 'animal_mine.study not found under %s. Run verify_batch(''st8'') first.', cfg.course_dir);
[STUDY, ALLEEG] = pop_loadstudy('filename', 'animal_mine.study', 'filepath', hit(1).folder);
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name', 'image x gender', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'group', 'values2', {'F', 'M'}, 'vartype2', 'categorical');
STUDY = std_selectdesign(STUDY, ALLEEG, 2);
names = {STUDY.changrp.name};
pz = names(strcmpi(names, 'Pz'));
STUDY = pop_erpparams(STUDY, 'plotconditions', 'together', 'plotgroups', 'apart', 'topotime', []);
STUDY = pop_statparams(STUDY, 'condstats', 'off', 'groupstats', 'off');
std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 2);
fig = gcf;
for h = findall(fig, 'Type', 'text')'
    s = lower(strjoin(cellstr(h.String), ' '));
    if contains(s, 'image x gender') || contains(s, 'design'), delete(h); end   % no text naming the design
end
save_quiz(fig, cfg, id, [720 400]);
info = sprintf('%s | %d datasets', STUDY.name, numel(ALLEEG));
end
