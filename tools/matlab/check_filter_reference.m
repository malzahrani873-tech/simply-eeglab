% CHECK_FILTER_REFERENCE  Order, transition band and -6 dB cutoff of pop_eegfiltnew for the filter
%   settings of the interactive filter demo, at 250 Hz, so its unit test can compare against EEGLAB itself.
%   Runs on one channel of random noise (120 s); the filter design does not depend on the data.
%
% Output in assets-src/interactives/:
%   filter_reference.json   one entry per setting: type, edge, order, points, df, cutoff
%   filter_reference.txt    the same as a table, with PASS/FAIL against the values the demo uses
% Time: under a minute.

cfg = sea_init();
fs = 250;
% type, passband edge (Hz), expected order, expected -6 dB cutoff (Hz)
settings = {
    'highpass', 0.1,  8250, 0.05
    'highpass', 0.5,  1650, 0.25
    'highpass', 1,     826, 0.5
    'highpass', 2,     414, 1.0
    'lowpass',  20,    166, 22.5
    'lowpass',  30,    110, 33.75
    'lowpass',  40,     84, 44.9
    };

EEG = eeg_emptyset();
EEG.srate = fs;
EEG.nbchan = 1;
EEG.trials = 1;
EEG.data = randn(1, 120 * fs);
EEG.pnts = size(EEG.data, 2);
EEG.xmin = 0;
EEG = eeg_checkset(EEG);

rows = struct('type', {}, 'edge_hz', {}, 'order', {}, 'points', {}, 'df_hz', {}, 'cutoff_hz', {});
lines = cell(size(settings, 1), 1);
nFail = 0;
for k = 1:size(settings, 1)
    [type, edge, expOrder, expCut] = settings{k, :};
    if strcmp(type, 'highpass')
        args = {'locutoff', edge};
    else
        args = {'hicutoff', edge};
    end
    txt = evalc('[~, ~, b] = pop_eegfiltnew(EEG, args{:});');
    df = str2double(regexp(txt, 'transition band width: ([\d.eE+-]+) Hz', 'tokens', 'once'));
    cutoff = str2double(regexp(txt, 'cutoff frequency\(ies\) \(-6 dB\): ([\d.eE+-]+) Hz', 'tokens', 'once'));
    order = numel(b) - 1;
    rows(end + 1) = struct('type', type, 'edge_hz', edge, 'order', order, 'points', numel(b), ...
        'df_hz', df, 'cutoff_hz', cutoff); %#ok<SAGROW>
    ok = order == expOrder && abs(cutoff - expCut) <= 0.05;
    nFail = nFail + ~ok;
    status = 'PASS';
    if ~ok, status = 'FAIL'; end
    lines{k} = sprintf('%-8s %6.2f Hz | order %5d (demo %5d) | df %.4f Hz | cutoff %.4f Hz (demo %.2f) | %s', ...
        type, edge, order, expOrder, df, cutoff, expCut, status);
end

out = fullfile(cfg.out, 'interactives');
if ~exist(out, 'dir'), mkdir(out); end
ref = struct('fs_hz', fs, 'source', cfg.stamp, 'matlab', version, 'function', 'pop_eegfiltnew', 'settings', rows);
try
    json = jsonencode(ref, 'PrettyPrint', true);   % R2021a and later
catch
    json = jsonencode(ref);
end
fid = fopen(fullfile(out, 'filter_reference.json'), 'w');
fprintf(fid, '%s\n', json);
fclose(fid);
fid = fopen(fullfile(out, 'filter_reference.txt'), 'w');
fprintf(fid, '%s\nMATLAB %s\nfs = %d Hz\n%s\n%d of %d settings differ from the demo\n', cfg.stamp, version, fs, strjoin(lines, newline), ...
    nFail, size(settings, 1));
fclose(fid);
type(fullfile(out, 'filter_reference.txt'));
