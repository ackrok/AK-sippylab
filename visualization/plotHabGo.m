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
nMouse = length(out);

tic

%%
dprime = getdprime(comb);
for a = 1:length(comb)
    beh = comb(a).beh;
    nHit = height(beh.hit);
    nMiss = height(beh.miss);
    nGo = length(find(strcmpi([beh.trial.label], 'goTone')));
    nCR = height(beh.corrReject);
    nFA = height(beh.falseAlarm);
    nNoGo = length(find(strcmpi([beh.trial.label], 'nogoTone')));
    rateHit = round(100*(nHit/nGo));
    rateFA  = round(100*(nFA/nNoGo));

    fprintf(' (%d) %s: hit rate = %d/%d (%d%%). FA rate = %d/%d (%d%%). d\" = %1.2f. \n',...
        a, comb(a).mouse, nHit, nGo, rateHit, nFA, nNoGo, rateFA, dprime(a));
end

%%
fig = figure; theme(fig,'light');
spX = 2; spY = 2;
clr = orderedcolors('gem'); clr = [clr;clr]; % default colors

%% (1) outcome by trial
p = 1;

outcome = table2array(vertcat(out.outcome));
lbl = out(1).outcome.Properties.VariableNames;

ax(p) = subplot(spX, spY, p);
bar(1:nMouse, outcome, 'stacked')
legend(lbl, 'direction','reverse', 'location', 'best');
xticklabels({out.mouse});  
ylabel('# trials'); 
% ax(p).YLim(1) = 0; ax(p).YLim(2) = max(200, ax(p).YLim(2));

str = sprintf('%s - #hits / #trial\n', out(1).date{1});
nHit = sum(outcome(:,1), 2);
nTrGo  = sum(outcome(:,1:2), 2);
parts = compose('(%d)%d/%d. ', (1:nMouse).', nHit, nTrGo);   % string array, one element per group
str = [str, char(strjoin(parts, ''))];
title(str);

%% (2) time to hit from tone
p = 2;

event = table2cell(vertcat(out.event));
lbl = out(1).outcome.Properties.VariableNames;

ax(p) = subplot(spX, spY, p); hold on
for a = [1 4 5]
    tone_mu = cellfun(@(x) mean(x(:)), event(:,a));
    tone_sem = cellfun(@(x) std(x(:)), event(:,a))./sqrt(cellfun(@(x) numel(x(:)), event(:,a)));

    errorbar(1:nMouse, tone_mu, tone_sem,...
        '-o', 'MarkerSize',10, 'LineStyle','none', ...
        'MarkerFaceColor',clr(a,:), 'Color',clr(a,:), 'DisplayName', lbl{a});
end

xlim([0.5 0.5+nMouse]); xticks(1:nMouse); xticklabels({out.mouse}); 
ylabel('time from tone to event (s)');
ax(p).YLim = [0 1.2]; % y-axis to start at 0 seconds
legend('Location','best');
title('time to lick after tone (s)');
% str = sprintf('tone to event (s):\n hit:');
% parts = compose(' (%d) %.1f.', (1:nMouse).', cellfun(@(x) mean(x(:)), event(:,1)));
% str = [str, char(strjoin(parts, ''))];
% title(str);

%% (3) lick vector to reward
p = 3;

% bin = 0.1; % bin width, in seconds
% win = [-1 1]; % window, in seconds
lickHit = table2cell(vertcat(out.lick));
lickTime = out(1).lickTime; % extract time vector for plotting

ax(p) = subplot(spX, spY, p); hold on
for a = 1:nMouse
    plot(lickTime, mean(lickHit{a,1},2,'omitnan'), ... % right
        'Color', clr(a,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s',out(a).mouse));
    % h.Annotation.LegendInformation.IconDisplayStyle = 'off';
end
xline(0,'--k','LineWidth',2); xlabel('time to reward (s)'); 
% h.Annotation.LegendInformation.IconDisplayStyle = 'off';
ylabel('lick frequency (Hz)');
title('lick at reward delivery');
legend('Location','best');

%% (4) timing of rewards
% p = 4;
% 
% rewTime = table2array(out.rewTime);
% lbl = out.rewTime.Properties.VariableNames;
% lbl = regexprep(lbl, '\s*\(.*', '');
% 
% ax(p) = subplot(spX, spY, p);
% b = bar(rewTime); % plot bar graph
% for a = 1:length(b)
%     b(a).Labels = round(b(a).YData);
% end
% xlabel('recording date'); xticklabels(out.date);  
% ylabel('time to reward (min)');
% legend(lbl,'location','west');
% str = sprintf('last rew at (min):\n');
% parts = compose(' (%d) %d.', (1:nMouse).', round(rewTime(:,2)));
% str = [str, char(strjoin(parts, ''))];
% title(str);

%% (5) inter-reward intervals
p = 4;
ax(p) = subplot(spX, spY, p); hold on

iri = vertcat(out.iri);
iri_mu = cellfun(@mean, iri);
% iri_sem = cellfun(@std, iri)./sqrt(cellfun(@length, iri));
% iri_min = cellfun(@min, iri);
 
slope = nan(nMouse,1);
for a = 1:nMouse
    x = comb(a).beh.hit.end(:);
    y = out(a).iri{1}(:); 
    lbl = 'inter-reward interval';
    x = x./60; % convert to minutes
    % h = scatter(x, y, 20, clr(a,:), 'filled', 'MarkerFaceAlpha', 0.6);
    try 
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        mdl = fitlm(x, y);     % linear model
        xs = sort(x);   % sorted x for plotting
        % ys = predict(mdl, xs); % fitted mean values
        [ypred, yci] = predict(mdl, xs, 'Alpha', 0.05); % 95% CI
        h = plot(xs, ypred, '-', 'Color', clr(a,:), 'LineWidth', 1.5);
        % h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        % fill([xs; flipud(xs)], [yci(:,1); flipud(yci(:,2))], ...
        %  0.7*clr(a,:), 'EdgeColor', 'none', 'FaceAlpha', 0.4, ...
        %     'DisplayName',out(a).mouse);
        slope(a) = mdl.Coefficients.Estimate(2); % linear model y = b1 + b2*x
    end
end
xlabel('time (min)'); 
ylabel([lbl,' (s)']); yl = ylim; ylim([0 yl(2)]);
% legend({out.mouse}, 'Location','best');
title('mean IRI');

% errorbar(1:nGroup, iri_mu, iri_sem,...
%     '-o','MarkerSize',10,'MarkerFaceColor',clr(5,:),'Color',clr(5,:),'LineStyle','none');
% plot(1:nGroup, iri_min, '*k', 'MarkerSize', 10);
% legend({'mean','min'},'location','southwest');
% xlim([0.5 0.5+nGroup]); xticks(1:nGroup);
% xlabel('recording date'); xticklabels(out.date);  
% ylabel('inter-reward interval (s)'); 
% ax(p).YLim(1) = 0; % y-axis to start at 0 seconds

% str = sprintf('mean IRI (s):\n');
% parts = compose(' (%d) %.1f.', (1:nMouse).', iri_mu(:));
% str = [str, char(strjoin(parts,''))];
% title(str);

toc
fprintf('\n');
