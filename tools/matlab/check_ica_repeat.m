% CHECK_ICA_REPEAT  Does ICA give the same components in two runs with default settings?
% Runs pop_runica twice on the D1 ICA copy with the lesson options only ('extended', 1), then
% matches each component of run 1 to the closest map of run 2 (|r| between icawinv columns).
%
% Output: assets-src/checks/ica-repeat.txt
%   duration of each run, components found at the same position, lowest |r| among matched pairs.

cfg = sea_init();
EEG_ica = pop_eegfiltnew(sea_main(cfg), 'locutoff', cfg.ica_hp);

A = cell(1, 2); secs = zeros(1, 2);
for k = 1:2
    t0 = tic;
    evalc('R = pop_runica(EEG_ica, ''icatype'', ''runica'', ''extended'', 1);');
    secs(k) = toc(t0);
    A{k} = R.icawinv;
end

C = abs(corr_cols(A{1}, A{2}));
[best, match] = max(C, [], 2);
sameOrder = sum(match(:)' == 1:numel(match));

out = fullfile(cfg.out, 'checks');
if ~exist(out, 'dir'), mkdir(out); end
fid = fopen(fullfile(out, 'ica-repeat.txt'), 'w');
fprintf(fid, '%s\nrun 1: %.0f s\nrun 2: %.0f s\ncomponents: %d\nsame position in both runs: %d\n', ...
    cfg.stamp, secs(1), secs(2), numel(match), sameOrder);
fprintf(fid, 'best |r| per component (min %.3f, median %.3f)\n', min(best), median(best));
fprintf(fid, 'IC%02d -> IC%02d  |r| %.3f\n', [1:numel(match); match(:)'; best(:)']);
fclose(fid);
type(fullfile(out, 'ica-repeat.txt'));

function C = corr_cols(X, Y)
X = X - mean(X); Y = Y - mean(Y);
C = (X ./ vecnorm(X))' * (Y ./ vecnorm(Y));
end
