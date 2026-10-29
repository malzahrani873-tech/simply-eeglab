function logfile = verify_batch(batch, mode)
% VERIFY_BATCH  Run the code of a batch of lessons and check the results against expected values.
%
%   verify_batch('mvp')            % a batch defined in expected/batches.m
%   verify_batch('import-raw')     % a single lesson
%   verify_batch({'filtering', 'run-ica'})
%   verify_batch('all', 'force')  % run even if some data files are missing (their lessons will fail)
%
% Before the first lesson it checks that every data file the batch needs is present (sea_data.m) and
% stops with the list of missing files and how to get them. sea_download.m fetches them.
%
% For each lesson the script reads lessons/en/<NN>-<NN>-<slug>.md, then in a clean workspace:
%   1. runs the "Starting point" script (frontmatter field startingPoint.script),
%   2. runs the lesson code blocks listed in expected/exp_<slug>.m,
%   3. evaluates each check in that workspace and records PASS / FAIL / INFO with the actual value,
%   4. runs the asset scripts listed for the lesson (figures, extra checks).
% A failure never stops the run: the error is logged and the next step or lesson starts.
%
% Output, in the data folder (sea_config: cfg.datadir):
%   verify_<batch>_<date>.txt   one log: versions, summary, every check, full command output
%   verify_<batch>_<date>.zip   the log plus assets-src (figures and facts files) for upload

cfg = sea_init();
addpath(fullfile(fileparts(mfilename('fullpath')), 'expected'));
if ischar(batch) || isstring(batch)
    b = batches();
    name = char(batch);
    if isfield(b, matlab.lang.makeValidName(name))
        slugs = b.(matlab.lang.makeValidName(name));
    else
        slugs = {name};
    end
else
    slugs = batch;
    name = 'custom';
end

% Data files needed by these lessons (downloaded the evening before by sea_download)
items = sea_data(cfg);
items = items(arrayfun(@(it) any(ismember(it.lessons, slugs)), items));
absent = items(arrayfun(@(it) isempty(dir(it.check)), items));
if ~isempty(absent) && ~(nargin > 1 && strcmpi(mode, 'force'))
    msg = sprintf('%d data item(s) missing. Run sea_download, or verify_batch(''%s'', ''force'') to continue without them:', ...
        numel(absent), name);
    for it = absent(:)'
        how = it.how;
        if iscell(how), how = 'sea_download'; end
        msg = sprintf('%s\n  - %s\n    expected: %s\n    get it: %s', msg, it.name, it.check, how);
    end
    error('verify_batch:data', '%s', msg);
end

stamp = datestr(now, 'yyyymmdd-HHMM');
logfile = fullfile(cfg.datadir, sprintf('verify_%s_%s.txt', name, stamp));
fid = fopen(logfile, 'w', 'n', 'UTF-8');
cleanup = onCleanup(@() fclose_if_open(fid));
fprintf(fid, 'verify_batch %s\n%s\nlessons: %s\n\n', name, cfg.stamp, strjoin(slugs, ', '));

origDir = pwd;
results = struct('slug', {}, 'pass', {}, 'fail', {}, 'error', {}, 'seconds', {});
outputs = cell(1, numel(slugs));
for k = 1:numel(slugs)
    slug = slugs{k};
    fprintf('\n=== [%d/%d] %s ===\n', k, numel(slugs), slug);
    [r, lines, out] = verify_lesson(slug, cfg);
    cd(origDir);
    close all force;
    results(k) = r; %#ok<AGROW>
    outputs{k} = out;
    fprintf(fid, '--- %s  (%.0f s)  pass %d  fail %d%s\n', slug, r.seconds, r.pass, r.fail, ...
        ternary(isempty(r.error), '', ['  ERROR: ' r.error]));
    fprintf(fid, '%s\n', lines{:});
    fprintf(fid, '\n');
end

fprintf(fid, '=== SUMMARY ===\n');
for k = 1:numel(results)
    r = results(k);
    fprintf(fid, '%-28s pass %3d  fail %3d  %6.0f s  %s\n', r.slug, r.pass, r.fail, r.seconds, r.error);
end
fprintf(fid, 'total: pass %d  fail %d\n\n', sum([results.pass]), sum([results.fail]));

