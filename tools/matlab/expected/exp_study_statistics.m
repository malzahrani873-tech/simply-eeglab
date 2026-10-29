function e = exp_study_statistics()
% Expected results for lesson study-statistics (08-07), ready Go-nogo STUDY (D6).

e.run = {'start', 1, 'statsToolbox = license(''test'', ''Statistics_Toolbox'');'};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'condition statistics on',       'STUDY.etc.statistics.condstats',                 'on',                    0
    'FDR correction',                'STUDY.etc.statistics.eeglab.mcorrect',           'fdr',                   0
    'FDR keeps fewer points',        'nnz(maskFdr{1}) <= nnz(maskRaw{1})',             true,                    0
    'some points pass FDR',          'nnz(maskFdr{1}) > 0',                            true,                    0
    'Pz in the STUDY',               'numel(pz) == 1',                                 true,                    0
    'points uncorrected',            'nnz(maskRaw{1})',                                [],                      0
    'points after FDR',              'nnz(maskFdr{1})',                                [],                      0
    'Statistics Toolbox (8.7-4)',    'statsToolbox',                                   [],                      0
    'one map value per channel (y-14)', 'numel(maskMap{1}) == numel(names)',           true,                    0
    'channels after FDR (y-14)',     'strjoin(names(maskMap{1} > 0), '' '')',          [],                      0
    };
e.log = {
    'points printed (8.7-3)',        'Significant time points at Pz: \d+ uncorrected, \d+ after FDR'
    'channels printed (8.7-5)',      'Channels with a significant 150-250 ms difference after FDR'
    'interaction printed (8.7-7)',   'Interaction time points after FDR: \d+'
    };
e.scripts = {'fig_study_statistics'};
end
