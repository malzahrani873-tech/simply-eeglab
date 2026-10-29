% Copied from lessons/en/00-03-matlab-basics.md. The lesson is the reference.
% A toy recording: 3 channels, 10 seconds at 128 Hz
demo.srate  = 128;                              % sampling rate (samples per second)
demo.nbchan = 3;                                % number of channels
demo.pnts   = 10 * demo.srate;                  % samples per channel
demo.labels = {'Fz', 'Cz', 'Pz'};               % channel names (a cell array of text)
demo.data   = randn(demo.nbchan, demo.pnts);    % random numbers, channels x samples

% Read from the struct
size(demo.data)                                 % rows = channels, columns = samples
demo.srate                                      % one field
demo.labels{2}                                  % text of the second channel name

% Indexing: channel 2, samples 1 to 5
firstSamples = demo.data(2, 1:5)

% Time of each sample in seconds (the first sample is at time 0)
t = (0:demo.pnts-1) / demo.srate;
t(end)

% Plot one channel
figure;
plot(t, demo.data(2, :));
xlabel('Time (s)'); ylabel('Amplitude');
title(['Channel ' demo.labels{2}]);

% Where MATLAB finds things
whos demo                                       % size and type of a variable
which plot                                      % location of a function on the path
