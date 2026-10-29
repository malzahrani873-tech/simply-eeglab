% Copied from lessons/en/06-01-erp-average.md. The lesson is the reference.
% The ERP is the mean over epochs: channels x time points
% (the same line pop_plottopo computes in the GUI step)
erp = mean(EEG.data, 3);
fprintf('Averaged %d epochs\n', EEG.trials);

% Plot the ERP at Pz, positive up
pz = find(strcmp({EEG.chanlocs.labels}, 'Pz'));
figure;
plot(EEG.times, erp(pz, :), 'k', 'LineWidth', 1.5);
xlim([-200 800]); grid on;
xline(0, '--'); yline(0);
xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
title(sprintf('ERP at Pz, %d epochs', EEG.trials));

% Approximate latency of the largest positive peak between 250 and 600 ms
win = EEG.times >= 250 & EEG.times <= 600;
winTimes = EEG.times(win);
[peakAmp, iPeak] = max(erp(pz, win));
fprintf('Positive peak at Pz: %.1f uV at %.0f ms\n', peakAmp, winTimes(iPeak));

% Quick look at all channels, same as the GUI step
figure; pop_plottopo(EEG, 1:EEG.nbchan, EEG.setname, 0, 'ydir', 1);
