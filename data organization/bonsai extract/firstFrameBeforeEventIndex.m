function fpTS = firstFrameBeforeEventIndex(compTS, Fs, nSamp)
% 
% Description: permits alignment of photometry signal, acquired with
% Neurophotometrics, with behavioral events, acquired with Bonsai
% 
% When looping over each compTS, this function first finds all the 
% photometry frames that happen before the behavior event, then returns
% the indices of those frames ('FramesB4Evnt'), and finally takes last one.
%
% fpTS = firstFrameBeforeEventIndex(compTS, Fs, nSamp)
%
% INPUTS
% - 'compTS' - vector of behavior event times in seconds
%       note timestamps drawn from statetrans.TimeOfDay if photometry data
%       also acquired via Bonsai / Neurophotometrics, or drawn from 
%       statetrans.PhotoTime if acquired via Wavesurfer / NI.
% - 'Fs':    - sampling rate (Hz)
% - 'nSamp'  - total number of samples
%
% OUTPUT
% - 'fpTS': timestamps as index relative to photometry signal.
%
%       Returns index of the last sample that occurs at or before each 
%       event time (i.e., largest index k with timeVector(k) ≤ compTS(i)).
%
% Updated Anya Krok, April 2026

t0 = 1/Fs; % first time stamp
compTS = compTS(:);
idx = floor((compTS - t0) * Fs) + 1;   % vectorized candidate indices
idx(idx < 1 | idx > nSamp) = nan; % events before t0 or after end -> NaN
fpTS = idx;

% valid = ~isnan(idx); 
% fpTS = idx(valid); % ignore events before t0 or after end

%% OLD
% Changed on 26-04-10 due to long run-times when utilizing full time vector
% Time to run shortened from ~40 seconds to 0.025 seconds.
% Old syntax:
%   fpTS = firstFrameBeforeEventIndex(compTS,timeVector)
% Code:
% idx = nan(length(compTS),1); % initiate vector
% framesTS = timeVector;
% for ii = 1:length(compTS)
%     FramesB4Evnt = find(framesTS < compTS(ii)); 
%     if FramesB4Evnt > 0
% %         idx(c) = FramesB4Evnt(end);
% %         c = c+1;
%         idx(ii) = FramesB4Evnt(end);
%     else
%         continue
%     end
% end
% fpTS = idx(:);