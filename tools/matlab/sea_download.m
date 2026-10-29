function missing = sea_download(slugs)
% SEA_DOWNLOAD  Download every data file the run day needs, then list what is still missing.
%   sea_download            all items in sea_data.m
%   sea_download('mvpa')    only the items of these lessons (cell array or one name)
% Run it the evening before (run_checklist 0.2). Files that already exist are kept. Direct links use
% websave; ERP CORE files are found by name in the ERP CORE project on OSF (api.osf.io). Items that
% need a manual download print their instruction. The return value lists the missing item names.

cfg = sea_config();
items = sea_data(cfg);
if nargin > 0
    if ischar(slugs), slugs = {slugs}; end
    items = items(arrayfun(@(it) any(ismember(it.lessons, slugs)), items));
end
missing = {};
for k = 1:numel(items)
    it = items(k);
    fprintf('\n[%d/%d] %s\n', k, numel(items), it.name);
    if has_file(it.check)
        fprintf('  present\n');
        continue
    end
    try
        switch it.get
            case 'url'
                fetch_urls(it.how, cellstr(it.dest));
            case 'osf'
                osf_fetch(it.how{1}, it.how{2}, it.how{3}, it.dest);
            case 'manual'
                fprintf('  manual: %s\n', it.how);
        end
    catch err
        fprintf('  download failed: %s\n', err.message);
    end
    if has_file(it.check)
        fprintf('  ok\n');
    else
        missing{end + 1} = it.name; %#ok<AGROW>
        fprintf('  MISSING: %s\n', it.check);
    end
end
fprintf('\n%d of %d items present.\n', numel(items) - numel(missing), numel(items));
if ~isempty(missing)
    fprintf('Missing:\n'); fprintf('  - %s\n', missing{:});
end
end

function tf = has_file(pattern)
tf = ~isempty(dir(pattern));
end

function fetch_urls(urls, dests)
opts = weboptions('Timeout', 120);
for k = 1:numel(urls)
    if exist(dests{k}, 'file'), continue; end
    if ~exist(fileparts(dests{k}), 'dir'), mkdir(fileparts(dests{k})); end
    fprintf('  %s\n', urls{k});
    websave(dests{k}, urls{k}, opts);
end
end

function osf_fetch(component, pattern, maxGroups, dest)
% Finds the ERP CORE component (child of OSF project thsqg) by title, walks its storage and downloads
% the files whose names match the pattern, keeping the participant folder. maxGroups limits the
% number of participant folders (for example 10 of 40).
opts = weboptions('ContentType', 'json', 'Timeout', 120);
api = 'https://api.osf.io/v2/';
kids = osf_list([api 'nodes/thsqg/children/'], opts);
titles = cellfun(@(d) d.attributes.title, kids, 'UniformOutput', false);
hit = find(contains(titles, component), 1);
assert(~isempty(hit), 'sea:osf', 'No ERP CORE component named %s on OSF.', component);
root = [api 'nodes/' kids{hit}.id '/files/osfstorage/'];
% Each component stores the raw files twice ('... All Data and Scripts' and '... Raw Data and
% Scripts Only'); walk only the first folder when it is there.
top = osf_list(root, opts);
isAll = cellfun(@(d) strcmp(d.attributes.kind, 'folder') && contains(d.attributes.name, 'All Data'), top);
if any(isAll)
    root = top{find(isAll, 1)}.relationships.files.links.related.href;
end
files = osf_walk(root, pattern, opts, 4);
assert(~isempty(files), 'sea:osf', 'No file matching %s in ERP CORE %s.', pattern, component);
% Participant folders in numeric order (1, 2, ..., 10), not in the text order OSF returns (1, 10, 11, ...)
groups = unique({files.group});
[~, order] = sort(str2double(groups));   % non-numeric names (NaN) go last
groups = groups(order);
groups = groups(1:min(maxGroups, end));
for f = files(ismember({files.group}, groups))'
    target = fullfile(dest, f.group, f.name);
    if exist(target, 'file'), continue; end
    if ~exist(fileparts(target), 'dir'), mkdir(fileparts(target)); end
    fprintf('  %s/%s\n', f.group, f.name);
    websave(target, f.url, weboptions('Timeout', 300));
end
end

function out = osf_walk(url, pattern, opts, depth)
% Files matching the pattern under an OSF folder, with the name of the folder that holds each one.
out = struct('name', {}, 'url', {}, 'group', {});
if depth < 0, return; end
list = osf_list(url, opts);
for i = 1:numel(list)
    d = list{i};
    a = d.attributes;
    if strcmp(a.kind, 'file') && ~isempty(regexp(a.name, pattern, 'once'))
        parts = strsplit(strip(a.materialized_path, '/'), '/');
        group = '';
        if numel(parts) > 1, group = parts{end - 1}; end
        out(end + 1) = struct('name', a.name, 'url', d.links.download, 'group', group); %#ok<AGROW>
    elseif strcmp(a.kind, 'folder')
        out = [out, osf_walk(d.relationships.files.links.related.href, pattern, opts, depth - 1)]; %#ok<AGROW>
    end
end
end

function data = osf_list(url, opts)
% All pages of an OSF API list, as a cell array of entries (files and folders have different fields).
data = {};
while ~isempty(url)
    r = webread(url, opts);
    page = r.data;
    if isstruct(page), page = num2cell(page); end
    data = [data; page(:)]; %#ok<AGROW>
    url = '';
    if isfield(r, 'links') && isfield(r.links, 'next') && ~isempty(r.links.next)
        url = r.links.next;
    end
end
end
