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
% Updated by Anya Krok, Feb 2026 to organize data in tables based on Trial
% and Hits

switch nargin
    case 1
        statetrans = varargin{1}; % assign the input table to statetrans
    case 2
        filePath = varargin{1}; % fileNames = varargin{2};
        cd(filePath)
        filename=dir('*StateTransitions.csv');
        statetrans=GetBonsai_Pho_StateTransitions_Celeste(filename.name);
end

%% output variable
beh = struct;

%% table checks

% Adjustments if data collection ended in the middle of a trial:
% note that 2AFC trials should include ITI, LEDon if valid.

trials = unique(statetrans.Trial,'stable');    % unique trial identifiers, stable order
isITI = strcmp(string(statetrans.Id),'ITI');   % logical mask for ITI rows
isLED = strcmp(string(statetrans.Id),'LEDon'); % logical mask for LEDon rows

% For each unique trial, find the row index of the first ITI occurrence and
% the first LEDon occurrence
idxITI = NaN(numel(trials),1); % initialize vector of NaNs
idxLED = NaN(numel(trials),1); % initialize vector of NaNs
for k = 1:numel(trials)
    maskITI = isITI & ismember(statetrans.Trial, trials(k)); % logical mask for ITI rows
    r = find(maskITI, 1, 'first'); % return first 'ITI' for this trial
    if ~isempty(r)
        idxITI(k) = r;
    end
    maskLED = isLED & ismember(statetrans.Trial, trials(k)); % logical mask for LEDon rows
    r2 = find(maskLED, 1, 'first');
    if ~isempty(r2)
        idxLED(k) = r2;
    end
end

% If some trials do not include LEDon, remove those trials from table. 
% Note that if all NaN then will keep all data.
if any(isnan(idxLED)) && ~all(isnan(idxLED))
    nanTrials = trials(isnan(idxLED)); % trial number for trial without LEDon
    nanRows = ismember(statetrans.Trial, nanTrials); % row indices corresponding to trial
    statetrans(nanRows, :) = [];  % remove trial from table
    trials = unique(statetrans.Trial, 'stable'); % update unique trials after filtering
end

% Remove last row if trial ended during ITI
if statetrans.Id(end) == "ITI"
    statetrans(end,:) = [];
    trials = unique(statetrans.Trial, 'stable'); % update unique trials
end

%% extract variables
uni = cellstr(unique(statetrans.Id)); % identify unique behavioral event names
nTrial = max(statetrans.Trial)+1; % total number of trials
[G, trialNum] = findgroups(statetrans.Trial); % group trials and get unique trial ids
if trialNum(1) == 0; trialNum = trialNum+1; end % adjust for zero index 

%% time stamps
compTime = [statetrans.TimeOfDay]./1e3; % computer time
compTime_0 = compTime - compTime(1);
elapTime = [statetrans.ElapsedTime]; % elapsed time on bonsai
elapTime_0 = elapTime - elapTime(1);
TS0 = elapTime_0(:); % use elapsed time **CAN CHANGE**

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

%% TRIAL TABLE
% TRIAL START
trialStart = TS0(statetrans.Id == 'ITI');

% TRIAL END
idx = nan(nTrial,1);
for n = 1:nTrial
    idx(n) = find([statetrans.Trial] == n-1, 1, 'last');
end
trialEnd = TS0(idx);

% LED ON
ledOn = nan(length(trialStart),1);
if any(strcmp(uni,'LEDon'))
    ledOn = TS0(statetrans.Id == 'LEDon');
end

% LICK to START TRIAL
% Identify row index for first LickCenter for each unique Trial
pokeCenter_firstInTrial = nan(size(trials));
for ii = 1:numel(trials)
    rows = find(statetrans.Trial == trials(ii));
    if isempty(rows); continue; end
    if any(strcmp(uni,'LEDon')) % if LEDon exists
        % then consider only rows strictly after LEDon event
        ids = string(statetrans.Id(rows)); % Ids for this trial only
        isLed = contains(ids,"LEDon",'IgnoreCase',true);
        idxLed = find(isLed, 1, 'first'); % row relative to this trial only
        candidateRows = rows(rows > rows(idxLed));
    else
        candidateRows = rows; % else, fallback to whole trial
    end
    candIds = string(statetrans.Id(candidateRows));
    k = find(candIds == "LickCenter", 1, 'first');
    if ~isempty(k)
        pokeCenter_firstInTrial(ii) = candidateRows(k);
    end
end
trialFail = find(isnan(pokeCenter_firstInTrial)); % identify any trials that were not initiated
pokeCenter_firstInTrial(trialFail) = [];
try pokeStartTrial = TS0(pokeCenter_firstInTrial);
catch pokeStartTrial = [];
end

