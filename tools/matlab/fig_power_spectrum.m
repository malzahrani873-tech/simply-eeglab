% FIG_POWER_SPECTRUM  Figure for lesson power-spectrum from D1: Plot > Channel spectra and maps on
%   'D1 main clean' with the lesson's settings (1 to 64 Hz, map at 10 Hz, default EEGLAB colormap).
%   This is the EEGLAB figure itself, exported at a fixed size, in place of a screenshot.
%
% Output in assets-src/lessons/power-spectrum/:
%   power-spectrum-spectopo-10hz.png
%   facts.txt   frequency step, alpha peak at Pz, five strongest channels at 10 Hz, dip at 60 Hz

cfg = sea_init();
EEG = sea_clean(cfg);
rel = fullfile('lessons', 'power-spectrum');

figure;
[spectra, freqs] = pop_spectopo(EEG, 1, [0 EEG.xmax * 1000], 'EEG', ...
    'freq', 10, 'freqrange', [1 64], 'electrodes', 'off');
colormap(cfg.colormap);
sea_export(gcf, cfg, fullfile(rel, 'power-spectrum-spectopo-10hz.png'), [900 560]);

pz = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
alpha = freqs >= 8 & freqs <= 13;
af = freqs(alpha);
[pp, i] = max(spectra(pz, alpha));
[~, order] = sort(spectra(:, freqs == 10), 'descend');
dip = mean(spectra(:, freqs == 60)) - mean(mean(spectra(:, ismember(freqs, [55 56 64]))));
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nfrequency step: %.2f Hz\nalpha peak at Pz: %.0f Hz, %.1f dB\nstrongest at 10 Hz: %s\n60 Hz relative to 55/56/64 Hz: %.1f dB\n', ...
    cfg.stamp, freqs(2) - freqs(1), af(i), pp, strjoin({EEG.chanlocs(order(1:5)).labels}, ' '), dip);
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
