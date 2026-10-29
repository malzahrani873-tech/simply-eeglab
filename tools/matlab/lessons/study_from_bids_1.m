% Copied from lessons/en/08-03-study-from-bids.md. The lesson is the reference.
% bidsFolder comes from the starting point script
[STUDY, ALLEEG] = pop_importbids(bidsFolder, 'subjects', {'sub-002', 'sub-005'}, ...
    'eventtype', 'value', 'bidsevent', 'on', 'bidschanloc', 'on', 'studyName', 'gonogo_bids');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = 1:length(EEG);

% Fields from the file names, from participants.tsv and from the data
for k = 1:numel(STUDY.datasetinfo)
    d = STUDY.datasetinfo(k);
    fprintf('%s  session %s  run %s  gender %s  %d Hz  %d channels  %.0f s\n', d.subject, ...
        num2str(d.session), num2str(d.run), d.gender, ALLEEG(k).srate, ALLEEG(k).nbchan, ALLEEG(k).xmax);
end
eeg_eventtypes(ALLEEG(1));
fprintf('STUDY file: %s\n', fullfile(STUDY.filepath, STUDY.filename));
eeglab redraw;
