function e = exp_set_fdt_files()
% Expected results for lesson set-fdt-files (01-05), D1. Values from notes_stations_1-2.md (t-27)
% and review_batch7-st1-2b.md (t-32). The extra step copies eeglab_data.set alone to an empty folder
% and loads it, to record the error a learner sees when the .fdt file is missing.

e.run = {'start', 1, [ ...
    'copyInfo = dir(fullfile(myFolder, ''D1_copy.set'')); copyMB = copyInfo.bytes / 1e6; ' ...
    'setOnlyDir = fullfile(tempdir, ''simplyeeglab_set_only''); ' ...
    'if exist(setOnlyDir, ''dir''), rmdir(setOnlyDir, ''s''); end; mkdir(setOnlyDir); ' ...
    'copyfile(fullfile(sampleFolder, ''eeglab_data.set''), setOnlyDir); ' ...
    'setOnlyErr = ''''; ' ...
    'try, EEG_setonly = pop_loadset(''filename'', ''eeglab_data.set'', ''filepath'', setOnlyDir); ' ...
    'catch setOnlyME, setOnlyErr = setOnlyME.message; fprintf(''%s\n'', setOnlyErr); end']};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                                   expected  tol
    'one file: D1_copy.set',     'exist(fullfile(myFolder, ''D1_copy.set''), ''file'')',      2,        0
    'one file: no D1_copy.fdt',  'exist(fullfile(myFolder, ''D1_copy.fdt''), ''file'')',      0,        0
    'D1_copy.set size (MB)',     'copyMB',                                                     @(v) v > 3 && v < 6, 0
    'two files: .set',           'exist(fullfile(myFolder, ''D1_twofiles.set''), ''file'')',  2,        0
    'two files: .fdt',           'exist(fullfile(myFolder, ''D1_twofiles.fdt''), ''file'')',  2,        0
    '.set alone: load fails',    '~isempty(setOnlyErr)',                                      true,     0
    '.set alone: message',       'setOnlyErr',                                                [],       0
    };
e.log = {
    'sample datfile',            '''eeglab_data\.fdt'''
    '.set alone: fdt not found', 'eeglab_data\.fdt not found'
    '.set alone: rename hint',   'you must also rename/move the associated data file'
    };
e.scripts = {};
end
