function beh = extract2AFCdataAK(statetrans, varargin)
% Extract behavioral events from bonsai output table
% Task: 2AFC
%
% beh = extract2AFCdataAK(statetrans)
% beh = extract2AFCdataAK(statetrans, 'photo')
%
% INPUT
% 'statetrans' - table made from StateTransitions.csv
%       % How to extract into workspace?
%       filePath = uigetdir('Select Folder with StateTransitions.csv File');
%       cd(filePath)
%       fileName = dir('*StateTransitions.csv');
%       statetrans=GetBonsai_Pho_StateTransitions_Celeste(fileName.name);
% 'photo' or 'photoWS' - logical for photometry
%       For experiments with behavioral and photometry, then use fxn
%       'firstFrameBeforeEventIndex' to convert time stamps to "samples"
%       for ease of alignment with photometry signal.
%       fpTS = firstFrameBeforeEventIndex(compTimeStamp, timeVector)
%       hitTSphoto = firstFrameBeforeEventIndex(beh.hits, data.acq.time{1});
%
% OUTPUT
% 'beh' - structure with extracted behavioral data
%       Note that all time stamps are in seconds and are elapsed time,
%       unless photometry then time stamps are in computer time.
%
% Written by Anya Krok, Dec 2025
% Updated by Anya Krok, Feb 2026 to organize data in tables based on Trial
% and Hits
% Updated by Anya Krok, Mar 2026 to add additional error outcomes
%   beh.miss - no response within reward window
%   beh.error - incorrect action (eg, soundOnLeft but lickRight)
%   beh.noHold - does not maintain hold (eg, pokeCenter but NO soundOn)

elapTime = [statetrans.ElapsedTime]; % elapsed time on bonsai
elapTime_0 = elapTime - elapTime(1);
TS0 = elapTime_0(:);
if nargin == 2
    switch varargin{1}
        case 'photo'
            TS0 = [statetrans.TimeOfDay]; % computer time
            % For experiments with behavioral and photometry, then use fxn
            % 'firstFrameBeforeEventIndex' to convert time stamps to "samples"
            % for ease of alignment with photometry signal.
        case 'photoWS'
            TS0 = [statetrans.PhotoTime]; 
    end
end
TS0 = TS0(:);

%% extract variables
% uni    = cellstr(unique(statetrans.Id)); % identify unique behavioral event names
ids    = string(statetrans.Id); % convert to string for easier comparison
% [G, trialNum] = findgroups(statetrans.Trial); % group trials and get unique trial ids

%% output variable
beh = struct;

%% table checks

% Adjustments if data collection ended in the middle of a trial:
% note that 2AFC trials should include ITI, LEDon if valid.

trials = unique(statetrans.Trial,'stable');    % unique trial identifiers, stable order
isITI = strcmpi(ids,'ITI');   % logical mask for ITI rows
isLED = strcmpi(ids,'LEDon'); % logical mask for LEDon rows

% For each trial, find the row index of the first ITI occurrence and
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

% Exclude trials where LEDon did not occur. 
% BUT if all NaN then will keep all data, as may have been training day
% without LED.
if any(isnan(idxLED)) && ~all(isnan(idxLED))
    nanTrials = trials(isnan(idxLED)); % trial number for trial without LEDon
    nanRows = ismember(statetrans.Trial, nanTrials); % row indices corresponding to trial
    statetrans(nanRows, :) = [];  % remove trial from table
end

% Excludes trial where no lick events occurred
ids = string(statetrans.Id);      % re-extract given updated statetrans
G = findgroups(statetrans.Trial); % re-extract given updated statetrans
isLick = strcmpi(ids(G == G(end)),'LickLeft') ... % any lick events in last trial
        | strcmpi(ids(G == G(end)),'LickRight') ...
        | strcmpi(ids(G == G(end)),'LickCenter');
if ~any(isLick)
    statetrans(G == G(end), :) = []; % remove last trial 
end

% % Remove last row if trial ended during ITI
% if statetrans.Id(end) == "ITI"
%     statetrans(end,:) = [];
% end

%% re-extract given updated statetrans
clearvars -except statetrans TS0
trials = unique(statetrans.Trial, 'stable'); % update unique trials
uni    = cellstr(unique(statetrans.Id)); % identify unique behavioral event names
ids    = string(statetrans.Id); % convert to string for easier comparison
G      = findgroups(statetrans.Trial); % group trials and get unique trial ids
trialNum = 1:numel(trials); trialNum = trialNum(:);
nTrial = numel(trials);

%% LICK: all lick left and all lick rights
try beh.lickLeft = TS0(ids == 'LickLeft');
catch, beh.lickLeft = [];
end
try beh.lickRight = TS0(ids == 'LickRight');
catch, beh.lickRight = [];
end
try beh.pokeCenter = TS0(ids == 'LickCenter');
catch, beh.pokeCenter = [];
end

