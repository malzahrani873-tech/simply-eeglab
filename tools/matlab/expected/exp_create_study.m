function e = exp_create_study()
% Expected results for lesson create-study (08-02), ready Go-nogo STUDY (D6).
% Final state of the lesson: animal_mine.study saved and reloaded, CURRENTSTUDY = 1, every dataset selected.

ref = d6_facts();
% The extra steps measure the STUDY folder before and after the lesson saves the datasets (review 13 y-3):
% resaving converts the old .dat files to the current format, one 'Deleting old .dat' line per file.
e.run = {'start', ['d = dir(fullfile(studyDir, ''**'', ''*'')); mbBefore = sum([d(~[d.isdir] & ~startsWith({d.name}, ''._'')).bytes]) / 1e6;'], 1, ...
    ['d = dir(fullfile(studyDir, ''**'', ''*'')); mbAfter = sum([d(~[d.isdir] & ~startsWith({d.name}, ''._'')).bytes]) / 1e6; ' ...
     'datLeft = nnz(~startsWith({d.name}, ''._'') & endsWith({d.name}, ''.dat'')); clear d']};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'CURRENTSTUDY',                  'CURRENTSTUDY',                                   1,                       0
    'all datasets selected',         'numel(CURRENTSET) == numel(ALLEEG)',              true,                    0
    'datasets in STUDY',             'numel(STUDY.datasetinfo)',                       ref.ready.nfiles,        0
    'subjects',                      'numel(STUDY.subject)',                           ref.ready.nsubjects,     0
    'conditions',                    'sort(STUDY.condition)',                          {'animal', 'distractor'}, 0
    'groups',                        'sort(STUDY.group)',                              {'F', 'M'},              0
    'STUDY name',                    'STUDY.name',                                     'Go-nogo animal (mine)', 0
    'design 1 name',                 'STUDY.design(1).name',                           'STUDY.design 1',        0
    'current design',                'STUDY.currentdesign',                            1,                       0
    'saved animal_mine.study',       'exist(fullfile(studyDir, ''animal_mine.study''), ''file'')', 2,           0
    'old .dat files left (y-3)',     'datLeft',                                        0,                       0
    'folder MB before, after (y-3)', '[mbBefore mbAfter]',                             [],                      0
    };
e.log = {
    'summary printed',               '\d+ datasets, \d+ subjects, conditions: \w+ \w+, groups: F M'
    'old .dat converted (y-3)',      'Deleting old \.dat file format detected on disk'
    };
e.scripts = {};
end
