% Copied from lessons/en/07-01-topoplot.md. The lesson is the reference.
EEG = pop_loadset('D1_epochs_clean.set', pwd);

% Scalp channels only: the EOG channels are not on the average reference
EEG = pop_select(EEG, 'rmchannel', {'EOG1', 'EOG2'});
EEG.setname = 'D1 epochs clean scalp';

% All-channel ERP with a scalp map at the latency of maximum power
figure; pop_timtopo(EEG, [-200 800], NaN, 'D1 epochs clean scalp');

% ERP with scalp maps at chosen latencies
figure; pop_timtopo(EEG, [-200 800], [100 200 400], 'D1 epochs clean scalp');

% Map series every 100 ms, one shared color scale, 2 x 3 grid
pop_topoplot(EEG, 1, 0:100:500, 'D1 epochs clean scalp', [2 3], 0, 'electrodes', 'on');

% Mean map over a 300 to 500 ms window
erp = mean(EEG.data, 3);
win = EEG.times >= 300 & EEG.times <= 500;
winMap = mean(erp(:, win), 2);
lim = max(abs(winMap));
figure;
topoplot(winMap, EEG.chanlocs, 'maplimits', [-lim lim], 'electrodes', 'on');
cb = colorbar; ylabel(cb, '\muV');
title('300 to 500 ms');
