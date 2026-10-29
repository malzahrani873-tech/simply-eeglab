% Copied from lessons/en/01-01-install-eeglab.md. The lesson is the reference.
% Go to the EEGLAB folder (change the path to yours)
cd('C:\Users\me\Documents\MATLAB\eeglab2026.1');

% Save the root EEGLAB folder in the path BEFORE starting EEGLAB,
% so its subfolders are not saved too
addpath(pwd);
savepath;

% Start EEGLAB; it adds its own subfolders for this session only
eeglab;

% Install Biosig only if it is not installed yet (needs internet)
if ~exist('sopen', 'file')
    plugin_askinstall('Biosig', 'sopen', true);
end
