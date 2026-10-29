% FIG_ERSP_ITC  Figure for lesson ersp-itc from D1: Plot > Channel time-frequency on 'D1 epochs clean',
%   channel Cz, with the lesson's settings (3 to 30 Hz, wavelets from 3 cycles, default colormap).
%   This is the EEGLAB figure itself, exported at a fixed size, in place of a screenshot.
%
% Output in assets-src/lessons/ersp-itc/:
%   ersp-itc-cz.png
%   facts.txt   frequency and time range, largest ITC and where it is

cfg = sea_init();
ep = sea_epochs(cfg);
EEG = ep.clean;
rel = fullfile('lessons', 'ersp-itc');
cz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));

figure;
tflog = evalc(['[ersp, itc, powbase, times, freqs] = pop_newtimef(EEG, 1, cz, [EEG.xmin EEG.xmax] * 1000, ' ...
    '[3 0.8], ''freqs'', [3 30], ''winsize'', 128, ''baseline'', 0, ''padratio'', 1, ''plotphase'', ''off'');']);
colormap(cfg.colormap);
sea_export(gcf, cfg, fullfile(rel, 'ersp-itc-cz.png'), [900 820]);

itcMag = abs(itc);
[mx, idx] = max(itcMag(:));
[fi, ti] = ind2sub(size(itcMag), idx);
cyc = regexp(tflog, 'Using [^\n]*cycles[^\n]*', 'match', 'once');
fid = fopen(fullfile(cfg.out, rel, 'facts.txt'), 'w');
fprintf(fid, '%s\nchannel: %s (index %d), epochs %d\nfrequencies %.1f to %.1f Hz, times %.0f to %.0f ms, %d time points\nmax ITC %.2f at %.1f Hz, %.0f ms\n%s\n', ...
    cfg.stamp, EEG.chanlocs(cz).labels, cz, EEG.trials, freqs(1), freqs(end), times(1), times(end), numel(times), ...
    mx, freqs(fi), times(ti), cyc);
fclose(fid);
type(fullfile(cfg.out, rel, 'facts.txt'));
