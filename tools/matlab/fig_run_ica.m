% FIG_RUN_ICA  Figures for lesson run-ica from D1, following the lesson and its Starting point:
%   main dataset (sea_main) -> ICA copy with a 1 Hz high-pass -> ICA -> weights copied back to main.
%
% Output:
%   assets-src/lessons/run-ica/run-ica-maps-20.png   maps of the first 20 components (Plot > Component maps > In 2-D)
%   assets-src/lessons/run-ica/facts.txt             rank, number of components, ICA duration, end of the log
%   <cfg.work>/D1_main_ica.set                       main dataset with ICA weights (read by fig_iclabel.m)
%
% By default runica reseeds from the clock (runica.m line 205), so component order and sign can change
% between runs. 'rndreset','no' (cfg.ica_opts) keeps the figure and facts.txt reproducible;
% check_ica_repeat.m measures the difference with the default setting.

cfg = sea_init();
EEG_main = sea_main(cfg);

% ICA copy: same data, 1 Hz high-pass
EEG_ica = pop_eegfiltnew(EEG_main, 'locutoff', cfg.ica_hp);
EEG_ica.setname = 'D1 ica1hz';

% Tools > Decompose data by ICA: Extended Infomax (runica.m; default)
% Average reference lowers the rank by one; in script mode pop_runica adds 'pca' automatically.
t0 = tic;
icalog = evalc('EEG_ica = pop_runica(EEG_ica, cfg.ica_opts{:});');
icaSeconds = toc(t0);

% Copy the decomposition back to the main dataset
EEG_main.icaweights  = EEG_ica.icaweights;
EEG_main.icasphere   = EEG_ica.icasphere;
EEG_main.icachansind = EEG_ica.icachansind;
EEG_main.icawinv     = [];
EEG_main.icaact      = [];
EEG = eeg_checkset(EEG_main);
pop_saveset(EEG, 'filename', 'D1_main_ica.set', 'filepath', cfg.work);

% --- Maps of the first 20 components -------------------------------------------------
rel = fullfile('lessons', 'run-ica');
pop_topoplot(EEG, 0, 1:20, 'D1 main', [4 5], 0, 'electrodes', 'on');
sea_export(gcf, cfg, fullfile(rel, 'run-ica-maps-20.png'), [1000 860]);

% --- Facts ----------------------------------------------------------------------------
if ~exist(fullfile(cfg.out, rel), 'dir'), mkdir(fullfile(cfg.out, rel)); end
rankLine = regexp(icalog, 'Data rank[^\n]*', 'match', 'once');
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nchannels   : %d\ncomponents : %d\nica options: %s\nica time   : %.0f s\nrank line  : %s\n', ...
    cfg.stamp, EEG.nbchan, size(EEG.icaweights, 1), strjoin(cellfun(@num2str, cfg.ica_opts, 'UniformOutput', false), ' '), ...
    icaSeconds, rankLine);
fprintf(fid, 'last lines of runica log:\n%s\n', strtrim(icalog(max(1, end - 600):end)));
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
