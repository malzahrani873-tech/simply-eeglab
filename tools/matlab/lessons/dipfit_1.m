% Copied from lessons/en/10-01-dipfit.md. The lesson is the reference.
% Work on a copy: the lookup below changes channel coordinates
EEG.setname = 'D1 dipfit';

% Template electrode positions that match the BEM head model.
% Channels missing from the template (EOG1, EOG2) lose their
% coordinates and are left out of the fit.
EEG = pop_chanedit(EEG, 'lookup', 'standard_1005.elc');

% Template BEM head model (MNI); the alignment matrix is set
% automatically from the template file name
EEG = pop_dipfit_settings(EEG, 'model', 'standardBEM');
disp(EEG.dipfit.coord_transform);   % expect 0 0 0 0 0 -1.5708 1 1 1

% Coarse grid scan + fine fit for all components, keep every dipole
EEG = pop_multifit(EEG, [], 'threshold', 100);

% Residual variance per component, in percent
rv = 100 * [EEG.dipfit.model.rv];
fprintf('IC %2d: RV = %5.1f%%\n', [1:numel(rv); rv]);
fprintf('%d of %d components below 15%% RV\n', sum(rv < 15), numel(rv));

% Scalp maps of the first 12 components with their dipoles
pop_topoplot(EEG, 0, 1:12, 'D1 dipfit', 0, 1);

% Summary view of all dipoles: top, back and side, with component numbers
pop_dipplot(EEG, 1:numel(EEG.dipfit.model), 'normlen', 'on', 'summary', 'on', 'num', 'on');

EEG = pop_saveset(EEG, 'filename', 'D1_dipfit.set', 'filepath', pwd);
