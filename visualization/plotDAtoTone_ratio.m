%%
% October 2026
% 
% Cohort 3C: PFC DA + DMS DA
% Analysis: tone-evoked and lick-evoked DA signal

lbl = {'hit','miss','FA','CR'};

% b = 1; % PFC DA
b = 2; % DMS DA

mu = nan(length(comb), length(lbl)); 
sig = mu;
for a = 1:length(comb)
    beh = comb(a).beh;
    fp  = comb(a).FP{b}; fpLbl = comb(a).FPnames{b};
    Fs  = comb(a).Fs;

    toneGoHit  = beh.hit.tone - 0.75;
    toneGoMiss = beh.miss.tone - 0.75;
    toneNoFA   = beh.falseAlarm.tone - 0.75;
    toneNoCR   = beh.corrReject.tone - 0.75;
    ev = {toneGoHit, toneGoMiss, toneNoFA, toneNoCR};
    xlbl = 'tone';

    for ii = 1:length(ev)
        [sta, time] = getSTA(fp, ev{ii}, Fs, [0 1]);
        base = getSTA(fp, ev{ii}, Fs, [-1 -0]);
        sta = sta - mean(base, 1, 'omitnan');
        m = max(sta); % maximal signal in [0 1] seconds after event
        mu(a,ii) = mean(m, 2, 'omitnan');
        sig(a,ii) = SEM(m, 2);
    end
end

fig = figure; theme(fig, 'light');
subplot(1,2,1); hold on; axis square
    x = [1 2].*ones(size(mu,1),2);
    y = mu(:,1:2);
    e = sig(:,1:2);
    errorbar(x', y', e', 'o-', 'LineWidth', 1, ...
        'Color', 'k', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
    xlim([0.5 2.5]); xticks(1:2); xticklabels({'hit','miss'});
    ylabel('maximum tone-evoked DA'); yticks(0:5:20);
    title('saline (n = 8)');
ax = subplot(1,2,2); hold on; axis square
    y = mu(:,1)./mu(:,2); % ratio
    violinplot(ax, y);
    swarmchart(ones(numel(y),1), y, 36, 'k', 'filled');
    yline(0,'--k');
    ylabel('ratio of tone-evoked DA'); yticks(0:5);
    xlim([0 2]); xticks(1); xticklabels({'hit/miss'});
    [~,p] = ttest(y);
    title(sprintf('p = %.4f',p));
