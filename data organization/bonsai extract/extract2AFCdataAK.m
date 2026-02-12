function beh = extract2AFCdataAK(varargin)
% Extract behavioral events from bonsai output table
% Task: 2AFC
%
% beh = extract2AFCdataAK(statetrans)
% beh = extract2AFCdataAK(filePath, fileNames)
%
% INPUT
% 'statetrans' - table made from StateTransitions.csv using function 
% statetrans = GetBonsai_Pho_StateTransitions_Celeste(filename.name);
%
% OUTPUT
% 'beh' - structure with extracted behavioral data
%
% Written by Anya Krok, Dec 2025

switch nargin
    case 1
        statetrans = varargin{1}; % assign the input table to statetrans
    case 2
        filePath = varargin{1}; % fileNames = varargin{2};
        cd(filePath)
        filename=dir('*StateTransitions.csv');
        statetrans=GetBonsai_Pho_StateTransitions_Celeste(filename.name);
end

%% time stamps
compTime = [statetrans.TimeOfDay]./1e3; % computer time
compTime_0 = compTime - compTime(1);
elapTime = [statetrans.ElapsedTime]; % elapsed time on bonsai
elapTime_0 = elapTime - elapTime(1);
TS0 = elapTime_0(:); % use elapsed time **CAN CHANGE**

%% 
uni = cellstr(unique(statetrans.Id)); % identify unique behavioral event names
nTrial = max(statetrans.Trial)+1; % total number of trials

%% TRIAL START
beh.trialStart = TS0(statetrans.Id == 'ITI');

%% TRIAL END
idx = nan(nTrial,1);
for n = 1:nTrial
    idx(n) = find([statetrans.Trial] == n-1, 1, 'last');
end
beh.trialEnd = TS0(idx);

%% LED and sound on
if any(strcmp(uni,'LEDon'))
    beh.ledOn = TS0(statetrans.Id == 'LEDon');
end
if any(strcmp(uni,'SoundOnLeft')) || any(strcmp(uni,'SoundOnRight'))
    beh.soundOn = [TS0(statetrans.Id == 'SoundOnLeft'); TS0(statetrans.Id == 'SoundOnRight')];
end
%% HIT
if any(strcmp(uni,'Hit'))
    rowsHit = find(statetrans.Id == 'Hit'); % row index for a Hit
elseif any(strcmp(uni,'LeftHit')) || any(strcmp(uni,'RightHit'))
    leftHit = find(statetrans.Id == 'LeftHit');
    rightHit = find(statetrans.Id == 'RightHit');
    rowsHit = sort([leftHit; rightHit]);
    beh.hitsL = TS0(leftHit);
    beh.hitsR = TS0(rightHit);
end
% hitTrial = statetrans.Trial(rowsHit)+1; % find the Trial # for Hits
% hitError = find(diff(sort(hitTrial)) == 0); % ensure that no overlappying Hits on the same trial
try beh.hits = TS0(rowsHit);
catch beh.hits = [];
end

%% MISS
try beh.miss = TS0(statetrans.Id == 'Miss');
catch beh.miss = [];
end

%% LICK: all lick left and all lick rights
try beh.lickLeft = TS0(statetrans.Id == 'LickLeft');
catch beh.lickLeft = [];
end
try beh.lickRight = TS0(statetrans.Id == 'LickRight');
catch beh.lickRight = [];
end
try beh.lickCenter = TS0(statetrans.Id == 'LickCenter');
catch beh.lickCenter = [];
end

%% LICK CENTER -- mouse initiates trial
% Identify row index for first LickCenter for each unique Trial
trials = unique(statetrans.Trial);
rowsLickCenter_trial = nan(size(trials));
for i = 1:numel(trials)
    rows = find(statetrans.Trial == trials(i));
    k = find(statetrans.Id(rows) == "LickCenter", 1, 'first');
    if ~isempty(k)
        rowsLickCenter_trial(i) = rows(k);
    end
end
trialFail = find(isnan(rowsLickCenter_trial)); % identify any trials that were not initiated
rowsLickCenter_trial(trialFail) = [];
try beh.lickStartTrial = TS0(rowsLickCenter_trial);
catch beh.lickStartTrial = [];
end

%% LICK CENTER -- preceding a hit
rowsLickCenter_preHit = nan(numel(rowsHit),1); % store preceding LickCenter (NaN if none)
for k = 1:numel(rowsHit)
    r = rowsHit(k);
    if r > 1
        idx = find(statetrans.Id(1:r-1) == 'LickCenter', 1, 'last');
        if ~isempty(idx)
            rowsLickCenter_preHit(k) = idx;
        end
    end
end
try beh.lickStartHitTrial = TS0(rowsLickCenter_preHit);
catch beh.lickStartHitTrial = [];
end
beh.rewLatency = beh.hits - beh.lickStartHitTrial;

%% INCORRECT ACTION aka NO HOLD
try beh.noHold = TS0(statetrans.Id == 'IncorrectAction');
catch beh.noHold = [];
end

%% TIMEOUT aka ERROR
try beh.error = TS0(statetrans.Id == 'Timeout');
catch beh.error = [];
end

%% TRIAL END ACTION
% Group trials and get unique trial ids
if statetrans.Id(end) == "ITI"
    statetrans(end,:) = [];
end
[G, trial] = findgroups(statetrans.Trial);

% For each group, take the last Id (last row within that trial)
lastAct = splitapply(@(ids) ids(end), statetrans.Id, G);   % categorical array, one per trial

% Take second to last Id (should be LickXXX)
secondLastAct = splitapply(@(ids) ids(end-1), statetrans.Id, G); % second to last action per trial
% s = string(secondLastAct); % convert to string vector
% maskNotLick = ~startsWith(s, "Lick") | isundefined(secondLastAct); % logical to identify which values do not start with Lick
% idx = find(maskNotLick); % any action non-Lick?

% Return result table
lastAct = table(trial, lastAct, secondLastAct,...
    'VariableNames', {'trial','lastAct','lastLick'});
lastAct(trialFail,:) = []; % remove trials where mouse failed to initiate trial with center poke, as identified above

beh.lastAct = lastAct;

end