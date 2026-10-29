function e = exp_channel_erp_plot()
% Expected results for lesson channel-erp-plot (07-02). D1 epochs clean.
% Values from the lesson script. The figure script writes the facts for the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'positions add up to all trials', 'EEG_pos1.trials + EEG_pos2.trials == EEG.trials', true,                 0
    };
e.log = cell(0, 2);
e.scripts = {'fig_channel_erp_plot'};
end
