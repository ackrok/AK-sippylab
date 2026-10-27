function out = analyzeBehDrug(comb)
% Description:
% Extract behavior performance from data structure for Go/No-Go auditory
% discrimination task, for sessions with drug injections. 
% Breaking down recording session into 5 min time bins, for comparison of 
% performance during baseline pre-drug and post-drug injection periods.
% 
% [out] = analyzeBehDrug(comb)
%
% Anya Krok, October 2026

%% variables
binSec = 5 * 60;  % 5 min time bins
recDur = 60 * 60; % limit to 60 minutes of recording session
nComb = numel(comb);  % number of sessions
edges = 0:binSec:recDur;
nBins = numel(edges) - 1;

%%
lickProbBin = nan(nBins, nComb); % preallocate variables
rateHitBin  = nan(nBins, nComb); 
rateFABin   = nan(nBins, nComb); 

%%
for a = 1:nComb
    beh = comb(a).beh;
    lickProbBin(:, a) = histcounts(beh.lick, edges).' / binSec;
    rateHitBin(:, a) = eventRatePerBin(beh.hit.end, beh.miss.end, edges);
    rateFABin(:, a)  = eventRatePerBin(beh.falseAlarm.end, beh.corrReject.end, edges);
end
binMid = (edges(1:end-1) + edges(2:end)) / 2 / 60; % minutes
binMid = binMid(:);

%% 
% Analyze each recording session as baseline, post-drug, and late drug
% periods as specified by injection time
lbl = {'baseline','drug','post-drug'};
injTime = 15;   % injection at 15 min
endTime = 60;   % session limit in minutes
rateHit = nan(nComb, 3);
rateFA  = nan(nComb, 3);
dprime  = nan(nComb, 3);
criterion = nan(nComb, 3);

for a = 1:nComb
    beh = comb(a).beh;
     % Define 3 analysis windows in minutes, then convert to seconds
    win = [0 injTime; ...
        injTime+2 injTime+15; ...
        injTime+30 floor(beh.trial.end(end)/endTime)];
    % win = [0 15; 17 30; 45 floor(beh.trial.end(end) / 60)];
    win = 60 * win;   % convert to seconds

    % Counts per window: [hit, miss, CR, FA]
    outcome = zeros(3, 4);
    for j = 1:3
        t0 = win(j,1);
        t1 = win(j,2);

        outcome(j,1) = sum(beh.hit.tone > t0 & beh.hit.tone < t1);
        outcome(j,2) = sum(beh.miss.tone > t0 & beh.miss.tone < t1);
        outcome(j,3) = sum(beh.corrReject.tone > t0 & beh.corrReject.tone < t1);
        outcome(j,4) = sum(beh.falseAlarm.tone > t0 & beh.falseAlarm.tone < t1);
    end
    H  = outcome(:,1); % hit
    M  = outcome(:,2); % miss
    CR = outcome(:,3); % correct rejection
    FA = outcome(:,4); % false alarm 
    toneGo = H + M;     % go tone
    toneNoGo = CR + FA; % no go tone
    rateHit(a,:) = 100 * H ./ toneGo; % hit rate
    rateFA(a,:)  = 100 * FA ./ toneNoGo; % false alarm rate
    zH = norminv((H + 0.5) ./ (toneGo + 1));
    zFA = norminv((FA + 0.5) ./ (toneNoGo + 1));
    dprime(a,:) = zH - zFA;
    criterion(a,:) = -0.5 * (zH + zFA);
end

%% 
out = struct();
out.drug = '';
out.mouse = {comb.mouse};
out.date  = {comb.date};
out.binMid = binMid;
out.lickProbBin = lickProbBin;
out.rateHitBin = rateHitBin;
out.rateFABin = rateFABin;
out.rateHit = rateHit;
out.rateFA = rateFA;
out.dprime = dprime;
out.criterion = criterion;

end

%%
function rate = eventRatePerBin(numEvents, denEvents, edges)
numCounts = histcounts(numEvents, edges);
denCounts = histcounts(denEvents, edges);

total = numCounts + denCounts;
rate = nan(numel(total), 1);

valid = total > 0;
rate(valid) = 100 * numCounts(valid) ./ total(valid);
end
