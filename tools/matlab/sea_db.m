function db = sea_db(EEG, freqs)
% SEA_DB  Channel-averaged power (dB) at the given frequencies, as computed by spectopo.
%   db = sea_db(EEG, 60)
%   peak = sea_db(EEG, 60) - mean(sea_db(EEG, [56 57 63 64]))   % line-noise peak above neighbours

[spec, f] = spectopo(double(EEG.data(:, :)), 0, EEG.srate, 'plot', 'off', 'verbose', 'off');
m = mean(spec, 1);
db = arrayfun(@(x) interp1(f, m, x), freqs);
end
