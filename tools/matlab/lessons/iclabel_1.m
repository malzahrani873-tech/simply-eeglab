% Copied from lessons/en/04-05-iclabel.md. The lesson is the reference.
% Classify all components with the default ICLabel classifier
EEG = pop_iclabel(EEG, 'default');

% One row per component, one column per class
classes = EEG.etc.ic_classification.ICLabel.classes;
probs   = EEG.etc.ic_classification.ICLabel.classifications;
disp(classes);
disp(round(probs(1:10, :) * 100));

% Flag components above 90% Muscle or Eye
% Row order: Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other
thresh = [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN];
EEG = pop_icflag(EEG, thresh);
artifactComps = find(EEG.reject.gcompreject);

% Review the flagged components
if ~isempty(artifactComps)
    pop_viewprops(EEG, 0, artifactComps);
end

% Remove them from the main dataset
if ~isempty(artifactComps)
    EEG = pop_subcomp(EEG, artifactComps, 0);
end
EEG.setname = 'D1 main clean';
EEG = pop_saveset(EEG, 'filename', 'D1_main_clean.set', 'filepath', pwd);

% Low-pass at 30 Hz, postponed until after ICA cleaning
EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);
EEG.setname = 'D1 main clean lp30';
EEG = pop_saveset(EEG, 'filename', 'D1_main_clean_lp30.set', 'filepath', pwd);
