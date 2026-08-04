function beh = extractGoNoGodataAK(statetrans, varargin)
% Extract behavioral events from bonsai output table for GoNoGo task
% ACTIVE as of June 2026
%
% beh = extractGoNoGodataAK(statetrans);
% beh = extractGoNoGodataAK(statetrans, 'photo'); % for photometry in Bonsai
%
% INPUT
% 'statetrans' - table made from GoTone_StateTransitions.csv
%       % How to extract into workspace?
%       filePath = uigetdir('Select Folder with StateTransitions.csv File');
%       cd(filePath)
%       fileName = dir('*StateTransitions.csv');
%       statetrans=GetBonsai_Pho_StateTransitions_Celeste(fileName.name);
% 'photo' - logical for photometry
%       For experiments with behavioral and photometry, then use fxn
%       'firstFrameBeforeEventIndex' to convert time stamps to "samples"
%       for ease of alignment with photometry signal.
%       fpTS = firstFrameBeforeEventIndex(compTimeStamp, timeVector)
%       hitTSphoto = firstFrameBeforeEventIndex(beh.hits, data.acq.time{1});
%
% OUTPUT
% 'beh' - structure with extracted behavioral data
%       Note that all time stamps are in SECONDS and elapsed time.
%
% USABILITY
%   mask = strcmpi(trial.label,'goTone') & strcmpi(trial.outcome,'Hit'); 
%   hitTone = trial.tone(mask); hit = trial.end(mask);
%   mask = strcmpi(trial.label,'goTone') & strcmpi(trial.outcome,'Miss'); 
%   missTone = trial.tone(mask); miss = trial.end(mask);
%   mask = strcmpi(trial.label,'catch') & strcmpi(trial.outcome,'CatchHit'); 
%   mask = strcmpi(trial.label,'catch') & strcmpi(trial.outcome,'CatchMiss'); 
%
% Written by Anya Krok, June 2026
% Adapted from extract2AFCdataAK
% Updated July 2026 to account for photometry data time stamps

elapTime = [statetrans.ElapsedTime]; % elapsed time on bonsai
elapTime_0 = elapTime - elapTime(1);
TS0 = elapTime_0(:);
if nargin == 2
    switch varargin{1}
        case 'photo'
            TS0 = [statetrans.TimeOfDay]./1000; % computer time, in seconds
            % For experiments with behavioral and photometry, then use fxn
            % 'firstFrameBeforeEventIndex' to convert time stamps to "samples"
            % for ease of alignment with photometry signal.
    end
end
TS0 = TS0(:);
statetrans.TS0 = TS0;

%% extract variables
% uni    = cellstr(unique(statetrans.Id)); % identify unique behavioral event names
ids    = string(statetrans.Id); % convert to string for easier comparison
% [G, trialNum] = findgroups(statetrans.Trial); % group trials and get unique trial ids

%% output variable
beh = struct;

%% table checks
% Adjustments if data collection ended in the middle of a trial.
% Note that GoNoGo trials should start with ITI if valid. All trials can be
% categorized by presentation of (a) Go tone, (b) NoGo tone, (c) Catch.
trials = unique(statetrans.Trial,'stable');    % unique trial identifiers, stable order
isITI = strcmpi(ids,'ITI');   % logical mask for ITI rows

% For each trial, find the row index of the first ITI occurrence
idxITI = NaN(numel(trials),1); % initialize vector of NaNs
for k = 1:numel(trials)
    maskITI = isITI & ismember(statetrans.Trial, trials(k)); % logical mask for ITI rows
    r = find(maskITI, 1, 'first'); % return first 'ITI' for this trial
    if ~isempty(r)
        idxITI(k) = r;
    end
end

% Excludes trial where no lick events occurred
ids = string(statetrans.Id);      % re-extract given updated statetrans
G = findgroups(statetrans.Trial); % re-extract given updated statetrans
isLick = strcmpi(ids(G == G(end)),'Lick'); % any lick events in last trial
if ~any(isLick)
    statetrans(G == G(end), :) = []; % remove last trial 
end

% % Remove last row if trial ended during ITI
% if statetrans.Id(end) == "ITI"
%     statetrans(end,:) = [];
% end

% Remove last trial if does not end with appropriate possible outcome
ids = string(statetrans.Id);      % re-extract given updated statetrans
G = findgroups(statetrans.Trial); % re-extract given updated statetrans
outcomes = {'hit','miss','correctrejection','falsealarm','catchhit','catchmiss'};
if ~any(strcmpi(outcomes, statetrans.Id(end)))
    statetrans(G == G(end), :) = []; % remove last trial
end

%% re-extract given updated statetrans
clearvars -except statetrans TS0
trials = unique(statetrans.Trial, 'stable'); % update unique trials
uni    = cellstr(unique(statetrans.Id)); % identify unique behavioral event names
ids    = string(statetrans.Id); % convert to string for easier comparison
G      = findgroups(statetrans.Trial); % group trials and get unique trial ids
trialNum = 1:numel(trials); trialNum = trialNum(:);
nTrial = numel(trials);

