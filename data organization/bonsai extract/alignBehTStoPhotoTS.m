function [data] = alignBehTStoPhotoTS(data)
%
% When looping over each GoTS, it first finds all the photometry frames 
% that happen before the behavior event, and return the indices of those 
% frames ('FramesB4Evnt'); 
% then FirstFrameB4EvntIdx7 takes the last one (end)
%
% [data] = alignBehTStoPhotoTS(data);
% 
% INPUT
% - 'data': structure with data
%       necessary variables to be included within 'data' structure are: 
%           - data.acq.time{1} or 'FrameTS': actual time (in ms) of each 
%               photometry frame recorded by the computer software clock
%       'data.beh' sub-structure will have behavioral events in timestamps
%           in computer software clock time, as extracted from 
%           StateTransitions.csv with fxn 'extract2AFCdataAK'
%           >> beh = extract2AFCdataAK(statetrans, 'photo');
%
% OUTPUT
% - 'TS': timestamp as index relative to photometry signal at 50 Hz.
%       This is the frame in photometry signal that is
%       immediately BEFORE the behavioral event timestamp
%
%
% Anya Krok, December 2025
% Updated March 2026: code now will be run after extract2AFCdataAK and change computer time stamps to samples 
% Updated April 2026: integrate for use with wavesurfer output

%% check
% Check whether data.beh timeStamps are in elapsedTime or already in 
% samples aka index relative to photometry signal.
% Simple check: if in samples then all values will be integers.
if all(isinteger([data.beh.lickLeft])) || all(isinteger([data.beh.lickRight]))
    error('Behavior time-stamps are already in units of samples.');
end

%% extract variables
beh = data.beh;

beh_photo = struct;
beh_photo.lickLeft  = [];
beh_photo.lickRight = [];
beh_photo.pokeCenter = [];
beh_photo.hits  = [];
beh_photo.abort = [];
beh_photo.miss  = [];
beh_photo.error = [];
try
    beh_photo.startTime = beh.startTime;
    beh_photo.startSec = beh.startSec;
end

%%
Fs = data.gen.Fs;
nSamp = numel(data.final.FP{1});

%%
% Syntax: newTS = firstFrameBeforeEventIndex(oldTS, time);
%
% lickLeft
oldTS = beh.lickLeft;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.lickLeft = newTS;
end


% lickRight
oldTS = beh.lickRight;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.lickRight = newTS;
end

% pokeCenter
oldTS = beh.pokeCenter;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.pokeCenter = newTS;
end

% hits
oldTS = beh.hits;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.hits = newTS;
end

% abort
oldTS = beh.abort;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.abort = newTS;
end

% miss
oldTS = beh.miss;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.miss = newTS;
end

% error
oldTS = beh.error;
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    beh_photo.error = newTS;
end

% trial data
trial = beh.trial(:,1:4); % extract table
trial.start     = nan(height(trial),1);
trial.ledOn     = nan(height(trial),1);
trial.firstPoke = nan(height(trial),1);
trial.soundOn   = nan(height(trial),1);
trial.end       = nan(height(trial),1);

% trial start
oldTS = [beh.trial.start];
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    trial.start = newTS;
end

% trial ledOn
oldTS = [beh.trial.ledOn];
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    trial.ledOn = newTS;
end

% trial firstPoke
oldTS = [beh.trial.firstPoke];
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    trial.firstPoke = newTS;
end

% trial soundOn
oldTS = [beh.trial.soundOn];
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    trial.soundOn = newTS;
end

% trial end
oldTS = [beh.trial.end];
if ~isempty(oldTS)
    try newTS = firstFrameBeforeEventIndex(oldTS, Fs, nSamp);
    catch, newTS = nan;
    end
    trial.end = newTS;
end

beh_photo.trial = trial;

%% 
hitT = beh.hitT;  % extract table
hitT.hits = nan(height(hitT),1); % clear values
hitT.hits = [beh_photo.hits];    % replace with newTS
beh_photo.hitT = hitT;

%%
data.beh = beh_photo;

%% OLD
% % Pre-March 2026 method directly using statetrans
% statetransTS = table2array(statetrans(:,1));
% compTS = statetransTS((statetrans.Id=='ITI'));
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.trialStart = TS;

