function out = analyzeTrialExample(comb, varargin)
% Photometry dynamics and licks recorded from an example mouse during a 
% bandit task session. 
% - For plotting, each row depicts the baselined sensor signal of a trial.
% - t = 0 reflect trial start time as determined by mouse center poke.
% - red dots reflect trial end time, aka final correct lick / "hit".
%
% out = analyzeTrialExample(comb)
% out = analyzeTrialExample(comb, win)
% 
% NOTE: must run most recent bonsai behavior extraction code, which
% includes new variables beh.trialStart and beh.trialEnd.
%
% INPUTS
%   'comb': SINGLE RECORDING from combined data structure
%   'win': window, in seconds, for analysis. Eg, [-1 5]
%
% OUTPUTS
%   'out': structure with saved outputs, for plotting with script
%       'plotTrialsColormap.m'
%
% Anya Krok, December 2025

%% INPUTS
switch nargin
    case 2
        win = varargin{1};
    case 1
        win = [-1 5]; % in seconds
end
win_base = [win(1)-1 win(1)]; % for baseline adjusting photometry signal
    % default is 1 second window preceding window for analysis
bin_peth = 0.05; % bin width, in seconds, for aligning licks to events

%% Pull relevant data
Fs      = comb.Fs; 
beh     = comb.beh;
nFP     = length(comb.FPnames);

%% Rewarded trials
% For rewarded trials, alignment of photometry to 
% (1) first center poke (when mouse self-initiates trial) 
% and (2) reward delivery.
% Note that behavior event times are in samples relative to processed
% photometry sampling frequency, usually 50 Hz.
nTrials  = height(beh.trial);
nHits    = height(beh.hitT);
idxHits  = beh.hitT.trial; % index for rewarded trials
idxHitsR = idxHits(strcmpi(beh.hitT.side, 'right')); % note these are relative to ALL trials
idxHitsL = idxHits(strcmpi(beh.hitT.side, 'left')); % note these are relative to ALL trials
idxSidebyTr  = {idxHitsR, idxHitsL}; % store in cell array for looping
idxSidebyHit = {find(strcmpi(beh.hitT.side,'right')), find(strcmpi(beh.hitT.side,'left'))};
lickSide = {beh.lickRight, beh.lickLeft}; % store in cell array for looping
tr_start = beh.trial.start; % trial start
tr_end   = beh.trial.end;   % trial end
firstPoke = beh.trial.firstPoke; % mouse self-initiation
soundOn   = beh.trial.soundOn;   % soundOn
hit      = beh.hitT.hits;
rewLatency = cell(1,2);
rewLatency{1} = beh.hitT.rewLatency(idxSidebyHit{1}); % latency from firstPoke to right hit
rewLatency{2} = beh.hitT.rewLatency(idxSidebyHit{2});  % latency from firstPoke to left hit
if isnan(beh.trial.start(1))
    rmv = find(isnan(beh.trial.start)); % index of first trial that starts after photometry
    idxHits(ismember(idxHits, rmv)) = nan; % replace with nan to exclude from analysis
end

%% 
% Align licks to events:
% Lick rate aligned to self-initiation of trial (poke center after LEDon),
% separated by right/left trials.
lickRate = cell(1,2); % initialize output variable
nBins = -1 + numel(win(1):bin_peth:win(2));    % original bin count
for s = 1:2 % right, left
    lickRate{s} = nan(nBins, nHits);           % preallocate NaNs
    % process each potential hit index
    for n = 1:numel(idxSidebyTr{s})
        id = idxSidebyTr{s}(n);
        % validate id and lick vectors
        if isnan(id) || id <= 0 || id > nTrials || isempty(lickSide{s})
            continue
        end
        % find licks in trial window
        idxSort = find(lickSide{s} >= tr_start(id) & lickSide{s} <= tr_end(id));
        if isempty(idxSort)
            continue
        end
        tmpLick = lickSide{s}(idxSort);
        % compute peri-event histogram (aligning to first poke for that trial)
        % guard: ensure firstPoke index exists for this id
        if id <= numel(firstPoke)
            peth = getClusterPETH(tmpLick./Fs, firstPoke(id)./Fs, bin_peth, win);
            lickRate{s}(:,n) = peth.fr;
        else
            % leave as NaNs if no firstPoke available
            lickRate{s}(:,n) = nan(nBins,1);
        end
    end
    % clamp values and select hits by idxSidebyHit{s}
    lickRate{s}(lickRate{s} > 1) = 1;
    lickRate{s} = lickRate{s}(:, idxSidebyHit{s});
end

%% 
% Align photometry signals to behavioral events
% Events:
%   (1) first center poke for rewarded trials
%   (2) reward delivery
%   (3) sound on right rewarded trials
%   (4) sound on left rewarded trials
%   (5) sound on for all miss trials
%   (6) sound on for all error trials
%   (7) sound on for all abort trials
opts = {'rightHit','leftHit','miss','incorrectAction','abort'};
photo2event = cell(2+length(opts),nFP); % store values, photometry to event

for b = 1:nFP
    signal = comb.FP{b};

    event = firstPoke(idxHits)./Fs; % firstPoke for all rewarded trials
    sta = getSTA(signal, event, Fs, win); % align photometry to event
    sta_base = getSTA(signal, event, Fs, win_base); % align pre-event window
    sta = sta - mean(sta_base,1,'omitnan'); % subtract baseline average signal
    photo2event{1,b} = sta;

    event = hit./Fs; % reward delivery
    sta = getSTA(signal, event, Fs, win);
    sta_base = getSTA(signal, event, Fs, win_base);
    sta = sta - mean(sta_base,1,'omitnan');
    photo2event{2,b} = sta;
    
    for ii = 1:length(opts)
        j = strcmpi(beh.trial.lastAct, opts{ii}); % find trial index that matches option
        if any(j) % if any matching trials exist, then continue
            event = soundOn(j)./Fs; % soundOn by outcome
            sta = getSTA(signal, event, Fs, win);
            sta_base = getSTA(signal, event, Fs, win_base);
            sta = sta - mean(sta_base,1,'omitnan');
            photo2event{2+ii,b} = sta;
        else
            photo2event{2+ii,b} = nan;
        end
    end
end
time_sta = win(1) : 1/Fs : win(2); % time vector
lbls = {'pokeRew','reward','soundOnHitR','soundOnHitL','soundOnMiss','soundOnError','soundOnAbort'}; % table headers
T = cell2table(photo2event.', 'VariableNames', lbls); % store into table

%% store
a = 1; 
out = struct;
out(a).mouse = comb.mouse;
out(a).date  = comb.date;
out(a).win   = win;
out(a).evPhoto  = T;
out(a).time  = time_sta(:);
out(a).evLicks  = lickRate;
out(a).timePeth = peth.time(:);
out(a).rewLat   = rewLatency;
out(a).idxSide  = idxSidebyHit;
out(a).lblSide  = {'right','left'};
out(a).lblPhoto = comb.FPnames; 


