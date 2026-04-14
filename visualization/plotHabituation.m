function [ax, fig, out] = plotHabituation(comb)
% Plot behavioral performance analysis for 2AFC task.
%
% Syntax:
%   [ax, fig, out] = plotHabituation(comb);
%
% Input:
%   'comb' - structure that includes behavioral data as comb.beh
%       using extract functions, eg:
%           comb = extractComb; 
%           comb = extractComb_beh; 
%       or directly from Bonsai output 'StateTransitions.csv', eg:
%           filename   = dir('*StateTransitions.csv');
%           statetrans = GetBonsai_Pho_StateTransitions_Celeste(filename.name);
%           comb.beh   = extract2AFCdataAK(statetrans);
% 
% Outputs:
%   Generates figure with 6 subplots, plotting data for each recording.
%   Also text output with percentage of hits and d' for each recording.
%
%   Optional additonal ouputs:
%       'ax'  - figure axes
%       'fig' - figure handle
%       'out' - output data, generated with function 'analyzeBeh_2AFC'
%           out = analyzeBeh_2AFC(comb);
%
% Written by Anya Krok, December 2025
% Updated April 2026 to make into function

out = analyzeBeh_2AFC(comb);
nGroup = size(out.date,1);

tic

%%
str = sprintf('\n%s performance (#hits/#trials)\n', out.mouse);
outcome = table2array(out.outcome);
nHit   = sum(outcome(:,1:2), 2);
nTr    = sum(outcome(:,1:4), 2);     % exclude aborted trials
abortN = outcome(:,5);
abortTot = sum(outcome, 2);
abortPer = round(100 * abortN ./ abortTot);
dprime = sqrt(2) .* norminv((nHit + 0.5) ./ (nTr + 1));
bias   = outcome(:,1)./outcome(:,2); % bias = right / left

lines = arrayfun(@(a) sprintf(...
    '\n  (%d) %s: hit rate = %d/%d (%d%%). d\" = %1.2f. bias = %.1f. abort = %d/%d (%d%%). end at %d min.\n', ...
    a, out.date{a}, nHit(a), nTr(a), round(100*nHit(a)/nTr(a)), ...
    dprime(a), bias(a), abortN(a), abortTot(a), abortPer(a), round(out.endTime(a)) ), ...
    (1:nGroup).', 'UniformOutput', false);

str = [str, strcat(lines{:})];
fprintf('%s\n \n', str);

%%
% outcomes separated by which sound presented:
opts = {'righthit','lefthit','miss','incorrectAction','abort'};
fprintf('%s bias soundOnRight / soundOnLeft: \n', out.mouse);
for a = 1:length(comb)
    mat = nan(5,2); 
    last = comb(a).beh.trial.lastAct;
    idxRight = find(strcmpi(comb(a).beh.trial.side,'right'));
    idxLeft = find(strcmpi(comb(a).beh.trial.side,'left'));
    for j = 1:length(opts)
        thisAct = find(strcmpi(last, opts{j}));
        mat(j,1) = numel(intersect(thisAct, idxRight));
        mat(j,2) = numel(intersect(thisAct, idxLeft));
    end
    
    fprintf('  (%d) %s: rightHit (%d). leftHit (%d). miss (%d/%d). error (%d/%d). abort (%d/%d).\n', ...
        a, comb(a).date,...
        mat(1,1), mat(2,2), mat(3,1), mat(3,2), mat(4,1), mat(4,2), mat(5,1), mat(5,2));
end
fprintf('\n');

%%
fig = figure; theme(fig,'light');
spX = 2; spY = 3;
clr = orderedcolors('gem'); % default colors

%% (1) outcome by trial
p = 1;

outcome = table2array(out.outcome);
lbl = out.outcome.Properties.VariableNames;

ax(p) = subplot(spX, spY, p);
bar(1:nGroup, outcome, 'stacked')
legend(lbl, 'direction','reverse', 'location', 'southwest');
xlabel('recording date'); xticklabels(out.date);  
ylabel('# trials'); 
ax(p).YLim(1) = 0; ax(p).YLim(2) = max(200, ax(p).YLim(2));

str = sprintf('%s - total #hits / total #trial\n', out.mouse);
nHit = sum(outcome(:,1:2), 2);
nTr  = sum(outcome, 2);
% nTr = sum(outcome(:,1:4), 2); % exclude aborted trials
parts = compose('(%d)%d/%d. ', (1:nGroup).', nHit, nTr);   % string array, one element per group
str = [str, char(strjoin(parts, ''))];
title(str);

%% (2) lick vector to reward
p = 2;

% bin = 0.1; % bin width, in seconds
% win = [-1 1]; % window, in seconds
lickHit = table2cell(out.lick);
lickTime = out.lickTime; % extract time vector for plotting

ax(p) = subplot(spX, spY, p); hold on
for a = 1:nGroup
    plot(lickTime, mean(lickHit{a,1},2,'omitnan'), ... % right
        'Color', clr(a,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s',out.date{a}));
    h = plot(lickTime, mean(lickHit{a,2},2,'omitnan'), ... % left
        'Color', clr(a,:), 'LineWidth', 1.5, 'LineStyle', '--');
    h.Annotation.LegendInformation.IconDisplayStyle = 'off';
end
h = xline(0); xlabel('time to reward (s)'); 
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
ylabel('licks (Hz)');
title('lick frequency to reward');
legend('Location','northwest');

%% (3) timing of rewards
p = 3;

rewTime = table2array(out.rewTime);
lbl = out.rewTime.Properties.VariableNames;
lbl = regexprep(lbl, '\s*\(.*', '');

ax(p) = subplot(spX, spY, p);
b = bar(rewTime); % plot bar graph
for a = 1:length(b)
    b(a).Labels = round(b(a).YData);
end
xlabel('recording date'); xticklabels(out.date);  
ylabel('time to reward (min)');
legend(lbl,'location','west');
str = 'last rew at (min):';
parts = compose(' (%d) %d.', (1:nGroup).', round(rewTime(:,2)));
str = [str, char(strjoin(parts, ''))];
title(str);

%% (4) time to soundOn from ledOn
p = 4;

event = table2cell(out.event);
a = 1; 
hold_mu = cellfun(@(x) mean(x(:)), event(:,a));
hold_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));

ax(p) = subplot(spX, spY, p); hold on
errorbar(1:nGroup, hold_mu, hold_sem,...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(5,:),'Color',clr(5,:),'LineStyle','none');
xlim([0.5 0.5+nGroup]); xticks(1:nGroup);
xlabel('recording date'); xticklabels(out.date);  
ylabel('time from LED-on (s)');
ax(p).YLim(1) = 0; % y-axis to start at 0 seconds
str = 'ledOn to hold(s):';
parts = compose(' (%d) %.1f.', (1:nGroup).', hold_mu(:));
str = [str, char(strjoin(parts, ''))];
title(str);

%% (5) time to hit from soundOn
p = 5;

a = 2; 
toneR_mu = cellfun(@(x) mean(x(:)), event(:,a));
toneR_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));
a = 3; 
toneL_mu = cellfun(@(x) mean(x(:)), event(:,a));
toneL_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));

