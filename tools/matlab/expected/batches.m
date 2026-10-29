function b = batches()
% BATCHES  Lesson batches for verify_batch. Field name = batch name (hyphens become underscores).
%   verify_batch('mvp')
%   verify_batch('st1-2')
%   verify_batch('st5')
%   verify_batch('st3-4a')   % ica-concept (made-up data), then the D1 path from resampling to ica-1hz-copy-weights
%   verify_batch('st3-4b')
%   verify_batch('st6')
%   verify_batch('st7')      % D1 plotting lessons
%   verify_batch('st8')      % STUDY lessons on the ready Go-nogo STUDY (D6) and ds002680
%   verify_batch('st9-10')
%   verify_batch('plugins')  % lessons that need extensions not bundled with EEGLAB (run_checklist 0.4)
%   verify_batch('all')      % every batch above in one run and one zip file
%   verify_batch('fieldtrip-full')   % mne-fieldtrip again with full FieldTrip, in a new MATLAB session
% Lessons that read a file saved by an earlier lesson come after it in the same batch.

b.mvp = {'install-eeglab', 'import-raw', 'filtering', 'run-ica', 'iclabel'};
b.st1_2 = {'import-raw', 'alleeg-datasets', 'set-fdt-files', 'channel-locations', 'events', 'bids-openneuro'};
b.st5 = {'extract-epochs', 'baseline-correction', 'epoch-rejection'};
b.st6 = {'erp-average', 'power-spectrum', 'ersp-itc', 'erplab-amplitude-latency', 'data-quality-sme'};
b.st3_4a = {'ica-concept', 'resampling', 'line-noise', 'bad-channels', 'interpolation', 'rereferencing', 'ica-1hz-copy-weights'};   % fig_bad_channels needs ERP CORE N400 (run_checklist 0.2)
b.st3_4b = {'amica-picard'};   % needs the Picard plugin; the rest of the batch is by eye (run_checklist 2.10)
b.st7 = {'topoplot', 'channel-erp-plot', 'erp-image', 'publication-figures'};
b.st8 = {'study-concepts', 'create-study', 'study-from-bids', 'study-precompute', 'study-design', ...
    'study-plot-channels', 'study-statistics', 'study-export-results', 'ic-clustering', 'limo'};
% create-study saves animal_mine.study for the others; ic-clustering computes ICA for 14 participants
% (about an hour); limo needs the LIMO and Fieldtrip-lite plugins
b.st9_10 = {'write-plugin', 'mvpa'};   % mvpa needs ERPLAB and ERP CORE N170 participant 2; the other station 9-10 checks are by eye (run_checklist 2.9)
b.plugins = {'automated-pipelines', 'dipfit', 'sift', 'mne-fieldtrip'};   % PrepPipeline, SIFT and Fieldtrip-lite; dipfit is bundled
% mne-fieldtrip is the last lesson of 'all', so it runs on Fieldtrip-lite after every lesson that needs it.
b.all = unique([b.mvp, b.st1_2, b.st3_4a, b.st3_4b, b.st5, b.st6, b.st7, b.st8, b.st9_10, b.plugins], 'stable');
% Not part of 'all': run only if mne-fieldtrip fails on Fieldtrip-lite. Start a new MATLAB session,
% put full FieldTrip on the path (ft_defaults) without Fieldtrip-lite, then run this batch.
b.fieldtrip_full = {'mne-fieldtrip'};
end
