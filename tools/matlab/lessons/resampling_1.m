% Copied from lessons/en/03-01-resampling.md. The lesson is the reference.
% Exercise only: a temporary copy at half the sampling rate
EEG_64 = pop_resample(EEG, 64);
EEG_64.setname = 'D1 64Hz';

% Compare rate, length and events
fprintf('Original : %g Hz, %d samples, %d events\n', EEG.srate, EEG.pnts, length(EEG.event));
fprintf('Resampled: %g Hz, %d samples, %d events\n', EEG_64.srate, EEG_64.pnts, length(EEG_64.event));

% The same 2 seconds of channel Cz at both rates
cz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));
t1 = (0:2*EEG.srate-1) / EEG.srate;
t2 = (0:2*EEG_64.srate-1) / EEG_64.srate;
figure; hold on;
plot(t1, EEG.data(cz, 1:numel(t1)), '.-');
plot(t2, EEG_64.data(cz, 1:numel(t2)), 'o-');
legend('128 Hz', '64 Hz');
xlabel('Time (s)'); ylabel('Amplitude (uV)');

% The main path continues on EEG at 128 Hz; EEG_64 is not saved
