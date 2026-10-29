function e = exp_power_spectrum()
% Expected results for lesson power-spectrum (06-02), D1 main clean (no low-pass). Values from
% notes_stations_5-6.md. The lesson time in the log answers review_batch6-st6.md P-1 (the Starting
% point reruns ICA).

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected                    tol
    'frequency step (Hz)',       'freqs(2) - freqs(1)',                             1,                          1e-6
    'spectra size',              'size(spectra)',                                   [32 65],                    0
    'alpha peak at Pz (Hz)',     'alphaFreqs(iPeak)',                               @(f) any(f == [9 10]),      0
    'alpha peak at Pz (dB)',     'peakPow',                                         [],                         0
    'top five channels at 10 Hz', '{EEG.chanlocs(order(1:5)).labels}',             [],                         0
    'quiz: alpha is posterior',  'nnz(~cellfun(@isempty, regexp({EEG.chanlocs(order(1:5)).labels}, ''^(P|O)'', ''once''))) >= 3', true, 0
    'dip at 60 Hz (dB vs 56/64)', 'mean(mean(spectra(:, freqs >= 59 & freqs <= 61))) - mean(mean(spectra(:, freqs == 56 | freqs == 64)))', @(d) d < 0, 0
    };
e.log = {
    'frequency step printed',    'Frequency step: 1\.00 Hz'
    };
e.scripts = {'fig_power_spectrum'};
end
