% FIG_IMPORT_RAW  Facts and figure for lesson import-raw from the EDF file (D2: EEGMMIDB S001R03).
%
% Requires the Biosig plugin (File > Manage EEGLAB extensions).
% Output in assets-src/lessons/import-raw/:
%   facts.txt                 channels, sampling rate, length, events (to check the lesson text)
%   import-raw-scroll.png     10 s of 8 channels after import

cfg = sea_init();
if ~exist(cfg.d2, 'file')
    error('sea:nodata', 'File not found: %s\nDownload it from https://physionet.org/files/eegmmidb/1.0.0/S001/S001R03.edf', cfg.d2);
end

% Same as File > Import data > Using EEGLAB functions and plugins >
%                 From EDF/EDF+/GDF files (BIOSIG toolbox)
EEG = pop_biosig(cfg.d2);
EEG.setname = 'S001R03';
EEG = eeg_checkset(EEG);

outdir = fullfile(cfg.out, 'lessons', 'import-raw');
if ~exist(outdir, 'dir'), mkdir(outdir); end

% --- Facts ---------------------------------------------------------------------
types = {};
if ~isempty(EEG.event)
    types = cellfun(@num2str, {EEG.event.type}, 'UniformOutput', false);
end
[u, ~, j] = unique(types);
fid = fopen(fullfile(outdir, 'facts.txt'), 'w');
fprintf(fid, '%s\n', cfg.stamp);
fprintf(fid, 'file      : %s\n', cfg.d2);
fprintf(fid, 'nbchan    : %d\n', EEG.nbchan);
fprintf(fid, 'srate     : %g Hz\n', EEG.srate);
fprintf(fid, 'pnts      : %d\n', EEG.pnts);
fprintf(fid, 'duration  : %.1f s\n', EEG.xmax);
fprintf(fid, 'chanlocs  : %d of %d have coordinates\n', sum(~cellfun(@isempty, {EEG.chanlocs.X})), EEG.nbchan);
fprintf(fid, 'labels    : %s\n', strjoin({EEG.chanlocs(1:min(8, end)).labels}, ', '));
fprintf(fid, 'events    : %d\n', numel(EEG.event));
for k = 1:numel(u)
    fprintf(fid, '  type %-8s x %d\n', u{k}, sum(j == k));
end
fclose(fid);
type(fullfile(outdir, 'facts.txt'));

% --- 10 s of 8 channels (static plot, no eegplot window) ------------------------
nch = min(8, EEG.nbchan);
idx = 1:round(10 * EEG.srate);
x = double(EEG.data(1:nch, idx));
x = x - mean(x, 2);
gap = 4 * median(std(x, 0, 2));
t = (idx - 1) / EEG.srate;
fig = figure;
hold on;
for c = 1:nch
    plot(t, x(c, :) - (c - 1) * gap, 'k', 'LineWidth', 0.6);
end
set(gca, 'YTick', -(nch - 1:-1:0) * gap, 'YTickLabel', fliplr({EEG.chanlocs(1:nch).labels}), ...
    'TickLength', [0 0], 'Box', 'off');
xlabel('Time (s)');
xlim([0 10]);
sea_export(fig, cfg, fullfile('lessons', 'import-raw', 'import-raw-scroll.png'), [960 420]);
