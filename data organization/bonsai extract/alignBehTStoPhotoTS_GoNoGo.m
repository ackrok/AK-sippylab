function [data] = alignBehTStoPhotoTS_GoNoGo(data)
%
% Behavior: GoNoGo task, run with Bonsai
% When looping over each GoTS, it first finds all the photometry frames 
% that happen before the behavior event, and return the indices of those 
% frames ('FramesB4Evnt'); 
% then FirstFrameB4EvntIdx7 takes the last one (end)
%
% [data] = alignBehTStoPhotoTS_GoNoGo(data);
% 
% INPUT
% - 'data': structure with data
%       necessary variables to be included within 'data' structure are: 
%           - data.acq.time{1} or 'FrameTS': actual time (in ms) of each 
%               photometry frame recorded by the computer software clock
%       'data.beh' sub-structure will have behavioral events in timestamps
%           as extracted from StateTransitions.csv with fxn 'extractGoNoGodataAK'
%           >> beh = extractGoNoGodataAK(statetrans);
%
% OUTPUT
% - 'TS': timestamp as index relative to photometry signal at 50 Hz.
%       This is the frame in photometry signal that is
%       immediately BEFORE the behavioral event timestamp
%
%
% Anya Krok, July 2026
% Adapted from alignBehTStoPhotoTS for GoNoGo behavioral data

%% check
% Check whether data.beh timeStamps are in elapsedTime or already in 
% samples aka index relative to photometry signal.
% Simple check: if in samples then all values will be integers.
if all(isinteger([data.beh.lick]))
    error('Behavior time-stamps are already in units of samples.');
end

%% extract variables
beh = data.beh;
Tnames = fieldnames(beh);
Tnames(strcmpi(Tnames,'lick')) = []; 
Tnames(strcmpi(Tnames,'trial')) = []; 
beh_photo = struct;
beh_photo.lick = beh.lick;
beh_photo.trial = beh.trial;
nTrial = height(beh.trial);
beh_photo.trial.start = nan(nTrial,1);
beh_photo.trial.tone  = nan(nTrial,1);
beh_photo.trial.end   = nan(nTrial,1);
for ii = 1:length(Tnames)
    nVar = height(beh.(Tnames{ii}));
    beh_photo.(Tnames{ii}) = table(beh.(Tnames{ii}).num, ...
        nan(nVar,1), nan(nVar,1), ...
        'VariableNames', {'num','tone','end'});
end
try
    beh_photo.startTime = data.gen.startTime;
    beh_photo.startSec = data.gen.startSec;
end
Fs = data.gen.Fs;
nSamp = numel(data.final.FP{1});

%%
% Syntax: newTS = firstFrameBeforeEventIndex(oldTS, time);

% LICK
oldTS = beh.lick; % lick
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.lick = newTS;
end

% FULL TRIAL TABLE
oldTS = beh.trial.start; % trial start
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.trial.start = newTS;
end
oldTS = beh.trial.tone; % trial tone
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.trial.tone = newTS;
end
oldTS = beh.trial.end; % trial end
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.trial.end = newTS;
end

% EVENT TABLE
for ii = 1:length(Tnames)
    oldTStone = beh.(Tnames{ii}).tone; % tone
    if ~isempty(oldTStone)
        try newTS = firstFrameBeforeEventIndex(oldTStone, Fs, nSamp);
        catch, newTS = nan;
        end
        beh_photo.(Tnames{ii}).tone = newTS;
    end
    oldTSend = beh.(Tnames{ii}).end; % end
    if ~isempty(oldTSend)
        try newTS = firstFrameBeforeEventIndex(oldTSend, Fs, nSamp);
        catch, newTS = nan;
        end
        beh_photo.(Tnames{ii}).end = newTS;
    end
end

%%
data.beh = beh_photo;
