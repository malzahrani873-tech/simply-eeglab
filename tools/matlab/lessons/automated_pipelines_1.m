% Copied from lessons/en/09-04-automated-pipelines.md. The lesson is the reference.
% PREP is not bundled with EEGLAB: install it from the extension manager
plugin_askinstall('PrepPipeline', 'prepPipeline', true);

% Keep a copy of the raw data to compare spectra
EEG_raw = EEG;

% Scalp channels only; EOG is cleaned of line noise but not referenced
eegChans = find(~ismember({EEG.chanlocs.labels}, {'EOG1', 'EOG2'}));

params = struct();
params.name = 'D1';
params.lineFrequencies = 60;
params.detrendChannels = 1:EEG.nbchan;
params.lineNoiseChannels = 1:EEG.nbchan;
params.referenceChannels = eegChans;
params.evaluationChannels = eegChans;
params.rereferencedChannels = eegChans;

% Line noise removal, robust reference, bad channel interpolation
[EEG, params] = prepPipeline(EEG, params);
EEG.setname = 'D1 prep';

% What did PREP decide?
nd = EEG.etc.noiseDetection;
if ~strcmp(nd.errors.status, 'good')
    error('PREP stopped with status: %s', nd.errors.status);
end
fprintf('PREP version: %s\n', nd.version);
fprintf('Interpolated channels: %s\n', ...
    strjoin({EEG.chanlocs(nd.interpolatedChannelNumbers).labels}, ', '));
fprintf('Still noisy after reference: %s\n', ...
    strjoin({EEG.chanlocs(nd.stillNoisyChannelNumbers).labels}, ', '));

% Spectrum before and after
figure; pop_spectopo(EEG_raw, 1, [], 'EEG', 'freqrange', [1 64], 'freq', [10 60]);
figure; pop_spectopo(EEG, 1, [], 'EEG', 'freqrange', [1 64], 'freq', [10 60]);

% PREP leaves the data unfiltered: high-pass before ICA or epochs
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1);

EEG.filename = ''; EEG.filepath = ''; EEG.datfile = ''; EEG.saved = 'no';
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'setname', 'D1 prep', 'gui', 'off');
eeglab redraw;
