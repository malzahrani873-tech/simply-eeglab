% Copied from lessons/en/06-02-power-spectrum.md. The lesson is the reference.
% Spectra of all channels from 1 to 64 Hz, with a scalp map at 10 Hz
figure;
[spectra, freqs] = pop_spectopo(EEG, 1, [0 EEG.xmax*1000], 'EEG', ...
    'freq', 10, 'freqrange', [1 64], 'electrodes', 'off');

% spectra: channels x frequencies, in 10*log10(uV^2/Hz)
fprintf('Frequency step: %.2f Hz\n', freqs(2) - freqs(1));

% Alpha peak at Pz between 8 and 13 Hz
pz = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
alphaBand = freqs >= 8 & freqs <= 13;
alphaFreqs = freqs(alphaBand);
[peakPow, iPeak] = max(spectra(pz, alphaBand));
fprintf('Alpha peak at Pz: %.0f Hz, %.1f dB\n', alphaFreqs(iPeak), peakPow);

% Channels with the strongest 10 Hz power
[~, order] = sort(spectra(:, freqs == 10), 'descend');
disp({EEG.chanlocs(order(1:5)).labels});
