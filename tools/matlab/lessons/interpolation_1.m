% Copied from lessons/en/03-06-interpolation.md. The lesson is the reference.
% Rebuild the removed channels from the full channel list (fullLocs)
if ~isempty(badChans)
    EEG = pop_interp(EEG, fullLocs, 'spherical');
end
EEG.setname = 'D1 interp';
fprintf('Channels after interpolation: %d\n', EEG.nbchan);
EEG = pop_saveset(EEG, 'filename', 'D1_interp.set', 'filepath', pwd);

% Exercise: remove a good channel, rebuild it, compare with the original
testChan = 'C3';
EEG_drop = pop_select(EEG, 'rmchannel', {testChan});
EEG_back = pop_interp(EEG_drop, fullLocs, 'spherical');
iOrig = find(strcmp({EEG.chanlocs.labels}, testChan));
iBack = find(strcmp({EEG_back.chanlocs.labels}, testChan));
r = corrcoef(double(EEG.data(iOrig, :)), double(EEG_back.data(iBack, :)));
fprintf('Correlation between original and interpolated %s: %.2f\n', testChan, r(1, 2));
