function out = analyzeBeh_Go(comb)
% Analyze behavioral performance across multiple recordings across multiple
% unique mouse IDs, for Go-NoGo task in Sippy lab.
%
% Syntax:
%   out = analyzeBeh_Go(comb)
%
% Inputs:
% 'comb' - structure with data from multiple recordings, created using 
%           comb = extractComb_beh or extractComb;
%
% Outputs:
% 'out' - structure with behavior performance metrics
%   - out(a).mouse   - mouse ID
%   - out(a).date    - all recording dates
%   - out(a).outcome - trial outcome (hit, miss, error, abort)
%   - out(a).lickHit - licks aligned to reward delivery
%           - default to use bin width 0.1 sec, window [-1 1] sec
%   - out(a).rewTime - time to 1st and last rewarded trial, in minutes
%   - out(a).event   - time to events (ledOn to hold, soundOn to hit)
%   - out(a).iri     - inter-reward intervals, in seconds
%   - out(a).endTime - end of recording, in minutes
%
% Note: to extract table headers, use lbl = T.Properties.VariableNames
%       to extract data, use mat = T{j,k} or cell2mat(T{j,k});
%
% Written by Anya Krok, June 2026
% Adapted from analyzeBeh_2AFC
%

% Initialize output structure
out = struct;

% Input variables
lickBin = 0.1; % bin width for PETH, in seconds
lickWin = [-1 1]; % window for PETH, in seconds

% Extract unique mouse IDs from the input structure
uniMouse = unique({comb.mouse});

% Loop through each unique mouse ID to calculate performance metrics
for j = 1:length(uniMouse)
    % Loop through each recording for each unique mouse ID
    match = find(strcmp({comb.mouse},uniMouse{j}));
    nGroup = length(match);

    % Initiate outcomes variables
    lastOutcome = nan(nGroup, 4);
    lblOutcomes = {'hit','miss','catchHit','catchMiss'};
    lickHit = cell(nGroup, 1);
    lblLickHit = {'lick to hit (Hz)'};
    lickHitTime = [];
    rewTime = nan(length(match),2);
    lblRewTime = {'1st reward (min)','last reward (min)'};
    eventTimes = cell(nGroup, 4);
    lblTimes = {'tone to hit','tone to miss','tone to catchHit','tone to catchMiss'};
    iri = cell(length(match),1);
    endTime = []; 
    dprime = [];

    for a = 1:length(match)
        mouse = comb(match(a)).mouse; % Store to be able to check in case of errors 
        date = comb(match(a)).date; % Store to be able to check in case of errors
        beh = comb(match(a)).beh; % Behavioral data for one recording
        % Adjustment to ensure data is in seconds to match windows for analysis
            % IF data includes behavior and photometry data, then behavior
            % data such as licks is in samples and need to convert to sec
            % so set adj = Fs (sampling frequency).
            % IF data is behavior only, then is already in seconds so will
            % set adj = 1.
            % Detemine based on whether values in lick vector are integers,
            % as if they are all integers then are likely in samples but if
            % are non-integers then are likely all in seconds.
        switch isVecInteger(beh.lick) % Checking lick vector
            case true
                adj = comb(match(a)).Fs; % Sampling frequency
            case false
                adj = 1;  % Data is already in seconds
        end

        % Loop through each trial to first identify outcome
        % Possible outcomes: Hit, Miss, CatchHit, CatchMiss
        lastOutcome(a, 1) = height(beh.hit);  % hit trials
        lastOutcome(a, 2) = height(beh.miss); % miss
        lastOutcome(a, 3) = height(beh.catchHit); % catchHit
        lastOutcome(a, 4) = height(beh.catchMiss); % catchMiss

        % d-prime
        nHit = height(beh.hit);
        nTr = height(beh.trial);
        dprime(a) = sqrt(2) .* norminv((nHit + 0.5) ./ (nTr + 1));    

        % Generate matrix of licks aligned to rewarded Hit trials
        hits = beh.hit.end;
        peth = getClusterPETH(beh.lick./adj, hits./adj, lickBin, lickWin);
        lickHit{a} = peth.cts{1}; % Store lick data for right trials
    
        % Extract timing of 1st and last rewards
        rewTime(a,1) = (hits(1)/adj)/60; % time to 1st reward, in minutes
        rewTime(a,2) = (hits(end)/adj)/60; % time to last reward, in minutes

        % Extract time from tone to outcome
        eventTimes{a,1} = beh.hit.end - beh.hit.tone; % time, in seconds
        eventTimes{a,2} = beh.miss.end - beh.miss.tone;
        eventTimes{a,3} = beh.catchHit.end - beh.catchHit.tone;
        eventTimes{a,4} = beh.catchMiss.end - beh.catchMiss.tone;

        % Inter-reward intervals
        iri{a} = diff(hits./adj); % inter-hit intervals, in seconds
        iri{a} = [hits(1)/adj; iri{a}]; % add delay to 1st reward

        % Last time stamp
        try endTime(a) = beh.trialEnd(end)/60;
        catch endTime(a) = beh.trial.end(end)/60; 
        end
    end
   
    % Load into output structure
    out(j).mouse = uniMouse{j};
    out(j).date  = {comb(match).date}';

    out(j).outcome = array2table(lastOutcome, 'VariableNames', lblOutcomes);
    out(j).dprime  = dprime(:);
    out(j).lick    = cell2table(lickHit, 'VariableNames', lblLickHit);
    out(j).lickTime = peth.time;
    out(j).rewTime = array2table(rewTime, 'VariableNames', lblRewTime);
    out(j).event   = cell2table(eventTimes, 'VariableNames', lblTimes);
    out(j).iri     = iri;
    out(j).endTime = endTime(:);
end