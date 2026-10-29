function e = exp_publication_figures()
% Expected results for lesson publication-figures (07-04). D1 epochs clean.
% No value checks yet: the run records whether the lesson code runs without error, and the figure
% script writes the facts used to check the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = cell(0, 4);
e.log = cell(0, 2);
e.scripts = {'fig_publication_figures'};
end
