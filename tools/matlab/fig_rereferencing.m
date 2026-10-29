% FIG_REREFERENCING  Before/after pair for lesson rereferencing from D1.
%   Before: Plot > Channel data (scroll) on 'D1 interp' (original mastoid reference).
%   After: the same channels and seconds on 'D1 main' (average reference, EOG1 and EOG2 excluded).
%   Same channels, seconds, microvolt spacing and pixel size in both images.
%
% Output in assets-src/lessons/rereferencing/:
%   rereferencing-scroll-before.png, rereferencing-scroll-after.png
%   facts.txt   window, spacing, largest sum over scalp channels, EOG1 unchanged

cfg = sea_init();
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.notch(1), 'hicutoff', cfg.notch(2), 'revfilt', 1);
EEG.setname = 'D1 interp';
EEG_before = EEG;
eogIdx = find(ismember({EEG.chanlocs.labels}, cfg.d1_eog));
EEG = pop_reref(EEG, [], 'exclude', eogIdx);
EEG.setname = 'D1 main';
rel = fullfile('lessons', 'rereferencing');

chans = {'FPz', 'Cz', 'Pz', 'Oz', 'EOG1'};
t0 = 10; secs = 5;
[~, idx] = ismember(lower(chans), lower({EEG.chanlocs.labels}));
s = round(t0 * EEG.srate) + (1:round(secs * EEG.srate));
x = double(EEG_before.data(idx, s));
spacing = round(1.2 * max(max(x, [], 2) - min(x, [], 2)));

fig = sea_scroll(EEG_before, chans, t0, secs, spacing);
sea_export(fig, cfg, fullfile(rel, 'rereferencing-scroll-before.png'), [1000 520]);
fig = sea_scroll(EEG, chans, t0, secs, spacing);
sea_export(fig, cfg, fullfile(rel, 'rereferencing-scroll-after.png'), [1000 520]);

scalpIdx = setdiff(1:EEG.nbchan, eogIdx);
iEog = find(strcmp({EEG.chanlocs.labels}, 'EOG1'));
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nchannels: %s\nwindow: %g-%g s, spacing %g uV\nreference after: %s\nlargest sum over scalp channels: %g uV\nEOG1 largest change: %g uV\n', ...
    cfg.stamp, strjoin(chans, ' '), t0, t0 + secs, spacing, EEG.ref, ...
    max(abs(sum(EEG.data(scalpIdx, :), 1))), max(abs(EEG.data(iEog, :) - EEG_before.data(iEog, :))));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
