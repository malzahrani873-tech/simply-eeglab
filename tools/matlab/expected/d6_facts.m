function f = d6_facts()
% D6_FACTS  Facts of dataset D6 (Go-nogo categorization and detection task, Delorme), used by the
% station 8 expected files and by check_d6_study.m.
%
% raw: OpenNeuro ds002680 v1.2.0 (CC0), read from dataset_description.json, participants.tsv and the
% sub-*/ses-*/eeg sidecar files. ready: the version prepared as a STUDY on the EEGLAB data page; its
% values are recorded on the run day by check_d6_study.m ([] = record only, no check yet).

% --- Raw BIDS dataset (ds002680) --------------------------------------------------------
f.raw.name        = 'Go-nogo categorization and detection task';
f.raw.license     = 'CC0';
f.raw.doi         = '10.18112/openneuro.ds002680.v1.2.0';
f.raw.subjects    = arrayfun(@(k) sprintf('sub-%03d', k), 2:15, 'UniformOutput', false);
f.raw.nsubjects   = 14;
f.raw.gender      = {'F','F','F','M','M','M','F','F','M','F','M','F','M','M'};   % participants.tsv order
f.raw.nfemale     = 7;
f.raw.nmale       = 7;
f.raw.nbchan      = 31;            % all typed MISC in channels.tsv
f.raw.srate       = 1000;
f.raw.linefreq    = 50;
f.raw.system      = 'Neuroscan Synamps 1 (model 5083)';
f.raw.sessions    = {'ses-01', 'ses-02'};
f.raw.runs        = [13 12];       % runs per session, every participant
f.raw.trials_per_run = 100;        % 50 targets and 50 distractors
f.raw.run1_seconds = 206.44;       % sub-002 ses-01 run-1 (eeg.json RecordingDuration)
% Event values (column "value"): categorization task, then the three recognition tasks
f.raw.categorization = {'animal_target', 'animal_distractor'};
f.raw.recognition    = {'easy_target', 'easy_distractor', 'difficult_target', 'difficult_distractor', ...
                        'nonanimal_target', 'nonanimal_distractor'};
f.raw.responses      = {'correct', 'incorrect'};
% On OpenNeuro, ses-02 runs 1-12 have the same events.tsv as ses-01 (checked for sub-002, sub-005 and
% sub-010) and sub-002 run-1 has identical signal in both sessions. Lessons on the raw data use ses-01.
f.raw.ses02_duplicates_ses01 = true;

% --- Ready STUDY version (EEGLAB data page) ----------------------------------------------
f.ready.nsubjects = 14;            % same participants as ds002680 (curriculum section 9.2)
f.ready.nfiles    = 28;            % one file per participant and condition, animal and distractor (lesson study-concepts)
% Values below read from animal_study.zip on 2026-10-28 (assets/network_check.md, decision m q-18)
f.ready.nbchan    = 32;
f.ready.srate     = 250;
f.ready.conditions = {'animal', 'distractor'};
f.ready.has_ica   = true;          % authors' ICA: 31 x 32 weights, 29 x 32 for cba; used as is
f.ready.ncomps    = 31;            % except cba (29)
f.ready.has_dipfit = true;         % 31 models per file, but hdmfile is an old absolute path: fitted again
f.ready.size_gb   = 0.73;          % unzipped folder, 729,275,275 bytes (zip: 656,622,733)
f.ready.xminmax   = [-1 1.996];     % 750 points
f.ready.top_folder = 'animal_study';
f.ready.fdt_files = 0;             % data in .dat files (inside the .set for cba)
f.ready.dat_files = 138;           % 26 .dat + 28 each of .daterp .datersp .datitc .datspec (EEGLAB 6)
end
