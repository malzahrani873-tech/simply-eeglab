% Copied from lessons/en/04-01-ica-concept.md. The lesson is the reference.
eeglab nogui;   % puts runica on the MATLAB path

% Three made-up sources, 10 seconds at 128 Hz
srate = 128;
t = (0:10*srate-1) / srate;
brain = sin(2*pi*10*t);                        % steady 10 Hz rhythm
n = round(0.3*srate);
win = 0.5 - 0.5*cos(2*pi*(0:n-1)/(n-1));       % smooth bump for one blink
blink = zeros(size(t));
blink(round([1.5 4 6.5 9]*srate)) = 1;
blink = 5 * conv(blink, win, 'same');          % four large, slow blinks
muscle = 0.5 * randn(size(t));                 % fast, irregular activity
S = [brain; blink; muscle];

% Each channel records a different mix of the three sources
A = [1.0 0.8 0.3;     % frontal channel: strong blink
     0.9 0.2 0.4;     % central channel
     0.7 0.1 1.0];    % temporal channel: strong muscle
X = A * S;

% ICA unmixes the channels without knowing A
[weights, sphere] = runica(X, 'extended', 1);
act = weights * sphere * X;

figure;
for k = 1:3
    subplot(3, 2, 2*k-1); plot(t, X(k, :));   title(sprintf('Channel %d (mixture)', k));
    subplot(3, 2, 2*k);   plot(t, act(k, :)); title(sprintf('ICA component %d', k));
end
