function e = exp_automated_pipelines()
% Expected results for lesson automated-pipelines (09-04). Needs PrepPipeline (plugin batch).
% No value checks yet: the run records whether the lesson code runs without error, and the figure
% script writes the facts used to check the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = cell(0, 4);
e.log = cell(0, 2);
e.scripts = {'fig_automated_pipelines'};
end
