% Copied from lessons/en/04-02-ica-data-requirements.md. The lesson is the reference.
% How much data ICA has in the current dataset
% badChans: channels you interpolated (set in the starting script; {} if none)
if ~exist('badChans', 'var'), badChans = {}; end
nComp   = EEG.nbchan - numel(badChans) - 1;   % expected rank after average reference
nPoints = EEG.pnts * EEG.trials;
fprintf('Data points per channel: %d\n', nPoints);
fprintf('Recording length: %.2f min\n', nPoints / EEG.srate / 60);
fprintf('Points per weight, %d channels: %.1f\n', EEG.nbchan, nPoints / EEG.nbchan^2);
fprintf('Points per weight, %d components: %.1f\n', nComp, nPoints / nComp^2);

% Shortest recording that gives k = 30 points per weight at this sampling rate
k = 30;
for N = [32 64 128 256]
    fprintf('%3d components: at least %.1f min\n', N, k * N^2 / EEG.srate / 60);
end
