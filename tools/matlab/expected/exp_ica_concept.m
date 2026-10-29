function e = exp_ica_concept()
% Expected results for lesson ica-concept (04-01). No Starting point: the optional script makes three
% sources, mixes them into three channels and unmixes them with runica. Nothing is saved.
% Each component should match one source: the largest absolute correlation in every row and every
% column of corr(act', S') is above 0.95 (simulation gives about 1.00). corrcoef avoids the
% Statistics Toolbox.

e.run = {1, 'R = corrcoef([act; S]''); R = abs(R(1:3, 4:6));'};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'three components',              'size(act, 1)',                                   3,                       0
    'each component matches a source', 'all(max(R, [], 2) > 0.95)',                    true,                    0
    'each source has a component',   'all(max(R, [], 1) > 0.95)',                      true,                    0
    'best correlation per component', 'max(R, [], 2)''',                               [],                      0
    'six axes drawn',                'numel(findobj(gcf, ''Type'', ''axes''))',        6,                       0
    };
e.log = cell(0, 2);
e.scripts = {};
end
