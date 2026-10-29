function sea_note(id, text)
% SEA_NOTE  Record a note for a run-checklist item, so it lands in the diary file with all output.
%   sea_note('B3', 'Channel locations: No (labels only)')
fprintf('NOTE %-4s %s\n', id, text);
end
