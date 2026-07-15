function [ax, fig, out] = plotHabGo(comb)
% Plot behavioral performance analysis for Go-NoGo task.
%
% Syntax:
%   [ax, fig, out] = plotHabGo(comb);
%
% Input:
%   'comb' - structure that includes behavioral data as comb.beh
%       using extract functions, eg:
%           comb = extractComb; 
%           comb = extractComb_beh; 
% 
% Outputs:
%   Generates figure with 6 subplots, plotting data for each recording.
%   Also text output with percentage of hits and d' for each recording.
%
%   Optional additonal ouputs:
%       'ax'  - figure axes
%       'fig' - figure handle
%       'out' - output data, from analyzeBeh_Go function
%
% Written by Anya Krok, June 2026
% Adapted from plotHabituationfor 2AFC task

out = analyzeBeh_Go(comb);
nGroup = size(out.date,1);

tic

%%
str = sprintf('\n%s performance (#hits/#trials)\n', out.mouse);
outcome = table2array(out.outcome);
nHit   = sum(outcome(:,1), 2);
nTr    = sum(outcome(:,1:4), 2);
dprime = out.dprime;
catchWrong = out.catchWrong;

lines = arrayfun(@(a) sprintf(...
    '\n  (%d) %s: hit rate = %d/%d (%d%%). d\" = %1.2f. catchNo = %1.2f. end at %d min.\n', ...
    a, out.date{a}, nHit(a), nTr(a), round(100*nHit(a)/nTr(a)), ...
    dprime(a), catchWrong(a), round(out.endTime(a)) ), ...
    (1:nGroup).', 'UniformOutput', false);

str = [str, strcat(lines{:})];
fprintf('%s\n \n', str);

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
nHit = sum(outcome(:,1), 2);
nTr  = sum(outcome, 2);
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
str = sprintf('last rew at (min):\n');
parts = compose(' (%d) %d.', (1:nGroup).', round(rewTime(:,2)));
str = [str, char(strjoin(parts, ''))];
title(str);

%% (4) time to hit from tone
p = 4;

event = table2cell(out.event);
a = 1; % hit
toneH_mu = cellfun(@(x) mean(x(:)), event(:,a));
toneH_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));
a = 3; % catchHit
toneCH_mu = cellfun(@(x) mean(x(:)), event(:,a));
toneCH_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));
a = 2; % miss
toneM_mu = cellfun(@(x) mean(x(:)), event(:,a));
toneM_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));
a = 4; % catchMiss
toneCM_mu = cellfun(@(x) mean(x(:)), event(:,a));
toneCM_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));


ax(p) = subplot(spX, spY, p); hold on
errorbar(1:nGroup, toneH_mu, toneH_sem,...
    '-o', 'MarkerSize',10, 'LineStyle','none', ...
    'MarkerFaceColor',clr(1,:), 'Color',clr(1,:), 'DisplayName', 'hit');
errorbar(1:nGroup, toneCH_mu, toneCH_sem,...
    '-o', 'MarkerSize',10, 'LineStyle','none', ...
    'MarkerFaceColor',clr(6,:), 'Color',clr(6,:), 'DisplayName', 'catchHit');
errorbar(1:nGroup, toneM_mu, toneM_sem, ...
    '-o', 'MarkerSize',10, 'LineStyle','none', ...
    'MarkerFaceColor',clr(2,:), 'Color',clr(2,:), 'DisplayName', 'miss');
errorbar(1:nGroup, toneCM_mu, toneCM_sem, ...
    '-o', 'MarkerSize',10, 'LineStyle','none', ...
    'MarkerFaceColor',clr(4,:), 'Color',clr(4,:), 'DisplayName', 'catchMiss');

xlim([0.5 0.5+nGroup]); xticks(1:nGroup);
xlabel('recording date'); xticklabels(out.date);  
ylabel('time from tone to event (s)');
ax(p).YLim(1) = 0; % y-axis to start at 0 seconds
legend; legend('Location','southwest');
str = sprintf('tone to event (s):\n');
parts = compose(' (%d) %.1f.', (1:nGroup).', toneH_mu(:));
str = [str, char(strjoin(parts, ''))];
title(str);

%% (5) inter-reward intervals
p = 5;
ax(p) = subplot(spX, spY, p); hold on

iri = out.iri;
iri_mu = cellfun(@mean, iri);
% iri_sem = cellfun(@std, iri)./sqrt(cellfun(@length, iri));
% iri_min = cellfun(@min, iri);

nDate = length(out.date);
slope = nan(nDate,1);
for k = 1:nDate
    x = comb(k).beh.hit.end(:);
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
ylabel([lbl,' (s)']); yl = ylim; ylim([-5, yl(2)]);
legend('Location','northwest');

% errorbar(1:nGroup, iri_mu, iri_sem,...
%     '-o','MarkerSize',10,'MarkerFaceColor',clr(5,:),'Color',clr(5,:),'LineStyle','none');
% plot(1:nGroup, iri_min, '*k', 'MarkerSize', 10);
% legend({'mean','min'},'location','southwest');
% xlim([0.5 0.5+nGroup]); xticks(1:nGroup);
% xlabel('recording date'); xticklabels(out.date);  
% ylabel('inter-reward interval (s)'); 
% ax(p).YLim(1) = 0; % y-axis to start at 0 seconds
str = sprintf('mean IRI (s):\n');
parts = compose(' (%d) %.1f.', (1:nGroup).', iri_mu(:));
str = [str, char(strjoin(parts,''))];
title(str);

toc
fprintf('\n');
