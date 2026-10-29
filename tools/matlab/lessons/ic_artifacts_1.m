% Copied from lessons/en/04-06-ic-artifacts.md. The lesson is the reference.
% Classify the components, then find the clearest example of each class
EEG = pop_iclabel(EEG, 'default');
classes = EEG.etc.ic_classification.ICLabel.classes;
probs   = EEG.etc.ic_classification.ICLabel.classifications;
[~, bestClass] = max(probs, [], 2);   % most likely class of each component

for c = 1:numel(classes)
    [p, comp] = max(probs(:, c));
    fprintf('%-14s components: %2d | clearest: %2d (%.0f%%)\n', ...
        classes{c}, sum(bestClass == c), comp, 100 * p);
end

% Panels of the clearest Eye, Muscle, and Brain components
% Column order: Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other
[~, examples] = max(probs(:, [3 2 1]));
pop_viewprops(EEG, 0, examples);
