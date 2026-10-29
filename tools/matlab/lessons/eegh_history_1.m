% Copied from lessons/en/09-01-eegh-history.md. The lesson is the reference.
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','eeglab_data.set','filepath','C:\eeglab2026.1\sample_data\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'plotfreqz',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','D1 hp0.1','gui','off');
EEG = pop_eegfiltnew(EEG, 'locutoff',58,'hicutoff',62,'revfilt',1,'plotfreqz',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','D1 hp0.1 notch60','gui','off');
pop_eegplot( EEG, 1, 1, 1);
