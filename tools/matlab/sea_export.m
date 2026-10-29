function file = sea_export(fig, cfg, relpath, sizepx)
% SEA_EXPORT  Export a figure to assets-src/<relpath> on a white background, then close it.
%   sizepx = [width height] in final pixels (optional). With sizepx the PNG is written at exactly
%   that size (print -r0, no cropping), so both images of a before/after pair share one frame.
%   Without it, exportgraphics crops to the content. File size is checked after WebP conversion.
file = fullfile(cfg.out, relpath);
if ~exist(fileparts(file), 'dir'), mkdir(fileparts(file)); end
if nargin > 3 && ~isempty(sizepx)
    set(fig, 'Units', 'pixels', 'Position', [50 50 sizepx], 'Color', 'w', ...
        'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
    drawnow;
    print(fig, file, '-dpng', '-r0');
else
    exportgraphics(fig, file, 'Resolution', cfg.dpi, 'BackgroundColor', 'white');
end
close(fig);
fprintf('[sea] saved %s\n', file);
end
