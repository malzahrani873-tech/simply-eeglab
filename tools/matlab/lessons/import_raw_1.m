% Copied from lessons/en/02-01-import-raw.md. The lesson is the reference.
% BioSemi BDF: pick a temporary reference at import. Here: the average of
% the external mastoid electrodes EXG1 and EXG2 (channels 65 and 66 in a
% 64-channel cap). Check the channel order of your own montage.
EEG = pop_biosig(fullfile(dataFolder, 'sub01.bdf'), 'ref', [65 66]);

% BrainVision: give the folder and the .vhdr header file (needs bva-io)
EEG = pop_loadbv(dataFolder, 'sub01.vhdr');
