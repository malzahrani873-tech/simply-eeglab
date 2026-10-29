function e = exp_amica_picard()
% Expected results for lesson amica-picard (04-07), D1 main dataset. Needs the Picard plugin
% (run_checklist 0.4 installs it with AMICA). From review_batch9-st3-4b.md: y-2 records datfile and
% saved after the Starting point; y-4 records the Picard help text; the plugin folder names record the
% installed AMICA and Picard versions, which are not pinned in EEGLAB 2026.1.

e.run = {'start', [ ...
    'startDatfile = EEG.datfile; startSaved = EEG.saved; ' ...
    'pluginFolders = dir(fullfile(fileparts(which(''eeglab'')), ''plugins'')); ' ...
    'pluginFolders = {pluginFolders([pluginFolders.isdir]).name}; ' ...
    'pluginFolders = pluginFolders(~cellfun(@isempty, regexpi(pluginFolders, ''amica|picard'', ''once''))); ' ...
    'picardHelp = evalc(''help picard'');'], 1};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected    tol
    'datfile after start (y-2)', 'startDatfile',                                    [],         0
    'saved after start (y-2)',   'startSaved',                                      [],         0
    'AMICA / Picard folders',    'pluginFolders',                                   [],         0
    'picard found',              'exist(''picard'', ''file'')',                     2,          0
    'picard help: extended (y-4)', 'contains(picardHelp, ''extended'')',            [],         0
    'runica components',         'size(EEG_runica.icaweights, 1)',                  31,         0
    'Picard components',         'size(EEG_picard.icaweights, 1)',                  31,         0
    'runica seconds',            'tRunica',                                         [],         0
    'Picard seconds',            'tPicard',                                         [],         0
    };
e.log = {};
e.scripts = {'fig_amica_picard'};
end
