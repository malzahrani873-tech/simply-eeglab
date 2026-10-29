function e = exp_study_plot_channels()
% Expected results for lesson study-plot-channels (08-06). Ready Go-nogo STUDY (D6), after study-precompute.
% No value checks yet: the run records whether the lesson code runs without error, and the figure
% script writes the facts used to check the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = cell(0, 4);
e.log = cell(0, 2);
e.scripts = {'fig_study_plot_channels', 'fig_quiz'};   % fig_quiz needs D2, the D1 work files and this STUDY
end
