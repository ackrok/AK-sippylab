%%
% October 2026
% 
% Cohort 3C: PFC DA + DMS DA
% Analysis: tone-evoked and lick-evoked DA signal


fig = figure; theme(fig, 'light');
spM = floor(sqrt(length(comb))); spN = ceil(length(comb)/spM);
clr = {'g','b','r','m'};
lbl = {'hit','miss','FA','CR'};

% b = 1; % PFC DA
b = 2; % DMS DA
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

    % endGoHit  = beh.hit.end - 0.75;
    % endGoMiss = [];
    % endNoFA   = beh.falseAlarm.end - 0.75;
    % endNoCR   = [];
    % ev = {endGoHit, endGoMiss, endNoFA, endNoCR};
    % xlbl = 'last lick';

    sp(a) = subplot(spM, spN, a); hold on; axis square
    for ii = 1:length(ev)
        [sta, time] = getSTA(fp, ev{ii}, Fs, [-1 2]);
        base = getSTA(fp, ev{ii}, Fs, [-2 -1]);
        sta = sta - mean(base, 1, 'omitnan');
        shadederrbar(time, mean(sta, 2, 'omitnan'), SEM(sta, 2), clr{ii});
    end
    legend(lbl,'location','best');
    xlabel(sprintf('time to %s (s)',xlbl));
    xline(0,'--k','LineWidth',2);
    ylabel(sprintf('%s (dF/F)', fpLbl)); 
    title(sprintf('%s: %s', comb(a).mouse, fpLbl), 'Interpreter', 'none');
    hold off;
end
