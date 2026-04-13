function out = analyzeBeh_2AFC(comb)
% Analyze behavioral performance across multiple recordings across multiple
% unique mouse IDs, for two-alternate forced choice task in Sippy lab.
%
% Syntax:
%   out = analyzeBeh_2AFC(comb)
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
% Written by Anya Krok, Dec 2025
% Updated April 2026
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
    lastOutcome = nan(nGroup, 5);
    lblOutcomes = {'hit R','hit L','miss','error','abort'};
    lickHit = cell(nGroup, 2);
    lblLickHit = {'R lick to hit (Hz)','L lick to hit (Hz)'};
    lickHitTime = [];
    rewTime = nan(length(match),2);
    lblRewTime = {'1st reward (min)','last reward (min)'};
    eventTimes = cell(nGroup, 3);
    lblTimes = {'ledOn to hold', 'R tone to hit','L tone to hit'};
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
        switch isVecInteger(beh.pokeCenter) % Checking lickCenter vector
            case true
                adj = comb(match(a)).Fs; % Sampling frequency
            case false
                adj = 1;  % Data is already in seconds
        end

        % Loop through each trial to first identify outcome
        % Possible outcomes: Hit, with either LickRight or LickLeft being
        % second to last event, also Miss, IncorrectAction (error/noHold)
        lastOutcome(a, 1) = numel(find(strcmpi(beh.hitT.side,'right'))); % right HIT
        lastOutcome(a, 2) = numel(find(strcmpi(beh.hitT.side,'left')));  % left HIT
        lastOutcome(a, 3) = numel(beh.miss);  % miss
        lastOutcome(a, 4) = numel(beh.error); % incorrect action
        lastOutcome(a, 5) = numel(beh.abort);  % abort hold

        % d-prime
        nHit = numel(beh.hits);
        nTr  = height(beh.trial) - numel(beh.abort); % exclude aborted trials
        dprime(a) = sqrt(2) .* norminv((nHit + 0.5) ./ (nTr + 1));    

        % Generate matrix of licks aligned to rewarded Hit trials
        hitR = beh.hitT.hits(strcmpi(beh.hitT.side,'right'));
        hitL = beh.hitT.hits(strcmpi(beh.hitT.side,'left'));
        pethR = getClusterPETH(beh.lickRight./adj, hitR./adj, lickBin, lickWin);
        pethL = getClusterPETH(beh.lickLeft./adj,  hitL./adj, lickBin, lickWin);
        lickHit{a, 1} = pethR.cts{1}; % Store lick data for right trials
        lickHit{a, 2} = pethL.cts{1};  % Store lick data for left trials
    
        % Extract timing of 1st and last rewards
        rewTime(a,1) = (beh.hits(1)/adj)/60; % time to 1st reward, in minutes
        rewTime(a,2) = (beh.hits(end)/adj)/60; % time to last reward, in minutes

        % Extract time to sound On from led On
        % Corresponds to time until mouse completes hold.
        trialR = strcmpi(beh.trial.side,'right');
        trialL = strcmpi(beh.trial.side,'left');
        eventTimes{a,1} = beh.trial.soundOn - beh.trial.ledOn;
        tmpHit = beh.trial.end - beh.trial.soundOn;
        eventTimes{a,2} = tmpHit(trialR); 
        eventTimes{a,3} = tmpHit(trialL);

        % Inter-reward intervals
        iri{a} = diff(beh.hits./adj); % inter-hit intervals, in seconds
        iri{a} = [beh.hits(1)/adj; iri{a}]; % add delay to 1st reward

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
    out(j).lickTime = pethR.time;
    out(j).rewTime = array2table(rewTime, 'VariableNames', lblRewTime);
    out(j).event   = cell2table(eventTimes, 'VariableNames', lblTimes);
    out(j).iri     = iri;
    out(j).endTime = endTime(:);
end