% SOUND ON and SIDE
soundOn = nan(length(trialStart),1); % initialize variable as NaN array
hitSide = strings(numel(trialStart),1);  % initialize variable as string array
if any(strcmp(uni,'SoundOnLeft')) || any(strcmp(uni,'SoundOnRight'))
    soundOn = sort([TS0(statetrans.Id == 'SoundOnLeft'); TS0(statetrans.Id == 'SoundOnRight')]);

    isRightTrial = splitapply(@(ids) any(ids == "SoundOnRight"), ...
        string(statetrans.Id(:)), G); % return logical if for given trial, there is sound on right
    isLeftTrial  = splitapply(@(ids) any(ids == "SoundOnLeft"), ...
        string(statetrans.Id(:)), G); % return logical if for given trial, there is sound on left
    hitSide(isRightTrial) = "right"; % assign by logical index
    hitSide(isLeftTrial)  = "left"; % assign by logical index
    hitSide(~(isRightTrial | isLeftTrial)) = ""; % mark unspecified as empty
    hitSide = cellstr(hitSide); % convert to cell array of character vectors
end

% For each group, take the last Id (last row within that trial)
lastAct = splitapply(@(ids) ids(end), statetrans.Id, G);   % categorical array, one per trial

% Take second to last Id (should be LickXXX)
lastLick = splitapply(@(ids) ids(end-1), statetrans.Id, G); % second to last action per trial
% s = string(secondLastAct); % convert to string vector
% maskNotLick = ~startsWith(s, "Lick") | isundefined(secondLastAct); % logical to identify which values do not start with Lick
% idx = find(maskNotLick); % any action non-Lick?

% ENSURE VARIABLES ARE THE SAME LENGTH
%sometimes if run is terminated manually, it can end in the middle of a
%trial such that some events (trialStart, ledOn) may have occurred but
%others may not have happened for last trial (eg, soundOn)
vars = {trialNum, hitSide, lastAct, trialStart, ledOn, pokeStartTrial, ...
        soundOn, lastLick, trialEnd};  % add all variables you use
n = cellfun(@(x) numel(x), vars); % Compute lengths (treat empty as length 0)
minN = min(n); % Desired length = minimum

if any(n ~= minN) % If already equal, nothing to do
    % Truncate each variable to 1:minN and ensure column shape
    for k = 1:numel(vars)
        v = vars{k};
        % If char matrix (M-by-N), treat rows as elements => keep first minN rows
        if ischar(v)
            vars{k} = v(1:minN, :);
        else
            % For vectors or cell arrays, take first minN elements and make column
            vars{k} = reshape(v(1:minN), [], 1);
        end
    end
    % Reassign back to named variables (in workspace of this function/script)
    [trialNum, hitSide, lastAct, trialStart, ledOn, pokeStartTrial, ...
     soundOn, lastLick, trialEnd] = vars{:};
end % Now safe to create the table

% CREATE TABLE
byTrial = table(trialNum, hitSide, lastLick, lastAct, trialStart, ledOn, pokeStartTrial, soundOn, trialEnd,...
    'VariableNames', {'num','side','lastLick','lastAct','start','ledOn','pokeStart','soundOn','end'});
% byTrial(trialFail,:) = []; % remove trials where mouse failed to initiate trial with center poke, as identified above

% CHECK that time values sequentially increase from:
%   start-ledOn-pokeStart-soundOn-end
A = table2array(byTrial(:,[5:9]));      % numeric/datetime-compatible assumed
viol = any(diff(A,1,2) < 0, 2);        % true for rows that decrease somewhere
violRows = find(viol);

% SAVE INTO STRUCTURE
beh.trial = byTrial;

%% HITS

% WHEN HITS
if any(strcmp(uni,'Hit'))
    rowsHit = find(statetrans.Id == 'Hit'); % row index for a Hit
elseif any(strcmp(uni,'LeftHit')) || any(strcmp(uni,'RightHit'))
    leftHit = find(statetrans.Id == 'LeftHit');
    rightHit = find(statetrans.Id == 'RightHit');
    rowsHit = sort([leftHit; rightHit]);
else
    rowsHit = [];
end

% EMPTY TABLE IF NO HITS
if isempty(rowsHit)
    hitsT = table([],string.empty(0,1),[],[],...
        'VariableNames',{'trial','side','hits','rewLatency'});
else
    % TRIAL NUMBER
    hitTrial = statetrans.Trial(rowsHit); % find the Trial # for Hits
    if statetrans.Trial(1) == 0; hitTrial = hitTrial + 1; end % adjust for zero index

    % SIDE
    hitSide = strings(numel(rowsHit),1);  % initialize variable as string array
    hitSide(ismember(rowsHit, leftHit)) = "left";
    hitSide(ismember(rowsHit, rightHit)) = "right";
    hitSide(ismissing(hitSide)) = ""; % mark unspecified as empty
    hitSide = cellstr(hitSide); % convert to cell array of character vectors

    % HIT TIME STAMP
    hitTime = TS0(rowsHit);

    % REWARD LATENCY
    rewLatency = hitTime - pokeStartTrial(hitTrial);

    hitsT = table(hitTrial,hitTime,hitSide,rewLatency,...
        'VariableNames',{'trial','hits','side','rewLatency'});
end
beh.hitT = hitsT; % table 
beh.hits = beh.hitT.hits; % time stamps for hits

%% MISS
try beh.miss = TS0(statetrans.Id == 'Miss');
catch beh.miss = [];
end

%% INCORRECT ACTION aka NO HOLD
try beh.noHold = TS0(statetrans.Id == 'IncorrectAction');
catch beh.noHold = [];
end

%% TIMEOUT aka ERROR
try beh.error = TS0(statetrans.Id == 'Timeout');
catch beh.error = [];
end

end