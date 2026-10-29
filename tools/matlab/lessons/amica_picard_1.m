% Copied from lessons/en/04-07-amica-picard.md. The lesson is the reference.
% The same ICA copy, decomposed by runica and by Picard (Infomax mode)
EEG_ica = pop_eegfiltnew(EEG, 'locutoff', 1);
% badChans: channels you interpolated (set in the starting script; {} if none)
if ~exist('badChans', 'var'), badChans = {}; end
expectedRank = EEG_ica.nbchan - numel(badChans) - 1;

tic;
EEG_runica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1);
tRunica = toc;

% pop_runica does not reduce the rank for Picard, so pass 'pca' yourself
tic;
EEG_picard = pop_runica(EEG_ica, 'icatype', 'picard', 'maxiter', 500, ...
    'mode', 'standard', 'pca', expectedRank);
tPicard = toc;

fprintf('runica: %.0f s, %d components\n', tRunica, size(EEG_runica.icaweights, 1));
fprintf('Picard: %.0f s, %d components\n', tPicard, size(EEG_picard.icaweights, 1));

% First 10 scalp maps of each, to compare by eye
pop_topoplot(EEG_runica, 0, 1:10);
pop_topoplot(EEG_picard, 0, 1:10);

% AMICA, after installing the AMICA extension; it also needs the rank
% EEG_ica.datfile = '';   % AMICA must use the filtered data in memory, not eeglab_data.fdt on disk
% EEG_amica = pop_runamica(EEG_ica, 'pcakeep', expectedRank, 'outdir', fullfile(pwd, 'amicaout'));