ax(p) = subplot(spX, spY, p); hold on
errorbar(1:nGroup, toneR_mu, toneR_sem, ...
    '-o', 'MarkerSize',10, 'LineStyle','none', ...
    'MarkerFaceColor',clr(1,:), 'Color',clr(1,:), 'DisplayName', 'right');
errorbar(1:nGroup, toneL_mu, toneL_sem, ...
    '-o', 'MarkerSize',10, 'LineStyle','none', ...
    'MarkerFaceColor',clr(2,:), 'Color',clr(2,:), 'DisplayName', 'left');
xlim([0.5 0.5+nGroup]); xticks(1:nGroup);
xlabel('recording date'); xticklabels(out.date);  
ylabel('time from sound-on (s)'); yl = ylim; ylim([0 ceil(yl(2))]);
ax(p).YLim(1) = 0; % y-axis to start at 0 seconds
legend; legend('Location','southwest');
str = 'tone to hit(s):';
parts = compose(' (%d)%.1f/%.1f.', (1:nGroup).', toneR_mu(:), toneL_mu(:));
str = [str,char(strjoin(parts, ''))];
title(str);

%% (6) inter-reward intervals
p = 6;
ax(p) = subplot(spX, spY, p); hold on

iri = out.iri;
iri_mu = cellfun(@mean, iri);
% iri_sem = cellfun(@std, iri)./sqrt(cellfun(@length, iri));
% iri_min = cellfun(@min, iri);

nDate = length(out.date);
slope = nan(nDate,1);
for k = 1:nDate
    x = comb(k).beh.hits(:);
    y = out.iri{k}(:); 
    lbl = 'inter-reward interval';
    x = x./60; % convert to minutes
    h = scatter(x, y, 20, clr(k,:), 'filled', 'MarkerFaceAlpha', 0.6);
    h.Annotation.LegendInformation.IconDisplayStyle = 'off';
    mdl = fitlm(x, y);     % linear model
    xs = sort(x);   % sorted x for plotting
    % ys = predict(mdl, xs); % fitted mean values
    [ypred, yci] = predict(mdl, xs, 'Alpha', 0.05); % 95% CI
    h = plot(xs, ypred, '-', 'Color', clr(k,:), 'LineWidth', 1.5);
    h.Annotation.LegendInformation.IconDisplayStyle = 'off';
    fill([xs; flipud(xs)], [yci(:,1); flipud(yci(:,2))], ...
     0.7*clr(k,:), 'EdgeColor', 'none', 'FaceAlpha', 0.4, ...
        'DisplayName',out.date{k});

    slope(k) = mdl.Coefficients.Estimate(2); % linear model y = b1 + b2*x
end
xlabel('time (min)'); 
ylabel([lbl,' (s)']); yl = ylim; ylim([-10, yl(2)]);
legend('Location','northwest');

% errorbar(1:nGroup, iri_mu, iri_sem,...
%     '-o','MarkerSize',10,'MarkerFaceColor',clr(5,:),'Color',clr(5,:),'LineStyle','none');
% plot(1:nGroup, iri_min, '*k', 'MarkerSize', 10);
% legend({'mean','min'},'location','southwest');
% xlim([0.5 0.5+nGroup]); xticks(1:nGroup);
% xlabel('recording date'); xticklabels(out.date);  
% ylabel('inter-reward interval (s)'); 
% ax(p).YLim(1) = 0; % y-axis to start at 0 seconds
str = 'mean IRI(s):';
parts = compose(' (%d) %.1f.', (1:nGroup).', iri_mu(:));
str = [str, char(strjoin(parts,''))];
title(str);

toc
fprintf('\n');
