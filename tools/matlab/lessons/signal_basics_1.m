% Copied from lessons/en/00-04-signal-basics.md. The lesson is the reference.
% Build a 10-second signal at 128 Hz from known parts, then look at its spectrum
srate = 128;                          % samples per second
t     = (0:10*srate-1) / srate;       % 10 s of time, first sample at 0
rng(0);                               % same random noise on every run
alpha = 20 * sin(2*pi*10*t);          % 10 Hz, 20 microvolts
theta =  8 * sin(2*pi*6*t);           % 6 Hz, 8 microvolts
noise =  5 * randn(size(t));          % broadband noise
sig   = alpha + theta + noise;

% Amplitude spectrum with the FFT
n     = numel(sig);
amp   = abs(fft(sig)) / n * 2;        % amplitude at each frequency
freqs = (0:n-1) * srate / n;          % frequency of each FFT bin in Hz
keep  = freqs <= srate/2;             % keep frequencies up to Nyquist

figure;
subplot(2,1,1); plot(t, sig); xlim([0 2]);
xlabel('Time (s)'); ylabel('Amplitude (\muV)');
subplot(2,1,2); plot(freqs(keep), amp(keep));
xlabel('Frequency (Hz)'); ylabel('Amplitude (\muV)');

% Strongest frequency between 8 and 12 Hz
band = freqs >= 8 & freqs <= 12;
[~, iPeak] = max(amp .* band);
fprintf('Alpha peak at %.1f Hz, amplitude %.1f\n', freqs(iPeak), amp(iPeak));
fprintf('Nyquist frequency: %d Hz\n', srate/2);

% Aliasing: a 70 Hz wave sampled at 128 Hz shows up at 58 Hz
fast = sin(2*pi*70*t);
[~, iAlias] = max(abs(fft(fast)) .* keep);
fprintf('A 70 Hz wave appears at %.1f Hz\n', freqs(iAlias));
