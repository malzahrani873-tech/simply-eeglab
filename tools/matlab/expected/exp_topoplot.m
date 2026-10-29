function e = exp_topoplot()
% Expected results for lesson topoplot (07-01). D1 epochs clean.
% Values from the lesson script. The figure script writes the facts for the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'channels after pop_select',     'EEG.nbchan',                                     30,                      0
    };
e.log = cell(0, 2);
e.scripts = {'fig_topoplot'};
end
