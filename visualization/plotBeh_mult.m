%% plotBeh_mult
% Description: compare behavior performance across multiple recordings for an animal.
%
% INPUTS
% 'comb' - combined data structure from extractComb
% 
% OUTPUTS
% 'fig' - generates figures plotting behavioral performance, one figure per
% animal
% 
% Anya Krok, Dec 2025

if ~exist('comb')
    error('ERROR: comb structure does not exist in workspace.');
end

out       = analyzeBeh_2AFC(comb);
choice    = menu('Select mouse to analyze',{out.mouse});
thisMouse = out(choice).mouse;
recs      = out(choice).date;

fig = figure;
spX = 2; spY = 3;
clearvars sp
clr = lines(7); % RGB colors for MATLAB default (parula), for plotting

%% (1) outcome by trial
spNum = 1;

T = out(choice).lastAct; % extract table
barY = table2array(T); % extract matrix with outcomes by trial
lbl  = T.Properties.VariableNames; % extract headers

sp(spNum) = subplot(spX, spY, spNum);
bar(1:length(recs), barY, 'stacked')
legend({'#hits R', '#hits L','#miss', '#error', '#other'}, ...
    'direction','reverse', 'location', 'southwest');
xlabel('recording date'); xticklabels(recs);  
ylabel('# trials'); sp(spNum).YLim = [0 255];
str = sprintf('%s - total hits (per #trials) \n',thisMouse);
for a = 1:size(barY,1)
    str = [str,sprintf(' (%d): %d/%d.', a, sum(barY(a,1:2)), sum(barY(a,:)))];
end
title(str);

%% (2) lick vector to reward
spNum = 2;

T = out(choice).lickHit; % extract table
time = out(choice).lickHit_time; % time vector
lickHit = table2array(T); 
lbl  = T.Properties.VariableNames; % extract headers

sp(spNum) = subplot(spX, spY, spNum); hold on
b = 1; % lickRight
for a = 1:size(lickHit,1)
    shadederrbar(time, nanmean(lickHit{a,b},2), SEM(lickHit{a,b},2), clr(a,:));
end
xline(0);
xlabel('time to reward (s)'); ylabel('licks (Hz)');
title([lbl{b},' - frequency to reward']);
legend(recs,'Location','northwest');

%% (3) timing of rewards
spNum = 3;

T = out(choice).hitTime; % extract table
barY = table2array(T); % extract matrix with outcomes by trial
lbl  = T.Properties.VariableNames; % extract headers
lbl  = cellfun(@(s) strtok(strtrim(s)), lbl, 'UniformOutput', false); % remove second word

sp(spNum) = subplot(spX, spY, spNum);
b = bar(barY); % plot bar graph
for a = 1:length(b)
    b(a).Labels = round(b(a).YData);
end
xlabel('recording date'); xticklabels(recs);  
ylabel('time to reward (s)');
legend(lbl);
str = 'time to 1st:';
for a = 1:size(barY,1)
    str = [str,sprintf(' (%d) %d s = %.1f min.', a, round(barY(a,1)), barY(a,1)/60)];
end
title(str);

%% (4) inter-reward intervals
spNum = 4;

iri = out(choice).iri;
% Calculate the mean and minimum inter-reward intervals for plotting
iriMean = cellfun(@mean, iri);
iriMin = cellfun(@min, iri); iriMax = cellfun(@max, iri);
iriSEM = cellfun(@std,iri)./sqrt(cellfun(@length,iri));

sp(spNum) = subplot(spX, spY, spNum); hold on
errorbar(1:length(recs),iriMean,iriSEM,'-k','LineStyle','none'); % error bar
scatter(1:length(recs), iriMean, 50, lines(length(recs)), 'filled'); % mean of IRIs
plot(1:length(recs), iriMin, '*k', 'MarkerSize', 10); % min of IRIs
% plot(1:length(recs), iriMax, '*k', 'MarkerSize', 10); % max of IRIs
legend({'mean','min'},'location','northwest');
xlim([0.5 0.5+length(recs)]); xticks(1:length(recs));
xlabel('recording date'); xticklabels(recs);  
ylabel('inter-reward interval (s)'); 
ylim(1) = 0; % y-axis to start at 0 seconds
str = 'mean IRI:';
for a = 1:length(recs)
    str = [str,sprintf(' (%d) %.1f sec.', a, iriMean(a))];
end
title(str);

%% (5) inter-reward intervals plotted OVER TIME
spNum = 5;

iri = out(choice).iri;
% m = max(cellfun(@numel, out.iri)); % max # trials

sp(spNum) = subplot(spX, spY, spNum); hold on
for a = 1:size(iri,1)
    scatter(1:length(iri{a}), iri{a}, 'filled', ...
        'MarkerFaceColor', clr(a,:), 'MarkerFaceAlpha', 0.5);
end
legend(recs)
xlabel('trial #'); ylabel('inter-reward interval (s)');
