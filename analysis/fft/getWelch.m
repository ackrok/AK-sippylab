function [P, T, F] = getWelch(signal, Fs, params)
% Description: power spectral density (PSD) using pwelch function on 
% successive, overlapping time windows to get a time-varying PSD aka 
% Welch-based spectrogram
%
% [P, T, F] = getWelch(signal, Fs)
% [P, T, F] = getWelch(signal, Fs, params)
%
% INPUTS
% 'signal': photometry signal
% 'Fs': sampling frequency in Hz
% 'params': parameters (optional)
%       'params.winSec': window length in seconds (default 10 sec)
%       'params.fmax': max frequency for analysis, in Hz (default 0-15 Hz)
%
% OUTPUTS
% 'P': one-sided PSD per time-bin, in power/Hz
% 'T': center of each time segment, in minutes
% 'F': frequency vector, in Hz
%
% Anya Krok, January 2026

% signal
signal = zscore(signal); % z-score signal

% check inputs
if nargin < 3
    winSec = 10; % window length in seconds
    fmax = 15;   % range of frequency from 0-fmax Hz for analysis
    
else
    winSec = params.winSec; 
    fmax   = params.fmax;
    if isfield(params,'fmin')
        fmin = params.fmin;
    else
        fmin = 0;
    end
end
fvec = fmin:0.1:fmax; % frequency vector covering range with desired resolution

% window properties
win = round(winSec * Fs);     % window size is winSec * Fs
noverlap = round(0.75 * win);
hop = win - noverlap;         % step between successive windows
winVec = hamming(win);        % window vector for pwelch
starts = 1:hop:(numel(signal) - win + 1); % segment start indices
nT = numel(starts); % number of windows

% preallocate: compute pwelch once to get freq vector and number of bins
[~, F] = pwelch(signal(1:win), winVec, 0, fvec, Fs);   % noverlap=0 for single segment call
nF = numel(F);
P = zeros(nF, nT); % preallocate output matrix

% compute PSD per time-bin
for k = 1:nT
    seg = signal(starts(k) : starts(k) + win - 1);
    % compute one-sided PSD for this segment
    P(:,k) = pwelch(seg, winVec, 0, fvec, Fs);   % PSD in power/Hz
end

% time axis: center of each segment in minutes
Tsec = (starts - 1 + win/2) ./ Fs;  
T = Tsec / 60; % minutes

end