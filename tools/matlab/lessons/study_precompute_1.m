% Copied from lessons/en/08-05-study-precompute.md. The lesson is the reference.
% STUDY and ALLEEG come from the starting point script
% ERSP and ITC at two channels only, to keep the files small
labels    = {ALLEEG(1).chanlocs.labels};
erspChans = labels(ismember(lower(labels), {'pz', 'oz'}));
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, erspChans, 'savetrials', 'on', 'recompute', 'on', ...
    'ersp', 'on', 'itc', 'on', 'erspparams', {'cycles', [3 0.8], 'nfreqs', 50, 'ntimesout', 100});

% ERPs and spectra at all channels (same choices as the GUI); run last so that
% the STUDY channel list holds every channel
baseline = [round(ALLEEG(1).xmin*1000) 0];   % from the epoch start to 0 ms
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {}, 'savetrials', 'on', 'interp', 'on', 'recompute', 'on', ...
    'erp', 'on', 'erpparams', {'rmbase', baseline}, ...
    'spec', 'on', 'specparams', {'specmode', 'fft', 'logtrials', 'off'});
STUDY = pop_savestudy(STUDY, ALLEEG, 'savemode', 'resave');

% Files written for the first participant, with their size on disk
first = STUDY.datasetinfo(1);
measureFiles = dir(fullfile(first.filepath, [first.subject '.dat*']));
for k = 1:numel(measureFiles)
    fprintf('%-24s %8.1f MB\n', measureFiles(k).name, measureFiles(k).bytes/1e6);
end
fprintf('Channel groups in the STUDY: %d\n', numel(STUDY.changrp));
