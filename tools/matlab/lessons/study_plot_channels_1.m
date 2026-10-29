% Copied from lessons/en/08-06-study-plot-channels.md. The lesson is the reference.
% STUDY and ALLEEG come from the starting point script (design 2 is current)
names = {STUDY.changrp.name};
pz = names(strcmpi(names, 'Pz'));
oz = names(strcmpi(names, 'Oz'));

% Group ERP at Pz: both pictures on one panel, one panel per gender (design 2)
STUDY = pop_erpparams(STUDY, 'plotconditions', 'together', 'plotgroups', 'apart', 'topotime', []);
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'design', 2);

% The same channel for every participant
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', pz, 'plotsubjects', 'on', 'design', 2);

% Scalp maps of the mean ERP from 150 to 250 ms, all participants together (design 3)
STUDY = pop_erpparams(STUDY, 'topotime', [150 250]);
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', names, 'design', 3);
STUDY = pop_erpparams(STUDY, 'topotime', []);

% Group spectrum at Oz and ERSP at Pz (design 3)
STUDY = pop_specparams(STUDY, 'plotconditions', 'together', 'freqrange', [3 40]);
STUDY = std_specplot(STUDY, ALLEEG, 'channels', oz, 'design', 3);
STUDY = std_erspplot(STUDY, ALLEEG, 'channels', pz, 'design', 3);
