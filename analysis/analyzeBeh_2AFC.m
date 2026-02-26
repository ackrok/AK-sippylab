function out = analyzeBeh_2AFC(comb)
% Analyze behavioral performance across multiple recordings across multiple
% unique mouse IDs, for two-alternate forced choice task in Sippy lab.
%
% out = analyzeBeh_2AFC(comb)
%
% INPUTS
% 'comb' - structure with data from multiple recordings, created using 
%           script "extractComb"
%
% OUTPUTS
% 'out' - structure with behavior performance metrics
%   - out(a).mouse   - mouse ID
%   - out(a).date    - all recording dates
%   - out(a).lastAct - last action taken by mouse for each trial
%   - out(a).lickHit - matrix with licks aligned to each rewarded trial
%           - default to use bin width 0.1 sec, window [-1 1] sec
%   - out(a).hitTime - time to 1st and last rewarded trial, in seconds
%   - out(a).iri     - cell array with inter-reward intervals, in seconds
%
% Note: to extract table headers, use headers = T.Properties.VariableNames
%
% Written by Anne Krok, Dec 2025
%

% Initialize output structure
out = struct;

% Input variables
lickBin = 0.1; % bin width for PETH, in seconds
lickWin = [-1 1]; % window for PETH, in seconds

% Extract unique mouse IDs from the input structure
uniMouse = unique({comb.mouse});

% Loop through each unique mouse ID to calculate performance metrics
for thisMouse = 1:length(uniMouse)
    % Loop through each recording for each unique mouse ID
    match = find(strcmp({comb.mouse},uniMouse{thisMouse}));

    % Initiate outcomes variables
    trialOutcome = nan(length(match),5);
    trialOutcomes = {'hit R','hit L','miss','error','other'};
    lickHit = cell(length(match),2); 
    lickHitLbl = {'lick R','lick L'};
    lickHitTime = [];
    hitTime = nan(length(match),2);
    hitTimeLbl = {'1st reward','last reward'};
    iri = cell(length(match),1);
    endTime = []; 

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
        switch isVecInteger(beh.lickCenter) % Checking lickCenter vector
            case true
                adj = comb(match(a)).Fs; % Sampling frequency
            case false
                adj = 1;  % Data is already in seconds
        end

        % Loop through each trial to first identify outcome
        % Possible outcomes: Hit, with either LickRight or LickLeft being
        % second to last event, also Miss, IncorrectAction (error/noHold)
        try lastAct = [beh.lastAct.lastAct]; % Last action for each trial
            side = [beh.lastAct.lastLick]; % Second to last action for each trial
        catch lastAct = [beh.trial.lastAct]; % Pre or post-Feb 2026 data organization
              side = [beh.trial.lastLick];
        end
        if any(lastAct == 'LeftHit') || any(lastAct == 'RightHit') % 2AFC
            trialOutcome(a, 1) = length(find(lastAct == 'RightHit'));
            trialOutcome(a, 2) = length(find(lastAct == 'LeftHit'));
        else
            side = side(lastAct == 'Hit')); % tone-reward tast
            trialOutcome(a, 1) = length(find(side == "LickRight"));
            trialOutcome(a, 2) = length(find(side == "LickLeft"));
        end
        % counts = countcats(lastAct); % count occurence of categorical array elements by category
        % names = categories(lastAct); % returns possible names for categories
        trialOutcome(a, 3) = length(find(lastAct == 'Miss'));
        trialOutcome(a, 4) = length(find(lastAct == 'IncorrectAction'));
        trialOutcome(a, 5) = length(lastAct) - sum(trialOutcome(a,1:4));
    
        % Generate matrix of licks aligned to rewarded Hit trials
        pethR = getClusterPETH(beh.lickRight./adj, beh.hits./adj, lickBin, lickWin);
        pethL = getClusterPETH(beh.lickLeft./adj,  beh.hits./adj, lickBin, lickWin);
        lickHit{a, 1} = pethR.cts{1}; % Store lick data for right trials
        lickHit{a, 2} = pethL.cts{1};  % Store lick data for left trials
    
        % Extract timing of 1st and last rewards
        hitTime(a,1) = beh.hits(1)/adj; % time to 1st reward, in seconds
        hitTime(a,2) = beh.hits(end)/adj; % time to last reward, in seconds

        % Inter-reward intervals
        iri{a} = diff(beh.hits./adj); % inter-hit intervals, in seconds
        iri{a} = [beh.hits(1)/adj; iri{a}]; % add delay to 1st reward

        % Last time stamp
        try endTime(a) = beh.trialEnd(end);
        catch endTime(a) = beh.trial.end(end); 
        end
    end
   
    % Load into output structure
    out(thisMouse).mouse = uniMouse{thisMouse};
    out(thisMouse).date = {comb(match).date};
    out(thisMouse).lastAct = array2table(trialOutcome, ...
        'VariableNames', trialOutcomes);
    out(thisMouse).lickHit = array2table(lickHit, ...
        'VariableNames', lickHitLbl);
    out(thisMouse).lickHit_time = pethR.time; % Extract time vector from PETH
    out(thisMouse).hitTime = array2table(hitTime, ...
        'VariableNames', hitTimeLbl);
    out(thisMouse).iri = iri;
    out(thisMouse).endTime = endTime;

end
   
end
    