%% TRIAL TABLE
% TRIAL START
trialStart = TS0(strcmpi(ids, 'ITI'));

% TRIAL END
idx = nan(nTrial,1);
for n = 1:nTrial
    idx(n) = find([statetrans.Trial] == n, 1, 'last');
end
trialEnd = TS0(idx);

% LED ON
ledOn = nan(length(trialStart),1);
if any(strcmp(uni,'LEDon'))
    ledOn = TS0(strcmpi(ids, 'LEDon'));
end

% LICK to START TRIAL
% Identify row index for first LickCenter for each unique Trial
firstPokeIdx = nan(numel(trials), 1);
for ii = 1:numel(trials)
    rows = find(G == ii); % row indices for this trial
    sid  = ids(G == ii);  % Id strings for this trial
    % first 'lickCenter' after 'LEDon' in this trial
    ledIdx = find(strcmpi(sid,"LEDon"), 1, 'first');   % index into sid/rinds
    if ~isempty(ledIdx)
        lickAfter = find(strcmpi(sid,"LickCenter") & ( (1:numel(sid))' > ledIdx ), 1, 'first');
        if ~isempty(lickAfter)
            firstPokeIdx(ii) = rows(lickAfter);
        else
            firstPokeIdx(ii) = nan; % LEDon present but no LickCenter after
        end
    else
        firstPokeIdx(ii) = nan;     % no LEDon -> per spec return NaN
    end
end
trialNoStart = isnan(firstPokeIdx); % identify any trials that were not initiated
firstPokeIdx(trialNoStart) = [];
try firstPoke = TS0(firstPokeIdx);
catch, firstPoke = [];
end
trials = setdiff(trials, trials(trialNoStart)); % exclude not-initiated trials

% SOUND ON and SIDE
soundOn = nan(length(trialStart),1); % initialize variable as NaN array
hitSide = strings(numel(trialStart),1);  % initialize variable as string array
if any(strcmp(uni,'SoundOnLeft')) || any(strcmp(uni,'SoundOnRight'))
    soundOn = sort([TS0(strcmpi(ids,'SoundOnLeft')); TS0(strcmpi(ids,'SoundOnRight'))]);

    isRightTrial = splitapply(@(x) any(strcmpi(x,'SoundOnRight')), ids, G); % for each trial, does soundRight occur
    isLeftTrial  = splitapply(@(x) any(strcmpi(x,'SoundOnLeft')),  ids, G); % for each trial, does soundLeft occur
    hitSide(isRightTrial) = "right"; % assign by logical index
    hitSide(isLeftTrial)  = "left"; % assign by logical index
    hitSide(~(isRightTrial | isLeftTrial)) = ""; % mark unspecified as empty
    hitSide = cellstr(hitSide); % convert to cell array of character vectors
end

% For each group, take the last Id (last row within that trial)
lastAct = splitapply(@(ids) ids(end), ids, G);   % categorical array, one per trial
% needFix = find(startsWith(lastAct,'Lick','IgnoreCase',true)); % identify when last action is Lick action
% for ii = needFix
%     rows = find(G == ii); % row indices for this trial
%     sid  = ids(G == ii); % labels for this trial
%     tmp  = ids(rows(end-1)); ticker = 1; % prior value
%     while startsWith(tmp,'Lick') & (ticker < length(rows))
%         ticker = ticker + 1;
%         tmp = ids(rows(end-ticker));
%     end
%     lastAct(ii) = tmp;
%     % OR
    % j = find(~startsWith(sid, "Lick", "IgnoreCase", true), 1, 'last');
    % if isempty(j)
    %     lastAct(ii) = missing;            % no non-Lick found
    % else
    %     lastAct(ii) = sid(j);
    % end
% end
%

% Take second to last Id (should be LickXXX)
lastLick = splitapply(@(ids) ids(end-1), ids, G); % second to last action per trial
% s = string(secondLastAct); % convert to string vector
% maskNotLick = ~startsWith(s, "Lick") | isundefined(secondLastAct); % logical to identify which values do not start with Lick
% idx = find(maskNotLick); % any action non-Lick?

%%
% ENSURE VARIABLES ARE THE SAME LENGTH
%sometimes if run is terminated manually, it can end in the middle of a
%trial such that some events (trialStart, ledOn) may have occurred but
%others may not have happened for last trial (eg, soundOn)
vars = {trialNum, hitSide, lastAct, trialStart, ledOn, firstPoke, ...
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
    [trialNum, hitSide, lastAct, trialStart, ledOn, firstPoke, ...
     soundOn, lastLick, trialEnd] = vars{:};
end % Now safe to create the table

% CREATE TABLE
byTrial = table(trialNum, hitSide, lastLick, lastAct, trialStart, ledOn, firstPoke, soundOn, trialEnd,...
    'VariableNames', {'num','side','lastLick','lastAct','start','ledOn','firstPoke','soundOn','end'});
% byTrial(trialFail,:) = []; % remove trials where mouse failed to initiate trial with center poke, as identified above

% CHECK that time values sequentially increase from:
%   start-ledOn-pokeStart-soundOn-end
A = table2array(byTrial(:,5:9));      % numeric/datetime-compatible assumed
viol = any(diff(A,1,2) < 0, 2);        % true for rows that decrease somewhere
violRows = find(viol);

% SAVE INTO STRUCTURE
beh.trial = byTrial;

%% HITS

% WHEN HITS
if any(strcmp(uni,'Hit'))
    rowsHit = find(strcmpi(ids, 'Hit')); % row index for a Hit
elseif any(strcmp(uni,'LeftHit')) || any(strcmp(uni,'RightHit'))
    leftHit = find(strcmpi(ids, 'LeftHit'));
    rightHit = find(strcmpi(ids, 'RightHit'));
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
    rewLatency = hitTime - firstPoke(hitTrial);

    hitsT = table(hitTrial,hitTime,hitSide,rewLatency,...
        'VariableNames',{'trial','hits','side','rewLatency'});
end
beh.hitT = hitsT; % table 
beh.hits = beh.hitT.hits; % time stamps for hits

%% ABORT HOLD
% For correctly fulfilled hold requirement, will be in table as
% LickCenter > SoundOnLeft/Right, and must be sequential. If not, then
% mouse failed hold and may re-attempt.
%
beh.abort = nan(numel(trials),1);
try 
    beh.abort = TS0(strcmpi(ids,'abort')); % in full behavior, will have return of 'Abort'
catch
    % ensuring that checks for an immediate adjacency: a "LickCenter" at position k followed by "SoundOnLeft" or "SoundOnRight" at position k+1 within the same trial.
    % for k = 1:nTrial
    %     rows = find(G == k); % row indices for this trial
    %     sid  = ids(G == k); % labels for this trial
    %     isLC = strcmpi(sid, 'lickcenter'); % check for position where Id is 'LickCenter'
    %     nextIsSound = strcmpi(sid(2:end), "SoundOnLeft") | strcmpi(sid(2:end), "SoundOnRight");
    %     hasPair = any(isLC(1:end-1) & nextIsSound);
    %     if ~hasPair
    %         beh.abort(k) = k; % CHANGE -- currently returning trial number
    %     end
    % end

    % written to check if there is no sound played for given trial
    isSoundEvent = strcmpi(ids,'SoundOnLeft') | strcmpi(ids,'SoundOnRight'); % rows that are sound events (case-insensitive)
    trialSound  = unique(statetrans.Trial(isSoundEvent)); % trials that have sound events
    trialNoSound = setdiff(trials, trialSound); % returns trials that do NOT have sound events
    for ii = 1:numel(trialNoSound)
        mask = (statetrans.Trial == trialNoSound(ii)) & strcmpi(ids,'LickCenter');
        if any(mask)
            beh.abort(ii,1) = TS0(find(mask, 1, 'last')); % record the timestamp of the last lick event
        end
    end
    if all(isnan(beh.abort)); beh.abort = []; end
end

beh.pokeCount = splitapply(@(s) sum(strcmpi(s,'LickCenter')), ids, G);

%% MISS
% Example: soundOnLeft then does NOT lickLeft OR lickRight within reward window. 
% Different from error/incorrectAction as detailed below, as mouse did not
%   provide any response rather than performed an incorrect response.
try beh.miss = TS0(strcmpi(ids,'miss'));
    % % Alternatively, can do:
    % beh.miss = beh.trial.end(strcmpi(string(beh.trial.lastAct),'Miss'));
catch, beh.miss = [];
end

%% INCORRECT ACTION
% Example: soundOnLeft but only lickRight within reward window.
% If this occurs during training will have a 'Timeout' period of 3 sec as a
%   punishment, in addition to usual ITI.
% Note that multiple 'IncorrectAction' may occur within given trial, but as
%   long as mouse completes center-hold then correctly collects reward
%   as directed by sound then can still have Hit trial. 
try 
    % beh.error = TS0(statetrans.Id == 'IncorrectAction'); 
    % % Changed because trials can have multiple IncorrectActions but only 
    % % want time stamp of last occurence.
    % % Instead for trial where lastAct is incorrectAction return trial
    % % end time, which is same as last occurrence.
    beh.error = beh.trial.end(strcmpi(string(beh.trial.lastAct),'IncorrectAction'));
catch, beh.error = [];
end

end