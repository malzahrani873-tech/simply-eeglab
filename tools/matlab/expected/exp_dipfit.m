function e = exp_dipfit()
% Expected results for lesson dipfit (10-01). D1 main with ICA weights; DIPFIT ships with EEGLAB.
% Values from the lesson script. The figure script writes the facts for the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'dipole models',                 'numel(EEG.dipfit.model)',                        31,                      0
    'coordinate transform',          'EEG.dipfit.coord_transform',                     [0 0 0 0 0 -1.5708 1 1 1], 1e-3
    };
e.log = cell(0, 2);
e.scripts = {'fig_dipfit'};
end
