% Copied from lessons/en/00-01-eeg-origin.md. The lesson is the reference.
% Sum of many small sources: random timing vs. synchronized timing
nSources = 1000;              % number of small sources
srate    = 128;               % samples per second
t        = 0:1/srate:2;       % 2 seconds of time
f        = 10;                % frequency in Hz (alpha range)

% Each source gets its own random phase (its own timing)
phases   = 2*pi*rand(nSources, 1);
asyncSum = sum(sin(2*pi*f*t + phases), 1);

% All sources share the same phase
syncSum  = sum(sin(2*pi*f*t + zeros(nSources, 1)), 1);

fprintf('Peak of random-timing sum: %.0f\n', max(abs(asyncSum)));
fprintf('Peak of synchronized sum:  %.0f\n', max(abs(syncSum)));

figure;
plot(t, syncSum); hold on;
plot(t, asyncSum);
xlabel('Time (s)'); ylabel('Summed amplitude (a.u.)');
legend('Synchronized', 'Random timing');
