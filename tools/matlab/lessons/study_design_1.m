% Copied from lessons/en/08-04-study-design.md. The lesson is the reference.
% STUDY and ALLEEG come from the starting point script
% Design 2: image (within subjects) x gender (between subjects)
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name', 'image x gender', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'group', 'values2', {'F', 'M'}, 'vartype2', 'categorical');

% Design 3: image only, all participants in one group
STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name', 'image only', ...
    'variable1', 'condition', 'values1', {'animal', 'distractor'}, 'vartype1', 'categorical', ...
    'variable2', 'none');

% Make design 2 the current design and save
STUDY = std_selectdesign(STUDY, ALLEEG, 2);
STUDY = pop_savestudy(STUDY, ALLEEG, 'savemode', 'resave');

% Every design with its variables, values and pairing
for k = 1:numel(STUDY.design)
    d = STUDY.design(k);
    fprintf('Design %d: %s\n', k, d.name);
    for v = 1:numel(d.variable)
        if ~isempty(d.variable(v).label)
            fprintf('   %-10s paired: %-4s values: %s\n', d.variable(v).label, ...
                d.variable(v).pairing, strjoin(d.variable(v).value, ' '));
        end
    end
end
fprintf('Current design: %d\n', STUDY.currentdesign);
eeglab redraw;
