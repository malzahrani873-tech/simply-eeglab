% Copied from lessons/en/00-05-experiment-design.md. The lesson is the reference.
% How the number of trials changes the noise left in an average
srate = 250;                                         % samples per second
t     = -0.2:1/srate:0.8;                            % epoch from -200 to 800 ms
erp   = 5 * exp(-((t - 0.35).^2) / (2*0.08^2));      % P3-like wave, 5 microvolts
rng(1);                                              % same noise on every run

nTrials = [10 40 160];
labels  = cell(1, numel(nTrials));
figure; hold on;
for k = 1:numel(nTrials)
    n      = nTrials(k);
    trials = erp + 20 * randn(n, numel(t));          % same wave + noise on each trial
    avg    = mean(trials, 1);                        % the average across trials
    noise  = std(avg(t < 0));                        % noise left in the pre-stimulus period
    fprintf('%4d trials: noise left = %.2f microvolts\n', n, noise);
    plot(t*1000, avg);
    labels{k} = sprintf('%d trials', n);
end
plot(t*1000, erp, 'k', 'LineWidth', 2);
xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
legend([labels, {'True wave'}]);
