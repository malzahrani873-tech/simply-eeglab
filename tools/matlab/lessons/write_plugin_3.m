% Copied from lessons/en/10-04-write-plugin.md. The lesson is the reference.
function vers = eegplugin_chanvar(fig, trystrs, catchstrs)
% EEGPLUGIN_CHANVAR - Add "Channel variance" to the EEGLAB Plot menu.

vers = 'chanvar1.0';

% Find the Plot menu of the main EEGLAB window
plotmenu = findobj(fig, 'tag', 'plot');

% Check the data, run the function, then add its command to the history
cmd = [trystrs.check_data 'LASTCOM = pop_chanvar(EEG);' catchstrs.add_to_hist];
uimenu(plotmenu, 'Label', 'Channel variance', 'CallBack', cmd, 'Separator', 'on');
