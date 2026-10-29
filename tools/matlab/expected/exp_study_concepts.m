function e = exp_study_concepts()
% Expected results for lesson study-concepts (08-01), ready Go-nogo STUDY (D6).
% The ready STUDY holds one "animal" and one "distractor" file per participant (d6_facts.m).

ref = d6_facts();
nDat = ref.ready.dat_files;
e.run = {'start', ...
    ['studyRel = strrep(studyDir, dataFolder, ''''); ' ...
     'fdtList = dir(fullfile(studyDir, ''**'', ''*.fdt'')); fdtCount = nnz(~startsWith({fdtList.name}, ''._'')); ' ...
     'datList = dir(fullfile(studyDir, ''**'', ''*.dat*'')); datCount = nnz(~startsWith({datList.name}, ''._'')); ' ...
     'clear fdtList datList'], ...
    1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'folder inside the zip (y-1)',   'contains(studyRel, ''animal_study'')',                    true,                    0
    'folder path (y-1)',             'studyRel',                                       [],                      0
    '.fdt files in the zip (y-1)',   'fdtCount',                                       ref.ready.fdt_files,     0
    '.dat and .dat* files (y-1)',    'datCount',                                       @(n) n >= nDat,          0     % more after study-precompute ran
    'dataset files',                 'numel(files)',                                   ref.ready.nfiles,        0
    'same sampling rate',            'A.srate == B.srate',                             true,                    0
    'sampling rate (Hz)',            'A.srate',                                        ref.ready.srate,         0
    'same channel count',            'A.nbchan == B.nbchan',                           true,                    0
    'channels',                      'A.nbchan',                                       ref.ready.nbchan,        0
    'epoch window (s)',              '[A.xmin A.xmax]',                                ref.ready.xminmax,       0.001
    'same epoch window',             'isequal([A.xmin A.xmax], [B.xmin B.xmax])',       true,                    0
    'same channel labels',           'isequal({A.chanlocs.labels}, {B.chanlocs.labels})', true,                 0
    'ICA weights present',           '~isempty(A.icaweights)',                         ref.ready.has_ica,       0
    'dipoles present',               'isfield(A.dipfit, ''model'')',                   ref.ready.has_dipfit,    0
    };
e.log = {
    'folder printed',                'Go-nogo STUDY folder: '
    'file count printed',            '\d+ dataset files under '
    };
e.scripts = {'check_d6_study'};   % writes assets-src/study/d6_facts.txt (licence and file names: run_checklist 4b)
end
