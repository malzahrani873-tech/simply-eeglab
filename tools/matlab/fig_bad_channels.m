% FIG_BAD_CHANNELS  Example of a real bad channel for lesson bad-channels, from D3
%   (ERP CORE N400, CC BY-SA 4.0). D1 has no bad channel, so the lesson image comes from D3.
%
% Looks for ERP CORE N400 .set files under <cfg.datadir>/ERP_CORE/N400 (one folder per participant).
% For each participant, in folder order, it runs the lesson's detection (clean_rawdata channel
% criteria only, EOG channels ignored) on a 0.1 Hz high-passed copy, and stops at the first one with
% a flagged channel. The 10-s window shown is the one where that channel differs most from the others.
%
% Output in assets-src/lessons/bad-channels/:
%   bad-channels-d3-scroll.png   Plot > Channel data (scroll), 10 s, the bad channel in red
%   facts.txt                    participant, file, flagged channels, window, attribution

cfg = sea_init();
root = fullfile(cfg.datadir, 'ERP_CORE', 'N400');
files = dir(fullfile(root, '**', '*N400*.set'));
assert(~isempty(files), 'sea:nodata', 'No ERP CORE N400 .set file under %s (run_checklist 0.2).', root);
% Prefer the raw files (<id>_N400.set) when both raw and processed files are present
isRaw = ~cellfun(@isempty, regexp({files.name}, '^\d+_N400\.set$', 'once'));
if any(isRaw), files = files(isRaw); end
rel = fullfile('lessons', 'bad-channels');

found = false;
for k = 1:numel(files)
    EEG = pop_loadset('filename', files(k).name, 'filepath', files(k).folder);
    EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.erp_hp);
    labels = {EEG.chanlocs.labels};
    eog = labels(contains(upper(labels), 'EOG'));
    EEG_test = pop_clean_rawdata(EEG, 'FlatlineCriterion', 5, 'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, 'Highpass', 'off', 'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Euclidian', ...
        'channels_ignore', eog);
    badChans = setdiff(labels, {EEG_test.chanlocs.labels}, 'stable');
    if ~isempty(badChans)
        found = true;
        break
    end
end
assert(found, 'sea:nobad', 'No flagged channel in %d N400 files. Ask the writer for another example.', numel(files));

% Window: 10 s where the first bad channel deviates most from the median of the scalp channels
scalp = setdiff(labels, eog, 'stable');
iBad = find(strcmp(labels, badChans{1}));
iScalp = find(ismember(labels, scalp));
w = 10 * EEG.srate;
x = double(EEG.data(iScalp, :));
dev = abs(double(EEG.data(iBad, :)) - median(x, 1));
nWin = floor(EEG.pnts / w) - 2;
score = arrayfun(@(j) mean(dev(j * w + (1:w))), 1:nWin);   % skips the first 10 s
[~, j] = max(score);
t0 = j * 10;

% Neighbors of the bad channel plus a spread of other scalp channels, in recording order
show = scalp(round(linspace(1, numel(scalp), min(12, numel(scalp)))));
show = labels(ismember(labels, [show badChans]));
colors = repmat({'k'}, 1, numel(show));
colors(ismember(show, badChans)) = {'r'};
spacing = 2 * median(std(x(:, j * w + (1:w)), 0, 2));
fig = sea_scroll(EEG, show, t0, 10, spacing, colors);
sea_export(fig, cfg, fullfile(rel, 'bad-channels-d3-scroll.png'), [1000 560]);

fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nfile: %s\nflagged channels: %s\nshown channels: %s\nwindow: %d-%d s, spacing %.0f uV\n', ...
    cfg.stamp, fullfile(files(k).folder, files(k).name), strjoin(badChans, ' '), strjoin(show, ' '), t0, t0 + 10, spacing);
fprintf(fid, 'Data: ERP CORE (Kappenman et al., 2021), N400, CC BY-SA 4.0. Image licence CC BY-SA 4.0.\n');
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