% 
% %% Trial End
% compTS = [];
% nTrial = statetrans.Trial(end)+1;
% for n = 1:nTrial
%     compTS(n) = statetransTS(find([statetrans.Trial] == n-1, 1, 'last'));
% end
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.trialEnd = TS;
% 
% %% Hit
% compTS = statetransTS((statetrans.Id=='Hit')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.hits = TS;
% 
% %% Miss
% compTS = statetransTS((statetrans.Id=='Miss')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.miss = TS;
% 
% %% LickRight
% compTS = statetransTS((statetrans.Id=='LickRight')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.lickRight = TS;
% 
% %% LickLeft
% compTS = statetransTS((statetrans.Id=='LickLeft')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.lickLeft = TS;
% 
% %% LickCenter
% compTS = statetransTS((statetrans.Id=='LickCenter')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.lickCenter = TS;
% 
% %% LickCenter -- mouse initiates trial
% trials = unique(statetrans.Trial); % Identify row index for first LickCenter for each unique Trial
% rowsLickCenter_trial = nan(size(trials));
% for ii = 1:numel(trials)
%     rows = find(statetrans.Trial == trials(ii));
%     k = find(statetrans.Id(rows) == "LickCenter", 1, 'first');
%     if ~isempty(k)
%         rowsLickCenter_trial(ii) = rows(k);
%     end
% end
% trialFail = find(isnan(rowsLickCenter_trial)); % identify any trials that were not initiated
% rowsLickCenter_trial(trialFail) = [];
% compTS = statetransTS(rowsLickCenter_trial); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.lickStartTrial = TS;
% 
% %% LickCenter -- precedes each Hit
% rowsHit = find(statetrans.Id == 'Hit'); % row numbers of Hits
% rowsLickCenter_preHit = nan(numel(rowsHit),1);       % store preceding LickCenter (NaN if none)
% for k = 1:numel(rowsHit)
%     r = rowsHit(k);
%     if r > 1
%         idx = find(statetrans.Id(1:r-1) == 'LickCenter', 1, 'last');
%         if ~isempty(idx)
%             rowsLickCenter_preHit(k) = idx;
%         end
%     end
% end
% compTS = statetransTS(rowsLickCenter_preHit); % only select time stamps for LickCenter that precedes a Hit
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.lickStartHitTrial = TS;
% beh.rewLatency = beh.hits - beh.lickStartHitTrial;
% 
% %% Timeout
% compTS = statetransTS((statetrans.Id=='Timeout')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.error = TS;
% 
% %% IncorrectAction
% compTS = statetransTS((statetrans.Id=='IncorrectAction')); 
% TS = firstFrameBeforeEventIndex(compTS, data.acq.time{1});
% beh.noHold = TS;
% 
% %% Trial end action
% % Group trials and get unique trial ids
% [G, trial] = findgroups(statetrans.Trial);
% 
% % For each group, take the last Id (last row within that trial)
% lastAct = splitapply(@(ids) ids(end), statetrans.Id, G);   % categorical array, one per trial
% 
% % Take second to last Id (should be LickXXX)
% secondLastAct = splitapply(@(ids) ids(end-1), statetrans.Id, G); % second to last action per trial
% % s = string(secondLastAct); % convert to string vector
% % maskNotLick = ~startsWith(s, "Lick") | isundefined(secondLastAct); % logical to identify which values do not start with Lick
% % idx = find(maskNotLick); % any action non-Lick?
% 
% % Return result table
% lastAct = table(trial, lastAct, secondLastAct,...
%     'VariableNames', {'trial','lastAct','lastLick'});
% lastAct(trialFail,:) = []; % remove trials where mouse failed to initiate trial with center poke, as identified above
% 
% beh.lastAct = lastAct;


% TStype=[ones(1,length(TS))];
% STClocal=1;
% FS=30;
% pre=5;
% post=5;
% for i= 1:length(TS)
% if TS(i) + post*FS < length(data.final.time{1}) & TS(i)-pre*FS+1>0   
%     GreenMatrix1(:,STClocal)=data.final.FP{1}(TS(i)-pre*FS+1:TS(i)+post*FS);
%     RedMatrix1(:,STClocal)=data.final.FP{2}(TS(i)-pre*FS+1:TS(i)+post*FS);
% 
%     TrialType1(STClocal)=TStype(i);
%     STClocal=STClocal+1;
% end
% end

