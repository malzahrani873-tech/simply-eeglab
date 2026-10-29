% FIG_AMICA_PICARD  Figure for lesson amica-picard from D1: the first 10 scalp maps of the same 1 Hz
%   copy decomposed by runica (top row) and by Picard in Infomax mode (bottom row).
%
% Requires the PICARD plugin (plugin batch on the run day, run_checklist 2.10). The runica row reuses
% the weights saved by fig_run_ica.m (<cfg.work>/D1_main_ica.set: same 1 Hz copy, same seed), or
% computes them with cfg.ica_opts when that file is missing. Picard runs with a fixed seed (rng 0).
%
% Output in assets-src/lessons/amica-picard/:
%   amica-picard-maps-runica-picard.png   2 rows x 10 maps, same colormap, each map scaled to its own maximum
%   facts.txt                             components, Picard time, best-matching runica map for each Picard map

cfg = sea_init();
assert(exist('picard', 'file') == 2, 'sea:plugin', 'Picard plugin not found (File > Manage EEGLAB extensions).');
EEG_main = sea_main(cfg);
EEG_ica = pop_eegfiltnew(EEG_main, 'locutoff', cfg.ica_hp);
EEG_ica.setname = 'D1 ica1hz';
expectedRank = EEG_ica.nbchan - 1;
rel = fullfile('lessons', 'amica-picard');

f = fullfile(cfg.work, 'D1_main_ica.set');
if exist(f, 'file')
    W = pop_loadset('filename', 'D1_main_ica.set', 'filepath', cfg.work);
    EEG_runica = EEG_ica;
    EEG_runica.icaweights = W.icaweights; EEG_runica.icasphere = W.icasphere;
    EEG_runica.icachansind = W.icachansind; EEG_runica.icawinv = []; EEG_runica.icaact = [];
    EEG_runica = eeg_checkset(EEG_runica);
else
    EEG_runica = pop_runica(EEG_ica, cfg.ica_opts{:});
end

rng(0);
t0 = tic;
EEG_picard = pop_runica(EEG_ica, 'icatype', 'picard', 'maxiter', 500, 'mode', 'standard', 'pca', expectedRank);
tPicard = toc(t0);

n = 10;
figure;
for k = 1:n
    subplot(2, n, k);
    topoplot(EEG_runica.icawinv(:, k), EEG_runica.chanlocs(EEG_runica.icachansind), 'maplimits', 'absmax', 'electrodes', 'off');
    title(sprintf('%d', k), 'FontWeight', 'normal');
    subplot(2, n, n + k);
    topoplot(EEG_picard.icawinv(:, k), EEG_picard.chanlocs(EEG_picard.icachansind), 'maplimits', 'absmax', 'electrodes', 'off');
    title(sprintf('%d', k), 'FontWeight', 'normal');
end
colormap(cfg.colormap);
sea_export(gcf, cfg, fullfile(rel, 'amica-picard-maps-runica-picard.png'), [1400 340]);

% For each Picard map, the runica map it matches best (absolute correlation, sign ignored)
A = EEG_picard.icawinv(:, 1:n); B = EEG_runica.icawinv;
A = (A - mean(A)) ./ vecnorm(A - mean(A)); B = (B - mean(B)) ./ vecnorm(B - mean(B));
C = abs(A' * B);                                   % Pearson correlation without the Statistics Toolbox
[best, match] = max(C, [], 2);
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\ncomponents: runica %d, Picard %d\nPicard time: %.0f s\n', cfg.stamp, ...
    size(EEG_runica.icaweights, 1), size(EEG_picard.icaweights, 1), tPicard);
for k = 1:n
    fprintf(fid, 'Picard %2d ~ runica %2d (|r| = %.2f)\n', k, match(k), best(k));
end
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
