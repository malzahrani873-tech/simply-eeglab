% Copied from lessons/en/10-04-write-plugin.md. The lesson is the reference.
eeglab nogui
eeglabRoot = fileparts(which('eeglab'));
EEG = pop_loadset('eeglab_data.set', fullfile(eeglabRoot, 'sample_data'));

% The plugin folder is on the path even without the GUI
assert(exist('pop_chanvar', 'file') == 2, 'pop_chanvar not found: check the plugins folder');

% Call with all arguments: no window, direct plot
com = pop_chanvar(EEG, 3);
disp(com);   % pop_chanvar(EEG, 3);

% Running the returned command must reproduce the same figure
eval(com);
