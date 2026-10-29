function cfg = sea_config()
% SEA_CONFIG  Settings for the Simply EEGLAB asset scripts. This is the only file to edit.
%
% Every script in tools/matlab reads its paths from here. Datasets are downloaded outside the
% site repository (no EEG data is committed); PNG output goes to assets-src/ at the repository
% root and is converted to WebP by tools/python/convert_and_check.py.

here = fileparts(mfilename('fullpath'));          % .../tools/matlab
cfg.root = fileparts(fileparts(here));            % repository (or project) root

% --- EEGLAB ---------------------------------------------------------------
% Leave empty when EEGLAB is already on the MATLAB path.
cfg.eeglab = '';                                  % e.g. 'C:\toolbox\eeglab2026.1.0'
cfg.eeglab_version = '2026.1';                    % version the lessons are written for
cfg.iclabel_min = 1.6;                            % ICLabel 1.5 has a known bug

% --- Datasets (outside the repository) ------------------------------------
if ispc, home = getenv('USERPROFILE'); else, home = getenv('HOME'); end
cfg.datadir = fullfile(home, 'simplyeeglab-data');
% A one-line file local_datadir.txt next to this file overrides the data folder (written by runday_setup,
% so that screenshots of file dialogs do not show the user's home folder).
override = fullfile(here, 'local_datadir.txt');
if exist(override, 'file')
    cfg.datadir = strtrim(fileread(override));
end
% D1: eeglab_data.set ships with EEGLAB (resolved in sea_init).
cfg.d1 = '';
% D2: PhysioNet EEGMMIDB, one file (ODC-By 1.0)
%     https://physionet.org/files/eegmmidb/1.0.0/S001/S001R03.edf
cfg.course_dir = fullfile(cfg.datadir, 'eeg-course');   % dataFolder in the lesson code
cfg.d2 = fullfile(cfg.course_dir, 'S001R03.edf');
% D4: OpenNeuro ds002718 (CC0), one .set file per subject
%     https://openneuro.org/datasets/ds002718
cfg.d4_dir = fullfile(cfg.datadir, 'ds002718');
cfg.d4_subjects = {'sub-002'};                    % add subjects if a class is short (heart, line noise)
cfg.d4_file = @(sub) fullfile(cfg.d4_dir, sub, 'eeg', [sub '_task-FaceRecognition_eeg.set']);
% Non-EEG channels in ds002718 (channels.tsv): excluded from reference and ICA
cfg.d4_eog = {'EEG061', 'EEG062'};                % HEOG, VEOG
cfg.d4_ecg = {'EEG063', 'EEG064'};

% --- Lessons (verify_batch) ----------------------------------------------
cfg.lessons = fullfile(cfg.root, 'lessons');      % lesson files: lessons/en and lessons/ar
% Example paths used in lesson code, and what replaces them in automated runs
cfg.lesson_paths = { ...
    'C:\Users\me\Documents\eeg-course', cfg.course_dir};

% --- Output ----------------------------------------------------------------
cfg.out  = fullfile(cfg.root, 'assets-src');      % PNG before conversion
cfg.work = fullfile(cfg.datadir, 'work');         % intermediate datasets (not uploaded)
cfg.dpi  = 150;                                   % export resolution for lesson figures

% --- Processing choices (same as the lessons) ----------------------------
cfg.ica_hp = 1;      % high-pass before ICA (Hz)
cfg.erp_hp = 0.1;    % main dataset
cfg.erp_lp = 30;     % applied only after removing ICA components
cfg.notch  = [58 62];                             % 60 Hz line noise in D1, band-stop ('revfilt', 1)
cfg.d1_eog = {'EOG1', 'EOG2'};                    % excluded from the average reference
cfg.ica_opts = {'icatype', 'runica', 'extended', 1, 'rndreset', 'no'};
% 'rndreset','no' fixes the random seed so figures are reproducible. By default runica.m (line 205)
% seeds from the clock and component order can change between runs. Lessons keep the default.

% --- ICA game images ------------------------------------------------------
cfg.game.w = 720; cfg.game.h = 280;               % pixels
cfg.game.freq = [1 80];                           % spectrum axis (Hz)
cfg.game.seconds = 5;                             % time-series length (s)
cfg.game.level1 = 0.8;                            % top ICLabel probability for level 1
cfg.game.level2 = 0.6;                            % 0.6 to 0.8 for level 2
end
