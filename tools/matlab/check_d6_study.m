function facts = check_d6_study(studyFile)
% CHECK_D6_STUDY  Record the facts of the ready D6 STUDY (Go-nogo) for the station 8 lessons.
%   check_d6_study                      finds animal.study (or the first .study) under <course_dir>
%   check_d6_study('C:\...\x.study')    uses that file
%
% Writes assets-src/study/d6_facts.txt and compares what it can with d6_facts.m: number of
% participants, sex groups, channels, sampling rate, conditions, ICA weights and dipoles.
% Nothing is changed or saved in the STUDY.

cfg = sea_init();
ref = d6_facts();
if nargin < 1 || isempty(studyFile)
    root = cfg.course_dir;
    hits = dir(fullfile(root, '**', 'animal.study'));
    if isempty(hits), hits = dir(fullfile(root, '**', '*.study')); end
    assert(~isempty(hits), 'No .study file under %s. Unzip animal_study.zip there.', root);
    studyFile = fullfile(hits(1).folder, hits(1).name);
end
[folder, name, ext] = fileparts(studyFile);
[STUDY, ALLEEG] = pop_loadstudy('filename', [name ext], 'filepath', folder);

info = STUDY.datasetinfo;
facts.study_file  = studyFile;
facts.study_name  = STUDY.name;
facts.ndatasets   = numel(ALLEEG);
facts.subjects    = unique({info.subject}, 'stable');
facts.nsubjects   = numel(facts.subjects);
facts.groups      = unique(cellfun(@as_text, {info.group}, 'UniformOutput', false), 'stable');
facts.sessions    = unique(cellfun(@as_text, {info.session}, 'UniformOutput', false), 'stable');
facts.conditions  = unique(cellfun(@as_text, {info.condition}, 'UniformOutput', false), 'stable');
facts.nbchan      = unique([ALLEEG.nbchan]);
facts.srate       = unique([ALLEEG.srate]);
facts.trials      = [ALLEEG.trials];
facts.pnts        = unique([ALLEEG.pnts]);
facts.xminmax_ms  = unique(round(1000 * [[ALLEEG.xmin]' [ALLEEG.xmax]']), 'rows');
facts.has_ica     = all(arrayfun(@(E) ~isempty(E.icaweights), ALLEEG));
facts.has_dipfit  = all(arrayfun(@(E) isfield(E, 'dipfit') && ~isempty(E.dipfit) && isfield(E.dipfit, 'model') ...
                        && ~isempty(E.dipfit.model), ALLEEG));
facts.designs     = {STUDY.design.name};
facts.files       = cellfun(@(f, p) fullfile(p, f), {ALLEEG.filename}, {ALLEEG.filepath}, 'UniformOutput', false);
sizes = cellfun(@folder_bytes, unique({ALLEEG.filepath}));
facts.size_gb     = sum(sizes) / 1e9;
% Event types present (first dataset), to match condition names in the lessons
facts.event_types = unique(cellfun(@as_text, {ALLEEG(1).event.type}, 'UniformOutput', false));

% --- Compare with d6_facts.m ----------------------------------------------------------------
checks = {
    'participants', facts.nsubjects, ref.ready.nsubjects
    'files',        numel(ALLEEG),   ref.ready.nfiles
    'channels',     facts.nbchan,    ref.ready.nbchan
    'sampling rate', facts.srate,    ref.ready.srate
    'ICA weights',  facts.has_ica,   ref.ready.has_ica
    'dipoles',      facts.has_dipfit, ref.ready.has_dipfit
    };
out = fullfile(cfg.out, 'study');
if ~exist(out, 'dir'), mkdir(out); end
fid = fopen(fullfile(out, 'd6_facts.txt'), 'w');
fprintf(fid, '%s\nSTUDY file : %s\nSTUDY name : %s\n', cfg.stamp, studyFile, facts.study_name);
for c = 1:size(checks, 1)
    [label, value, expected] = checks{c, :};
    if isempty(expected), status = 'INFO'; elseif isequal(value, expected), status = 'PASS'; else, status = 'FAIL'; end
    fprintf(fid, '%-5s %-14s %s%s\n', status, label, as_text(value), ...
        ternary(isempty(expected), '', ['   expected: ' as_text(expected)]));
end
fprintf(fid, 'INFO  datasets      %d\n', facts.ndatasets);
fprintf(fid, 'INFO  subjects      %s\n', strjoin(facts.subjects, ' '));
fprintf(fid, 'INFO  groups        %s\n', strjoin(facts.groups, ' '));
fprintf(fid, 'INFO  sessions      %s\n', strjoin(facts.sessions, ' '));
fprintf(fid, 'INFO  conditions    %s\n', strjoin(facts.conditions, ' '));
fprintf(fid, 'INFO  designs       %s\n', strjoin(facts.designs, ' | '));
fprintf(fid, 'INFO  points        %s\n', as_text(facts.pnts));
fprintf(fid, 'INFO  epoch (ms)    %s\n', as_text(facts.xminmax_ms));
fprintf(fid, 'INFO  trials        min %d  max %d  total %d\n', min(facts.trials), max(facts.trials), sum(facts.trials));
fprintf(fid, 'INFO  size          %.2f GB\n', facts.size_gb);
fprintf(fid, 'INFO  event types   %s\n', strjoin(facts.event_types, ' '));
fprintf(fid, 'INFO  first files   %s\n', strjoin(facts.files(1:min(4, end)), ' | '));
fprintf(fid, 'Licence: check the download page and any README in %s; ds002680 is CC0.\n', folder);
fclose(fid);
type(fullfile(out, 'd6_facts.txt'));
save(fullfile(out, 'd6_facts.mat'), 'facts');
end

function s = as_text(v)
if ischar(v), s = v;
elseif isnumeric(v) || islogical(v), s = mat2str(v);
elseif iscell(v), s = strjoin(cellfun(@as_text, v, 'UniformOutput', false), ' ');
else, s = class(v);
end
end

function n = folder_bytes(p)
d = dir(p);
n = sum([d(~[d.isdir]).bytes]);
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