fprintf(fid, '=== COMMAND OUTPUT ===\n');
for k = 1:numel(slugs)
    fprintf(fid, '\n##### %s #####\n%s\n', slugs{k}, outputs{k});
end
fclose(fid);

% One upload: the log plus every figure and facts file, under assets-src/.
if ~exist(cfg.out, 'dir'), mkdir(cfg.out); end
copyfile(logfile, cfg.out);
zipfile = strrep(logfile, '.txt', '.zip');
[outRoot, outName] = fileparts(cfg.out);
zip(zipfile, {outName}, outRoot);
fprintf('\nDone. Upload this file:\n  %s\n', zipfile);
end

% -------------------------------------------------------------------------------------------------
function [r, lines, out] = verify_lesson(slug, cfg)
r = struct('slug', slug, 'pass', 0, 'fail', 0, 'error', '', 'seconds', 0);
lines = {};
out = '';
t0 = tic;
try
    e = feval(['exp_' strrep(slug, '-', '_')]);
catch err
    r.error = ['no expected file: ' err.message];
    lines{end + 1} = ['  ' r.error];
    return
end

% Run lesson code in a clean working folder, so files saved with pwd do not mix between lessons.
work = fullfile(cfg.work, slug);
if ~exist(work, 'dir'), mkdir(work); end
cd(work);

try
    [ws, out, stepErrors] = run_lesson(slug, e, cfg);
catch err
    ws = struct(); out = ''; stepErrors = {err.message};
end
for s = 1:numel(stepErrors)
    lines{end + 1} = ['  ERROR  ' stepErrors{s}]; %#ok<AGROW>
    r.fail = r.fail + 1;
end

% Decision m-q-11: a Starting point that changes the data must leave EEG.saved = 'no', so that
% File > Resave really saves. Added to every lesson whose Starting point calls a processing function.
runsStart = any(cellfun(@(x) ischar(x) && strcmp(x, 'start'), e.run));
if runsStart && start_modifies(slug, cfg)
    e.checks(end + 1, :) = {'saved = no after start (m-q-11)', 'startSavedFlag', 'no', 0};
end

% Value checks: {label, expression, expected, tolerance}
for c = 1:size(e.checks, 1)
    [label, expr, expected, tol] = e.checks{c, :};
    [status, actual] = check_value(ws, expr, expected, tol);
    lines{end + 1} = sprintf('  %-5s %-34s %s%s', status, label, actual, expected_text(expected, tol)); %#ok<AGROW>
    r = count(r, status);
end

% Log checks: {label, regular expression that must appear in the command output}
for c = 1:size(e.log, 1)
    [label, pattern] = e.log{c, :};
    hit = regexp(out, pattern, 'match', 'once');
    if isempty(hit)
        lines{end + 1} = sprintf('  FAIL  %-34s not found: %s', label, pattern); %#ok<AGROW>
        r.fail = r.fail + 1;
    else
        lines{end + 1} = sprintf('  PASS  %-34s %s', label, strtrim(hit)); %#ok<AGROW>
        r.pass = r.pass + 1;
    end
end

% Asset scripts (figures, extra measurements); their output goes to the log.
for s = 1:numel(e.scripts)
    try
        txt = evalc(e.scripts{s});
        out = sprintf('%s\n>>> %s\n%s', out, e.scripts{s}, txt);
        lines{end + 1} = sprintf('  DONE  %s', e.scripts{s}); %#ok<AGROW>
    catch err
        out = sprintf('%s\n>>> %s\nERROR: %s', out, e.scripts{s}, err.message);
        lines{end + 1} = sprintf('  ERROR %s: %s', e.scripts{s}, err.message); %#ok<AGROW>
        r.fail = r.fail + 1;
    end
    close all force;
end
r.seconds = toc(t0);
end

% -------------------------------------------------------------------------------------------------
function [ws, out, errors] = run_lesson(vbX_slug, vbX_e, vbX_cfg)
% Runs the starting point and the selected code blocks as one script in this function's workspace,
% then returns that workspace as a struct. Each step is wrapped in try/catch inside the script, so a
% failing step is logged and the next one still runs. The script path is kept in root appdata
% because lesson code may call "clear"; local names use the vbX_ prefix for the same reason.
vbX_file = build_script(vbX_slug, vbX_e, vbX_cfg);
setappdata(0, 'verify_batch_file', vbX_file);
try
    vbX_out = evalc('run(getappdata(0, ''verify_batch_file''))');
