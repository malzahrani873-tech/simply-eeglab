function e = exp_channel_locations()
% Expected results for lesson channel-locations (02-02), D2 (S001R03.set saved by import-raw).
% Values from notes_stations_1-2.md (t-13, t-16). Block 1 is the short GUI-path snippet; block 2 is
% the full script, which reloads the file, so the labels are recorded right after the Starting point.

e.run = {'start', 'labelsBefore = {EEG.chanlocs(1:3).labels};', 2};
e.paths = cell(0, 2);
e.checks = {
    % label                      expression                                         expected                    tol
    'labels before (dots)',      'labelsBefore',                                    {'Fc5.', 'Fc3.', 'Fc1.'},   0
    'labels after',              '{EEG.chanlocs(1:3).labels}',                      {'Fc5', 'Fc3', 'Fc1'},      0
    'channels',                  'EEG.nbchan',                                      64,                         0
    'all channels located',      'all(~cellfun(@isempty, {EEG.chanlocs.X}))',       true,                       0
    };
e.log = {};
e.scripts = {'fig_channel_locations'};
end
