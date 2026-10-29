% Copied from lessons/en/00-02-electrode-10-20.md. The lesson is the reference.
% Plot the 32-channel montage of the EEGLAB sample dataset with labels
eeglab nogui;                                         % load EEGLAB functions only
eeglabRoot = fileparts(which('eeglab'));
locs = readlocs(fullfile(eeglabRoot, 'sample_data', 'eeglab_chan32.locs'));

figure;
topoplot([], locs, 'style', 'blank', 'electrodes', 'labelpoint');
title('eeglab\_data.set montage');

disp({locs.labels});                                  % list all channel names
