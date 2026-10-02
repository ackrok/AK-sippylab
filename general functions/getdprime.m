function dprime = getdprime(comb)
% Description: extract discriminability index (d') based on auditory
% discrimination task (Go/No-Go) performance.
% 
% dprime = getdprime(comb)
%
% Anya Krok, Oct 2026

if ~isfield(comb,'beh')
    error('no behavioral data present.');
end

dprime = [];
for a = 1:length(comb)
    beh = comb(a).beh;

    nHit = height(beh.hit);
    nMiss = height(beh.miss);
    nGo = length(find(strcmpi([beh.trial.label], 'goTone')));

    nCR = height(beh.corrReject);
    nFA = height(beh.falseAlarm);
    nNoGo = length(find(strcmpi([beh.trial.label], 'nogoTone')));

    zH = norminv((nHit + 0.5) ./ (nGo + 1)); % compute rates with log-linear correction and convert to Z (inverse normal)
    zFA = norminv((nFA + 0.5) ./ (nNoGo + 1)); 
    dprime(a) = zH - zFA; % dprime
end