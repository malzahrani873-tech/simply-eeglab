function e = exp_ic_clustering()
% Expected results for lesson ic-clustering (08-09), ready Go-nogo STUDY (D6). The ready files already
% hold the authors' ICA weights (31 x 32, 29 x 32 for cba), used as is; sea_d6_ica fits the dipoles
% again (the stored head model path is outdated) and adds ICLabel, about 25 minutes.

% The first step records the head model path stored in the ready files before sea_d6_ica fits the
% dipoles again (review 13 y-4).
e.run = {['hd = dir(fullfile(sea_config().course_dir, ''**'', ''sphanimal.set'')); ' ...
    'hdr = pop_loadset(''filename'', hd(1).name, ''filepath'', hd(1).folder, ''loadmode'', ''info''); ' ...
    'oldHdm = hdr.dipfit.hdmfile; oldHdmFound = exist(oldHdm, ''file''); clear hd hdr'], ...
    'sea_d6_ica;', 'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'ICA weights present',           '~isempty(ALLEEG(1).icaweights)',                 true,                    0
    'same weights for a participant', 'isequal(ALLEEG(1).icaweights, ALLEEG(find(strcmp({ALLEEG.subject}, ALLEEG(1).subject), 1, ''last'')).icaweights)', [], 0
    'shared ICA for every participant (y-13)', 'all(arrayfun(@(k) isequal(ALLEEG(k).icaweights, ALLEEG(find(strcmp({ALLEEG.subject}, ALLEEG(k).subject), 1)).icaweights), 1:numel(ALLEEG)))', [], 0
    'participants sharing ICA (y-1)', 'sprintf(''Shared ICA: %d of %d participants'', nnz(cellfun(@(s) isequal(ALLEEG(find(strcmp({ALLEEG.subject}, s), 1)).icaweights, ALLEEG(find(strcmp({ALLEEG.subject}, s), 1, ''last'')).icaweights), unique({ALLEEG.subject}))), numel(unique({ALLEEG.subject})))', [], 0
    'old head model path (y-4)',     'oldHdm',                                         [],                      0
    'old head model missing (y-4)',  'oldHdmFound',                                    0,                       0
    'components per dataset (ICA)', 'unique(cellfun(@(w) size(w, 1), {ALLEEG.icaweights}))', [29 31],       0
    'dipoles present',               'isfield(ALLEEG(1).dipfit, ''model'')',           true,                    0
    'more than two clusters',        'numel(STUDY.cluster) > 2',                       true,                    0
    'components kept per dataset',   '[median(nComps) min(nComps) max(nComps)]',       [],                      0
    'at least one component each (8.9-3)', 'min(nComps) >= 1',                        true,                    0
    'clusters',                      'numel(STUDY.cluster)',                           [],                      0
    };
e.log = {
    'ICA time printed (8.9-1)',      '\[sea\] D6(:)? (ICA, )?dipoles and ICLabel(: \d+ min| already present)'
    'cluster lines (8.9-4)',         '\d+ ICs from\s+\d+ participants, median brain probability'
    };
e.scripts = {'fig_ic_clustering'};
end
