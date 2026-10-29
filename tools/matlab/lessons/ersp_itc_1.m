% Copied from lessons/en/06-04-ersp-itc.md. The lesson is the reference.
% ERSP and ITC at Cz, 3 to 30 Hz, wavelets from 3 cycles
cz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));
figure;
[ersp, itc, powbase, times, freqs] = pop_newtimef(EEG, 1, cz, ...
    [EEG.xmin EEG.xmax]*1000, [3 0.8], 'freqs', [3 30], 'winsize', 128, ...
    'baseline', 0, 'padratio', 1, 'plotphase', 'off');

% ersp: frequencies x times in dB; itc: complex, its magnitude is 0 to 1
itcMag = abs(itc);
fprintf('Frequencies %.1f to %.1f Hz, times %.0f to %.0f ms\n', ...
    freqs(1), freqs(end), times(1), times(end));

% Where is the phase locking strongest?
[maxItc, idx] = max(itcMag(:));
[fi, ti] = ind2sub(size(itcMag), idx);
fprintf('Max ITC %.2f at %.1f Hz, %.0f ms\n', maxItc, freqs(fi), times(ti));
