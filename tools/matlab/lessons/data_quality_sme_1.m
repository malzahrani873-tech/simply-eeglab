% Copied from lessons/en/06-05-data-quality-sme.md. The lesson is the reference.
% aSME at C3, 200-300 ms window, bin 1, for every participant
c3 = find(strcmp({ALLERP(1).chanlocs.labels}, 'C3'));
nSets = numel(ALLERP);
sme = nan(nSets, 1);
for k = 1:nSets
    dq = ALLERP(k).dataquality;
    iA = find(strcmpi({dq.type}, 'aSME'));
    if isempty(iA)
        error('ERPset %d has no aSME values', k);
    end
    tw = dq(iA).times;   % one row per time window, in ms
    iW = find(tw(:, 1) == 200 & tw(:, 2) == 300);
    sme(k) = dq(iA).data(c3, iW, 1);   % channels x windows x bins
end

% Summary across participants
fprintf('aSME at C3, 200-300 ms: median %.2f uV, RMS %.2f uV\n', ...
    median(sme), sqrt(mean(sme.^2)));

% Participants with aSME more than twice the median
outliers = find(sme > 2 * median(sme));
fprintf('Participants to inspect: %s\n', mat2str(outliers'));

% Same summary as the GUI, for one ERPset
dq_summary(ALLERP(1));
