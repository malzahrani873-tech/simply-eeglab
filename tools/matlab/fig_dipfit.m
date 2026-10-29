% FIG_DIPFIT  Figures for lesson dipfit (10-01). Reads <cfg.work>/D1_main_ica.set (fig_run_ica.m or
%   sea_clean.m), the main dataset with the ICA weights (fixed seed), which is the lesson's Starting point.
%   DIPFIT ships with EEGLAB; the fit takes several minutes, so the script runs in the plugin batch.
%
% Output in assets-src/lessons/dipfit/:
%   dipfit-maps-12.png      Plot > Component maps > In 2-D for components 1-12 with their dipoles,
%                           residual variance in each title (1000 x 800 px)
%   dipfit-dipplot.png      dipplot of every fitted dipole on the template MRI: top, side and back views
%                           with the component list (dipplot 'summary' 'on', 1000 x 900 px)
%   facts.txt               coordinate transform, RV per component, components below 15% RV,
%                           the blink and posterior alpha candidates with their positions
%   <cfg.work>/D1_dipfit.set

cfg = sea_init();
if ~exist(fullfile(cfg.work, 'D1_main_ica.set'), 'file'), sea_clean(cfg); end
EEG = pop_loadset('filename', 'D1_main_ica.set', 'filepath', cfg.work);
EEG.setname = 'D1 dipfit';
rel = fullfile('lessons', 'dipfit');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end

% The lesson's steps: template electrodes, template BEM, fit every component
EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');
EEG = pop_dipfit_settings(EEG, 'model', 'standardBEM');
t0 = tic;
EEG = pop_multifit(EEG, [], 'threshold', 100);
fitSeconds = toc(t0);
EEG = pop_saveset(EEG, 'filename', 'D1_dipfit.set', 'filepath', cfg.work);
rv = 100 * [EEG.dipfit.model.rv];

% Component maps 1-12 with dipoles
pop_topoplot(EEG, 0, 1:12, EEG.setname, 0, 1);
sea_export(gcf, cfg, fullfile(rel, 'dipfit-maps-12.png'), [1000 800]);

% Every fitted dipole in three views
pop_dipplot(EEG, 1:numel(EEG.dipfit.model), 'normlen', 'on', 'summary', 'on', 'num', 'on');
sea_export(gcf, cfg, fullfile(rel, 'dipfit-dipplot.png'), [1000 900]);

% Blink and alpha candidates from ICLabel, to check their dipole positions
EEGl = pop_iclabel(EEG, 'default');
P = EEGl.etc.ic_classification.ICLabel.classifications;
[~, eyeIC] = max(P(:, 3));
[~, brainOrder] = sort(P(:, 1), 'descend');
posxyz = @(ic) EEG.dipfit.model(ic).posxyz(1, :);
fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nfit time %.0f s | components %d | coord_transform %s\n', cfg.stamp, fitSeconds, ...
    numel(EEG.dipfit.model), num2str(EEG.dipfit.coord_transform, '%.4g '));
fprintf(fid, 'IC %2d: RV = %5.1f%%\n', [1:numel(rv); rv]);
fprintf(fid, '%d of %d components below 15%% RV\n', sum(rv < 15), numel(rv));
fprintf(fid, 'eye IC %d (p = %.2f): RV %.1f%%, MNI %s\n', eyeIC, P(eyeIC, 3), rv(eyeIC), num2str(round(posxyz(eyeIC))));
for ic = brainOrder(1:3)'
    fprintf(fid, 'brain IC %d (p = %.2f): RV %.1f%%, MNI %s\n', ic, P(ic, 1), rv(ic), num2str(round(posxyz(ic))));
end
fclose(fid);
type(fullfile(out, 'facts.txt'));
