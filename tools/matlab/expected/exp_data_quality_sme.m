function e = exp_data_quality_sme()
% Expected results for lesson data-quality-sme (06-05): ERPLAB, Luck chapter 10 ERPsets.
% The extra step answers review_batch6-st6.md S-1 (decision m-q-09): do the files carry aSME values,
% and is there a 200-300 ms window? If not, the lesson uses the alternative in notes_stations_5-6.md.

cfg = sea_config();
e.run = {'start', [ ...
    'dqTypes = {ALLERP(1).dataquality.type}; ' ...
    'iA0 = find(strcmpi(dqTypes, ''aSME'')); aSMEsize = []; aSMEtimes = zeros(0, 2); ' ...
    'if ~isempty(iA0), aSMEsize = size(ALLERP(1).dataquality(iA0).data); ' ...
    'aSMEtimes = ALLERP(1).dataquality(iA0).times; end'], 1};
e.paths = {'fullfile(pwd, ''Chapter_10''', sprintf('fullfile(''%s'', ''Chapter_10''', cfg.course_dir)};
e.checks = {
    % label                      expression                                                   expected  tol
    'ERPsets loaded',            'numel(ALLERP)',                                             [],       0
    'data quality types',        'dqTypes',                                                   [],       0
    'aSME present (S-1)',        '~isempty(iA0)',                                             true,     0
    'window 200-300 present',    'any(aSMEtimes(:, 1) == 200 & aSMEtimes(:, 2) == 300)',      true,     0
    'aSME size (ch x win x bins)', 'aSMEsize',                                                [],       0
    'aSME windows',              'aSMEtimes',                                                 [],       0
    'bin descriptions (S-2)',    'ALLERP(1).bindescr',                                        [],       0
    'channel C3 present',        'any(strcmp({ALLERP(1).chanlocs.labels}, ''C3''))',          true,     0
    'aSME median at C3',         'median(sme)',                                               [],       0
    'aSME RMS at C3',            'sqrt(mean(sme.^2))',                                        [],       0
    'participants to inspect',   'outliers''',                                                [],       0
    };
e.log = {};
e.scripts = {'fig_data_quality_sme'};
end
