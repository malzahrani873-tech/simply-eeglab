function cfg = sea_init()
% SEA_INIT  Start EEGLAB without its window and check versions before any asset script.
%
% Stops with a clear message when:
%   - EEGLAB is not found (a version other than 2026.1 only warns)
%   - ICLabel is older than 1.6, or firfilt is missing
% Appends one line with the versions to assets-src/RUN_LOG.txt.

cfg = sea_config();
if ~isempty(cfg.eeglab), addpath(cfg.eeglab); end
if ~exist('eeglab', 'file')
    error('sea:noeeglab', 'EEGLAB not found on the path. Set cfg.eeglab in sea_config.m');
end
if ~exist('pop_eegfiltnew', 'file') || ~exist('eeg_checkset', 'file')
    eeglab('nogui');                              % adds EEGLAB folders and plugins to the path
end

% --- Versions ----------------------------------------------------------------
vers = eeg_getversion;
if ~startsWith(vers, cfg.eeglab_version)
    warning('sea:version', 'EEGLAB %s, expected %s. Figures may not match the lessons.', vers, cfg.eeglab_version);
end
icl = 'missing';
f = which('eegplugin_iclabel');
if ~isempty(f)
    tok = regexp(fileread(f), 'ICLabel(\d+\.\d+)', 'tokens', 'once');
    if ~isempty(tok), icl = tok{1}; end
end
if strcmp(icl, 'missing') || str2double(icl) < cfg.iclabel_min
    error('sea:iclabel', 'ICLabel %s found; %.1f or newer is required (File > Manage EEGLAB extensions).', icl, cfg.iclabel_min);
end
if ~exist('pop_eegfiltnew', 'file')
    error('sea:firfilt', 'firfilt is not installed.');
end

% --- D1 ships with EEGLAB -------------------------------------------------------
if isempty(cfg.d1)
    cfg.d1 = fullfile(fileparts(which('eeglab')), 'sample_data', 'eeglab_data.set');
end

% --- Folders -----------------------------------------------------------------
for d = {cfg.out, cfg.work}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end

% --- Same figure defaults for every image ---------------------------------------
set(groot, 'defaultFigureColor', 'w', 'defaultAxesFontName', 'Helvetica', ...
    'defaultAxesFontSize', 9, 'defaultFigureVisible', 'off');
icadefs;                                           % DEFAULT_COLORMAP (turbo on recent MATLAB)
cfg.colormap = DEFAULT_COLORMAP;

cfg.stamp = sprintf('EEGLAB %s | ICLabel %s | MATLAB %s | %s', vers, icl, version('-release'), ...
    char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
fprintf('[sea] %s | colormap %s\n', cfg.stamp, cfg.colormap);
st = dbstack; caller = 'command line';
if numel(st) > 1, caller = st(2).name; end
fid = fopen(fullfile(cfg.out, 'RUN_LOG.txt'), 'a');
fprintf(fid, '%s | %s\n', cfg.stamp, caller);
fclose(fid);
end
