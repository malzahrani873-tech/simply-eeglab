function e = exp_study_export_results()
% Expected results for lesson study-export-results (08-08), ready Go-nogo STUDY (D6). The first lines
% of the CSV file are copied into the log (header, participant codes, channel names).

e.run = {'start', 1, ['csvLines = splitlines(fileread(csvFile)); ' ...
    'csvHead = strjoin(csvLines(1:min(6, end)), '' | '');']};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'rows',                          'height(T)',                                      56,                      0
    'rows for F',                    'nnz(strcmp(T.gender, ''F''))',                   28,                      0
    'CSV file written',              'exist(fullfile(studyDir, ''erp_150_250_mean.csv''), ''file'')', 2,          0
    'CSV header (8.8-1)',            'csvLines{1}',                                    'subject,gender,condition,channel,mean_uV', 0
    'CSV first lines (8.8-2)',       'csvHead',                                        [],                      0
    };
e.log = {
    'rows printed',                  '56 rows written to '
    'Pz means printed (8.8-4)',      'Pz animal: mean -?\d+\.\d\d uV'
    };
e.scripts = {};
end
