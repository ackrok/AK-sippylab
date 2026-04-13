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
nTrials = height(beh.trial);
nHits   = height(beh.hitT);
idxHits = beh.hitT.trial; % index for rewarded trials
tr_start = beh.trial.start; % trial start
tr_end   = beh.trial.end;   % trial end
firstPoke = beh.trial.firstPoke; % alignment to mouse self-initiation of rewarded trial
soundOn   = beh.trial.soundOn; 
hit = beh.hitT.hits;
rewLatency = beh.hitT.rewLatency; % latency from firstPoke to Hit
if all(rewLatency == 0); rewLatency(:) = nan; end 

if isnan(beh.trial.start(1))
    rmv = find(isnan(beh.trial.start)); % index of first trial that starts after photometry
    idxHits(ismember(idxHits, rmv)) = nan;
end
idxHitsR = idxHits(strcmpi(beh.hitT.side,'right'));
idxHitsL = idxHits(strcmpi(beh.hitT.side,'left'));
idxSide  = {idxHitsR, idxHitsL};

%% Analysis: extract all licks for rewarded trials
% for some recordings with photometry, trial start may coincide with start
% of photometry and thus 1st trial will remain NaN due to no photometry
% frames being documented prior to trial start time

hitLicks = cell(nHits,2); % initialize variable
for n = 1:numel(idxHitsR); s = 1; % right
    if isnan(idxHitsR(n)); hitLicks{n,s} = nan; continue; end
    try
        idxSort = find((beh.lickRight > tr_start(idxHitsR(n))) ...
                & (beh.lickRight < tr_end(idxHitsR(n)))); 
        hitLicks{n,s} = beh.lickRight(idxSort);
    catch
        hitLicks{n,s} = nan;
    end
end
for n = 1:numel(idxHitsL); s = 2; % left
    if isnan(idxHitsL(n)); hitLicks{n,s} = nan; continue; end
    try
        idxSort = find((beh.lickLeft > tr_start(idxHitsL(n))) ...
                & (beh.lickLeft < tr_end(idxHitsL(n))));
        hitLicks{n,s} = beh.lickLeft(idxSort);
    catch
        hitLicks{n,s} = nan;
    end
end

%% Align licks to events
pethLicks = cell(1,2); 
for s = 1:2
    pethLicks{s} = nan(-1 + length(win(1):bin_peth:win(2)),nHits); % nans
    for n = 1:nHits
        if ~isnan(hitLicks{n,s})
            % extract peri-event histogram, aligning licks to event
            peth = getClusterPETH(hitLicks{n,s}./Fs, firstPoke(idxSide{s})./Fs, bin_peth, win);
            pethLicks{s}(:,n) = peth.cts{1}; % store values
        end
    end
    pethLicks{s}(pethLicks{s} > 1) = 1; % all lick bins set to 1
end

%% Align photometry signals to behavioral event
opts = {'rightHit','leftHit','miss','incorrectAction','abort'};
photo2event = cell(2+length(opts),nFP); % store values, photometry to event

for b = 1:nFP
    signal = comb.FP{b};

    event = firstPoke(idxHits)./Fs; % firstPoke for rewarded trials
    sta = getSTA(signal, event, Fs, win);
    sta_base = getSTA(signal, event, Fs, win_base);
    sta = sta - mean(sta_base,1,'omitnan');
    photo2event{1,b} = sta;

    event = hit./Fs; % reward delivery
    sta = getSTA(signal, event, Fs, win);
    sta_base = getSTA(signal, event, Fs, win_base);
    sta = sta - mean(sta_base,1,'omitnan');
    photo2event{2,b} = sta;
    
    for ii = 1:length(opts)
        j = strcmpi(beh.trial.lastAct, opts{ii});
        if any(j)
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
time_sta = win(1) : 1/Fs : win(2);
lbls = {'pokeRew','reward','soundOnHitR','soundOnHitL','soundOnMiss','soundOnError','soundOnAbort'};
T = cell2table(photo2event.', 'VariableNames', lbls);

%% store
a = 1; 
out = struct;
out(a).mouse = comb.mouse;
out(a).date  = comb.date;
out(a).win   = win;
out(a).evLicks  = pethLicks;
out(a).evPhoto  = T;
out(a).timePeth = peth.time(:);
out(a).timeSta  = time_sta(:);
out(a).rewLat   = rewLatency(:);
out(a).idxSide  = {idxHitsR, idxHitsL};
out(a).lblSide  = {'right','left'};
out(a).lblPhoto = comb.FPnames; 


