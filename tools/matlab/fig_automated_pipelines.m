% FIG_AUTOMATED_PIPELINES  Spectra before and after PREP for lesson automated-pipelines (09-04), D1 raw.
%   Needs the PrepPipeline extension (not bundled with EEGLAB): plugin batch of the run day.
%   PREP parameters are the lesson's: 60 Hz line noise, all channels detrended and cleaned of line
%   noise, the robust reference computed on the 30 scalp channels only.
%
% Output in assets-src/lessons/automated-pipelines/:
%   prep-spectra.png          left raw, right after PREP (Plot > Channel spectra and maps, 1-64 Hz)
%   prep-spectra-raw.png      the left plot alone (760 x 560 px)
%   prep-spectra-prep.png     the right plot alone (760 x 560 px)
%   facts.txt                 PREP version, interpolated and still-noisy channels, 60 Hz peak before/after

cfg = sea_init();
assert(exist('prepPipeline', 'file') == 2, 'PrepPipeline is not installed (File > Manage EEGLAB extensions).');
EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', fileparts(cfg.d1));
EEG_raw = EEG;
rel = fullfile('lessons', 'automated-pipelines');
out = fullfile(cfg.out, rel);
if ~exist(out, 'dir'), mkdir(out); end
sizepx = [760 560];

eegChans = find(~ismember({EEG.chanlocs.labels}, cfg.d1_eog));
params = struct();
params.name = 'D1';
params.lineFrequencies = 60;
params.detrendChannels = 1:EEG.nbchan;
params.lineNoiseChannels = 1:EEG.nbchan;
params.referenceChannels = eegChans;
params.evaluationChannels = eegChans;
params.rereferencedChannels = eegChans;
t0 = tic;
[EEG, params] = prepPipeline(EEG, params);
prepSeconds = toc(t0);
nd = EEG.etc.noiseDetection;

specargs = {'freqrange', [1 64], 'freq', [10 60]};
figure; pop_spectopo(EEG_raw, 1, [], 'EEG', specargs{:});
fileL = sea_export(gcf, cfg, fullfile(rel, 'prep-spectra-raw.png'), sizepx);
figure; pop_spectopo(EEG, 1, [], 'EEG', specargs{:});
fileR = sea_export(gcf, cfg, fullfile(rel, 'prep-spectra-prep.png'), sizepx);
imwrite([imread(fileL) imread(fileR)], fullfile(out, 'prep-spectra.png'));

peak = @(E) sea_db(E, 60) - mean(sea_db(E, [56 57 63 64]));
labels = {EEG.chanlocs.labels};
fid = fopen(fullfile(out, 'facts.txt'), 'w');
fprintf(fid, '%s\nPREP version %s | status %s | %.0f s\n', cfg.stamp, nd.version, nd.errors.status, prepSeconds);
fprintf(fid, 'interpolated: %s\nstill noisy : %s\n', strjoin(labels(nd.interpolatedChannelNumbers), ', '), ...
    strjoin(labels(nd.stillNoisyChannelNumbers), ', '));
fprintf(fid, '60 Hz peak above 56-57/63-64 Hz (dB, channel mean): raw %.1f | prep %.1f\n', peak(EEG_raw), peak(EEG));
fclose(fid);
type(fullfile(out, 'facts.txt'));