%% 
% LICKS
try beh.lick = TS0(ids == 'Lick');
catch, beh.lick = [];
end

%% 
% TRIAL START
trialStart = TS0(strcmpi(ids, 'ITI'));

% GO TONE or NOGO TONE or CATCH trial
maskGo    = find(strcmpi(ids,'go'));
maskNoGo  = find(strcmpi(ids,'nogo'));
maskCatch = find(strcmpi(ids,'catchtrial'));
trialGo   = statetrans.Trial(maskGo);
trialNoGo = statetrans.Trial(maskNoGo);
trialCatch = statetrans.Trial(maskCatch);

% TRIAL LABEL
trialLbl = strings(nTrial,1); % initialize string vector
trialLbl(trialGo) = "goTone";
trialLbl(trialNoGo) = "nogoTone";
trialLbl(trialCatch) = "catch";

% TONE
tone = zeros(nTrial,1);
tone(trialGo) = TS0(maskGo); % time stamp of tone
tone(trialNoGo) = TS0(maskNoGo); % time stamp of tone
tone(trialCatch) = TS0(maskCatch); % time stamp of catch

% LAST ACT
% For each group, take the last Id (last row within that trial)
lastAct = splitapply(@(ids) ids(end), ids, G);   % categorical array, one per trial

% TRIAL END
% Last event in trial
% Go tone: Hit or Miss
% NoGo tone: CorrectRejection or False Alarm
% Catch trial: CatchHit or CatchMiss
idx = nan(nTrial,1);
for n = 1:nTrial
    idx(n) = find([statetrans.Trial] == n, 1, 'last');
end
trialEnd = TS0(idx);

% For NoGo --> FalseAlarm, change trialEnd to be time stamp of 'Timeout'
% (current default is time stamp of 'FalseAlarm'
trialFA = find(strcmpi(lastAct,'falsealarm'));
idxFAend = nan(numel(trialFA),1);
for j = 1:numel(trialFA)
    k = trialFA(j);
    mask = ([statetrans.Trial] == k & strcmpi(ids,'timeout'));
    idxFAend(j) = find(mask,1,'first');
end
trialEnd(trialFA) = TS0(idxFAend); 

%%
% ENSURE VARIABLES ARE THE SAME LENGTH
%sometimes if run is terminated manually, it can end in the middle of a
%trial such that some events (trialStart, ledOn) may have occurred but
%others may not have happened for last trial (eg, soundOn)
vars = {trialNum, trialLbl, lastAct, trialStart, tone, trialEnd};  % add all variables you use
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
    [trialNum, trialLbl, lastAct, trialStart, tone, trialEnd] = vars{:};
end % Now safe to create the table

%%
% CREATE TABLE
trial = table(trialNum, trialLbl, lastAct, trialStart, tone, trialEnd,...
    'VariableNames', {'num','label','outcome','start','tone','end'});

% CHECK that time values sequentially increase from:
%   start-tone-end
A = table2array(trial(:,4:6));      % numeric/datetime-compatible assumed
viol = any(diff(A,1,2) < 0, 2);        % true for rows that decrease somewhere
trial(viol,:) = []; % remove violations

% SAVE INTO STRUCTURE
beh.trial = trial;

%%
mask = strcmpi(trial.label,'goTone') & strcmpi(trial.outcome,'Hit');
hit = table(trial.num(mask), trial.tone(mask), trial.end(mask), ...
    'VariableNames', {'num','tone','end'});
mask = strcmpi(trial.label,'goTone') & strcmpi(trial.outcome,'Miss'); 
miss = table(trial.num(mask), trial.tone(mask), trial.end(mask), ...
    'VariableNames', {'num','tone','end'});

mask = strcmpi(trial.label,'nogoTone') & strcmpi(trial.outcome,'CorrectRejection');
nogoCR = table(trial.num(mask), trial.tone(mask), trial.end(mask), ...
    'VariableNames', {'num','tone','end'});
mask = strcmpi(trial.label,'nogoTone') & strcmpi(trial.outcome,'FalseAlarm'); 
nogoFA = table(trial.num(mask), trial.tone(mask), trial.end(mask), ...
    'VariableNames', {'num','tone','end'});

mask = strcmpi(trial.label,'catch') & strcmpi(trial.outcome,'CatchHit');
catchHit = table(trial.num(mask), trial.tone(mask), trial.end(mask), ...
    'VariableNames', {'num','tone','end'});
mask = strcmpi(trial.label,'catch') & strcmpi(trial.outcome,'CatchMiss'); 
catchMiss = table(trial.num(mask), trial.tone(mask), trial.end(mask), ...
    'VariableNames', {'num','tone','end'});

beh.hit = hit;
beh.miss = miss;
beh.corrReject = nogoCR;
beh.falseAlarm = nogoFA;
beh.catchHit = catchHit;
beh.catchMiss = catchMiss;

end