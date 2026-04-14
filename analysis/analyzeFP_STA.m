function out = analyzeFP_STA(comb, varargin)
% Analyze photometry signal to align to behavioral events
%
% Syntax:
%   out = analyzeFP_STA(comb);
%   out = analyzeFP_STA(comb, win);
%   out = analyzeFP_STA(comb, win, base);
%
% Inputs:
%   'comb' - structure with data from multiple recordings, created using 
%           function extractComb
%   'win'  - window for photometry alignment, default is [-1 2] seconds
%   'base' - window for baseline, default is [-2 -1]
%
% Outputs:
%   'out' - structure with output variables, including:
%       - out(a).mouse   - mouse ID
%       - out(a).date    - all recording dates
%       - out(a).evPhoto - table with photometry aligned to events
%           - table columns are behavioral events
%           - table rows are different photometry signals (eg, 5-HT, rDA)
%       - out(a).time - time vector for plotting
%
% Note: to extract table headers: opts = T.Properties.VariableNames;
%
% Written by Anne Krok, Dec 2025
% Updated April 2026

% Default inputs
win = [-1 2]; % window, in seconds, for aligning photometry to events
win_base = [-2 -1]; % baseline window, in seconds
switch nargin
    case 2
        win = varargin{1};  % update STA window if provided
    case 3
        win = varargin{1};
        win_base = varargin{2}; % update baseline window if provided
end
bin_peth = 0.05; % bin width, in seconds, for aligning licks to events
out = struct; % initialize output variable

%% Align photometry signals to behavioral event
opts = {'rightHit','leftHit','miss','incorrectAction','abort'};

for a = 1:length(comb)
    Fs  = comb(a).Fs;
    FP  = comb(a).FP;
    nFP = length(FP);
    beh = comb(a).beh;
    out(a).mouse = comb(a).mouse;
    out(a).date  = comb(a).date;
    out(a).nFP   = nFP;
    out(a).lblPhoto = comb(a).FPnames;

%%
% Extract from data structure.
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
% Align photometry signals to behavioral events
%   (1) first center poke for rewarded trials
%   (2) reward delivery
%   (3) sound on right rewarded trials
%   (4) sound on left rewarded trials
%   (5) sound on for all miss trials
%   (6) sound on for all error trials
%   (7) sound on for all abort trials
    photo2event = cell(length(opts)+2, nFP); % initialize temporary variable
    time = win(1) : 1/Fs : win(2);
    for b = 1:nFP
        signal = FP{b}; % signal
        
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
        
        for kk = 1:length(opts)
            ll = strcmpi(beh.trial.lastAct, opts{kk});
            if any(ll)
                event = soundOn(ll)./Fs; % soundOn by outcome
                sta = getSTA(signal, event, Fs, win);
                sta_base = getSTA(signal, event, Fs, win_base);
                sta = sta - mean(sta_base,1,'omitnan');
                photo2event{2+kk,b} = sta;
            else
                photo2event{2+kk,b} = nan(numel(time),1);
            end
        end
    end
    lbls = {'pokeRew','reward','soundOnHitR','soundOnHitL','soundOnMiss','soundOnError','soundOnAbort'};
    T = cell2table(photo2event.', 'VariableNames', lbls);
    out(a).evPhoto = T;
    out(a).time  = time(:);

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
            % compute peri-event histogram (align licks to first poke)
            peth = getClusterPETH(tmpLick./Fs, firstPoke(id)./Fs, bin_peth, win);
            lickRate{s}(:,n) = peth.fr;
        end
        % clamp values and select hits by idxSidebyHit{s}
        lickRate{s}(lickRate{s} > 1) = 1;
        lickRate{s} = lickRate{s}(:, idxSidebyHit{s});
    end
    out(a).evLicks  = lickRate;
    out(a).timePeth = peth.time(:);
    out(a).rewLat   = rewLatency;
    out(a).idxSide  = idxSidebyHit;
    out(a).lblSide  = {'right','left'};
end