catch vbX_err
    vbX_out = sprintf('VERIFY-ERROR script: %s\n', vbX_err.message);
end
delete(getappdata(0, 'verify_batch_file'));
out = vbX_out;
errors = regexp(out, 'VERIFY-ERROR ([^\n]*)', 'tokens');
errors = cellfun(@(c) c{1}, errors, 'UniformOutput', false);
ws = struct();
vbX_vars = who;
for vbX_i = 1:numel(vbX_vars)
    if ~startsWith(vbX_vars{vbX_i}, 'vbX_') && ~any(strcmp(vbX_vars{vbX_i}, {'out', 'errors', 'ws'}))
        ws.(vbX_vars{vbX_i}) = eval(vbX_vars{vbX_i});
    end
end
end

function file = build_script(slug, e, cfg)
code = lesson_code(slug, cfg);
pairs = [cfg.lesson_paths; e.paths];
parts = {};
for i = 1:numel(e.run)
    step = e.run{i};
    if ischar(step) && strcmp(step, 'start')
        txt = [code.start newline 'startSavedFlag = ''''; ' ...
            'if exist(''EEG'', ''var'') && isstruct(EEG) && isfield(EEG, ''saved''), startSavedFlag = EEG(1).saved; end'];
        name = 'start';
    elseif ischar(step)
        txt = step;                     % extra check code from exp_<slug>.m, not from the lesson
        name = sprintf('extra %d', i);
    elseif iscell(step) && strcmp(step{1}, 'file')
        % {'file', n, 'name.m'}: the lesson asks the learner to save block n as a file. The block is
        % staged now and copied into the current folder when the script reaches this step.
        staged = fullfile(tempdir, sprintf('vbfile_%06d_%s', randi(999999), step{3}));
        fid = fopen(staged, 'w', 'n', 'UTF-8');
        fprintf(fid, '%s', code.blocks{step{2}});
        fclose(fid);
        txt = sprintf('copyfile(''%s'', fullfile(pwd, ''%s''), ''f''); rehash;', staged, step{3});
        name = sprintf('file %s', step{3});
    elseif step <= numel(code.blocks)
        txt = code.blocks{step};
        name = sprintf('block %d', step);
    else
        parts{end + 1} = sprintf('fprintf(''VERIFY-ERROR block %d not found in %s\\n'');', step, code.file); %#ok<AGROW>
        continue
    end
    parts{end + 1} = sprintf(['fprintf(''\\n>>> %s\\n'');\ntry\n%s\ncatch vbX_stepErr\n' ...
        '    fprintf(''VERIFY-ERROR %s: %%s\\n'', vbX_stepErr.message);\nend'], ...
        name, no_gui(apply_paths(txt, pairs)), name); %#ok<AGROW>
end
% run() switches to the script's folder, so the file lives in the lesson work folder:
% lesson code that saves to pwd then writes there.
file = fullfile(pwd, sprintf('vbstep_%06d.m', randi(999999)));
fid = fopen(file, 'w', 'n', 'UTF-8');
fprintf(fid, '%s\n', strjoin(parts, newline));
fclose(fid);
end

% -------------------------------------------------------------------------------------------------
function code = lesson_code(slug, cfg)
% Starting-point script and ```matlab blocks of the English lesson (code is identical in both languages).
hit = dir(fullfile(cfg.lessons, 'en', ['*-' slug '.md']));
if isempty(hit)
    error('verify:lesson', 'lesson file not found: lessons/en/*-%s.md', slug);
end
txt = fileread(fullfile(hit(1).folder, hit(1).name));
txt = strrep(txt, sprintf('\r\n'), newline);
parts = regexp(txt, '^---\n(.*?)\n---\n(.*)$', 'tokens', 'once');
if isempty(parts)
    front = ''; body = txt;
else
    front = parts{1}; body = parts{2};
end
code.start = '';
tok = regexp([front newline], '\n  script: \|\n((?:    [^\n]*\n|[ ]*\n)+)', 'tokens', 'once');
if ~isempty(tok)
    rows = splitlines(tok{1});
    rows = regexprep(rows, '^    ', '');
    code.start = strjoin(rows, newline);
end
code.blocks = regexp(body, '```matlab\n(.*?)```', 'tokens');
code.blocks = cellfun(@(c) c{1}, code.blocks, 'UniformOutput', false);
code.file = hit(1).name;
end

function tf = start_modifies(slug, cfg)
% True if the Starting point calls a function that changes the data (comments ignored).
try
    code = lesson_code(slug, cfg);
catch
    tf = false;
    return
end
txt = regexprep(code.start, '%[^\n]*', '');
tf = ~isempty(regexp(txt, ['\<(pop_eegfiltnew|pop_reref|pop_runica|pop_select|pop_epoch|pop_subcomp|' ...
    'pop_rmbase|pop_eegthresh|pop_rejepoch|pop_resample|pop_chanedit|pop_interp|pop_iclabel|' ...
    'pop_icflag|pop_clean_rawdata|pop_cleanline)\s*\('], 'once'));
end

function txt = apply_paths(txt, pairs)
for p = 1:size(pairs, 1)
    txt = strrep(txt, pairs{p, 1}, pairs{p, 2});
end
end

function txt = no_gui(txt)
% Starting points open the GUI and end with "eeglab redraw" so learners can continue from the menus.
% The checker runs without windows: every "eeglab" start becomes nogui and redraw lines are skipped.
opts = {'lineanchors'};
txt = regexprep(txt, '^([ \t]*)eeglab([ \t]+redraw|[ \t]*\([ \t]*''redraw''[ \t]*\))[ \t]*;?', ...
    '$1% eeglab redraw skipped by verify_batch', opts{:});
txt = regexprep(txt, '^([ \t]*\[[^\]\n]*\][ \t]*=[ \t]*)eeglab[ \t]*;?(?=[ \t]*(%|$))', ...
    '$1eeglab(''nogui'');', opts{:});
txt = regexprep(txt, '^([ \t]*)eeglab[ \t]*;?(?=[ \t]*(%|$))', '$1eeglab nogui', opts{:});
end

% -------------------------------------------------------------------------------------------------
function [status, actual] = check_value(ws, expr, expected, tol)
try
    value = eval_in(ws, expr);
catch err
    status = 'FAIL';
    actual = ['error: ' err.message];
    return
end
actual = as_text(value);
if isempty(expected) && ~iscell(expected)
    status = 'INFO';
elseif isa(expected, 'function_handle')
    status = pass_fail(expected(value));
elseif isnumeric(expected) || islogical(expected)
    ok = (isnumeric(value) || islogical(value)) && isequal(size(value), size(expected)) ...
        && all(abs(double(value(:)) - double(expected(:))) <= tol);
    status = pass_fail(ok);
else
    status = pass_fail(isequal(value, expected));
end
end

function value = eval_in(vbX_ws, vbX_expr)
% Unpack the lesson workspace, then evaluate the check expression against it.
vbX_names = fieldnames(vbX_ws);
for vbX_i = 1:numel(vbX_names)
    eval([vbX_names{vbX_i} ' = vbX_ws.(vbX_names{vbX_i});']);
end
value = eval(vbX_expr);
end

function s = pass_fail(ok)
if ok, s = 'PASS'; else, s = 'FAIL'; end
end

function r = count(r, status)
switch status
    case 'PASS', r.pass = r.pass + 1;
    case 'FAIL', r.fail = r.fail + 1;
end
end

function s = as_text(v)
if ischar(v) || isstring(v)
    s = ['''' char(v) ''''];
elseif iscellstr(v) || (iscell(v) && all(cellfun(@ischar, v)))
    s = ['{' strjoin(cellfun(@(x) ['''' x ''''], v, 'UniformOutput', false), ' ') '}'];
elseif isnumeric(v) || islogical(v)
    if numel(v) > 12
        s = sprintf('[%s ...] (%s)', num2str(double(v(1:12)), '%g '), mat2str(size(v)));
    else
        s = mat2str(double(v), 6);
    end
else
    s = ['<' class(v) '>'];
end
end

function s = expected_text(expected, tol)
if isempty(expected) && ~iscell(expected)
    s = '';
elseif isa(expected, 'function_handle')
    s = ['   expected: ' func2str(expected)];
elseif isnumeric(expected) && tol > 0
    s = sprintf('   expected: %s +/- %g', as_text(expected), tol);
else
    s = ['   expected: ' as_text(expected)];
end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

function fclose_if_open(fid)
if any(fopen('all') == fid), fclose(fid); end
end
