function e = exp_mne_fieldtrip()
% Expected results for lesson mne-fieldtrip (10-05). Needs FieldTrip on the MATLAB path: the Fieldtrip-lite
% plugin in batch plugins, or full FieldTrip in batch fieldtrip-full.
% Values from the lesson script. The figure script writes the facts for the lesson text.

e.run = {'start', 1};
e.paths = cell(0, 2);
e.checks = {
    % label                          expression                                        expected                 tol
    'FieldTrip matches EEGLAB',      'maxDiff < 1e-3',                                 true,                    0
    'channels in FieldTrip data',    'numel(data.label)',                              32,                      0
    };
e.log = cell(0, 2);
e.scripts = {'fig_mne_fieldtrip'};
end
