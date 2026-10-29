% Copied from lessons/en/01-03-eeg-struct.md. The lesson is the reference.
% Basic information
EEG.setname            % 'Continuous EEG Data'
EEG.nbchan             % 32 channels
EEG.srate              % 128 samples per second
EEG.pnts               % 30504 samples per channel
(EEG.pnts - 1) / EEG.srate   % 238.3047 seconds (same as EEG.xmax)

% The signal: channels x samples
size(EEG.data)         % 32 30504
class(EEG.data)        % 'single'
EEG.data(1, 1:5)       % first 5 samples of channel 1 (microvolts)

% Channel names
{EEG.chanlocs(1:3).labels}   % 'FPz' 'EOG1' 'F3'

% First event: type and latency
EEG.event(1).type      % 'square'
EEG.event(1).latency   % 129.0087 (in samples)
(EEG.event(1).latency - 1) / EEG.srate   % 1.0001 (in seconds)

% Empty until ICA is computed
isempty(EEG.icaweights)   % 1 (true)
