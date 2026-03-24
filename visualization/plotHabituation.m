%%
if ~exist('comb','var')
    error('ERROR: run extractComb_beh script first to extract behavioral data into structure.');
end

% OR extract data from .csv files (bonsai output)
% tic
% filename=dir('*StateTransitions.csv');
% statetrans=GetBonsai_Pho_StateTransitions_Celeste(filename.name);
% 
% beh = extract2AFCdataAK(statetrans);
% toc

%% number of rewards
if numel(unique({comb.mouse})) ~= 1
    % if structure contains data from multiple unique mouse IDs then
    % extract rows from structure for a unique mouse into sub-structure
    uni    = unique({comb.mouse});
    choice = menu('Select mouse to analyze',uni);
    match  = find(strcmp({comb.mouse},uni{choice}));
    sub    = comb(match);
else
    sub = comb; % else plot data from all recordings in comb
end

%% 
str = sprintf('%s performance (#hits/#trials) \n',sub(1).mouse);
for a = 1:length(sub)
    nHit = numel(sub(a).beh.hits);
    nTr  = height(sub(a).beh.trial) - numel(sub(a).beh.abort); % exclude aborted trials
    str  = [str,sprintf('  (%d) %s: %d/%d = %d%%.\n', a, sub(a).date, nHit, nTr, round(100*nHit/nTr))];
end
fprintf('%s \n',str);

%%
fig = figure; theme(fig,'light');
spX = 2; spY = 3;
clr = orderedcolors('gem'); % default colors

%% (1) outcome by trial
spNum = 1;

barY = nan(length(sub),5); % clear var
barLbl = {'hit R','hit L','miss','noHold','other'};
for a = 1:length(sub) % iterate over all recordings for this unique mouse ID
    beh = sub(a).beh; 
    % a) hits
    barY(a,1) = numel(find(strcmpi(beh.hitT.side,'right')));
    barY(a,2) = numel(find(strcmpi(beh.hitT.side,'left')));
    barY(a,3) = numel(beh.miss);
    barY(a,4) = numel(beh.error);
    barY(a,5) = numel(beh.abort);
end

sp(spNum) = subplot(spX, spY, spNum);
bar(1:length(sub), barY, 'stacked')
legend({'#hits R', '#hits L','#miss', '#error', '#abort'}, ...
    'direction','reverse', 'location', 'southwest');
xlabel('recording date'); xticklabels({sub.date});  
ylabel('# trials'); sp(spNum).YLim = [0 255];
str = sprintf('%s - total #hits per #trials \n',sub(1).mouse);
for a = 1:length(sub)
    nHit = numel(sub(a).beh.hits);
    nTr  = height(sub(a).beh.trial) - numel(sub(a).beh.abort); % exclude aborted trials
    str  = [str,sprintf('(%d)%d/%d=%d.', a, nHit, nTr, round(100*nHit/nTr))];
end
title(str);

%% (2) lick vector to reward
spNum = 2;

bin = 0.1; % bin width, in seconds
win = [-1 1]; % window, in seconds
lickHit = cell(length(sub),2); % initialize cell array
for a = 1:length(sub)
    beh = sub(a).beh; Fs = 1;
    pethR = getClusterPETH (beh.lickRight./Fs, beh.hits./Fs, bin, win);
    pethL = getClusterPETH (beh.lickLeft./Fs,  beh.hits./Fs, bin, win);
    lickHit{a,1} = pethR.cts{1};
    lickHit{a,2} = pethL.cts{1};
end
pethTime = pethR.time; % extract time vector for plotting

sp(spNum) = subplot(spX, spY, spNum); hold on
for a = 1:length(sub)
    plot(pethTime, mean(lickHit{a,1},2,'omitnan'), ... % right
        'Color', clr(a,:), 'LineWidth', 1.5, 'DisplayName', sprintf('%s right',sub(a).date));
    plot(pethTime, mean(lickHit{a,2},2,'omitnan'), ... % left
        'Color', clr(a,:), 'LineWidth', 1.5, 'LineStyle', '--', 'DisplayName', sprintf('%s left',sub(a).date));
end
xline(0,'DisplayName',''); xlabel('time to reward (s)'); 
ylim([0 1]); ylabel('licks (Hz)');
title('lick frequency to reward');
legend('Location','northwest');

%% (3) timing of rewards
spNum = 3;
barY = nan(length(sub),2); % preallocate matrix
for a = 1:length(sub)
    beh = sub(a).beh; 
    barY(a,1) = beh.hits(1); % time to 1st reward in samples
    barY(a,2) = beh.hits(end); % time to last reward
end
sp(spNum) = subplot(spX, spY, spNum);
b = bar(barY); % plot bar graph
for a = 1:length(b)
    b(a).Labels = round(b(a).YData);
end
xlabel('recording date'); xticklabels({sub.date});  
ylabel('time to reward (s)');
legend({'1st reward','last reward'},'location','west');
str = 'last at (min):';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %d.', a, round(barY(a,2)/60))];
end
title(str);

%% (4) time to soundOn from ledOn
spNum = 4;
timeHold = nan(length(sub),2); 
timeHit = nan(length(sub),4);
lbl = {'poke','hit'};
for a = 1:length(sub)
    beh = sub(a).beh;

    tmpHold = beh.trial.soundOn - beh.trial.ledOn; % soundOn - ledOn (time to complete proper hold)
    tmpHit  = beh.trial.end - beh.trial.soundOn; % hit - soundOn (reward latency)

    nTrial  = height(beh.hitT);
    timeHold(a,1) = mean(tmpHold,1); % mean for all trials
    timeHold(a,2) = std(tmpHold,[],1)./sqrt(nTrial); % SEM for all trials

    tLeft = beh.hitT.trial(strcmpi(beh.hitT.side,'left'));
    tRight = beh.hitT.trial(strcmpi(beh.hitT.side,'right'));
    timeHit(a,1) = mean(tmpHit(tLeft),1); % mean, left trials
    timeHit(a,2) = std(tmpHit(tLeft),[],1)./sqrt(numel(tLeft)); % SEM, left trials
    timeHit(a,3) = mean(tmpHit(tRight),1); % mean, right trials
    timeHit(a,4) = std(tmpHit(tRight),[],1)./sqrt(numel(tRight)); % SEM, right trials
end

sp(spNum) = subplot(spX, spY, spNum); hold on
errorbar(1:length(sub), timeHold(:,1), timeHold(:,2),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(5,:),'Color',clr(5,:),'LineStyle','none');
xlim([0.5 0.5+length(sub)]); xticks(1:length(sub));
xlabel('recording date'); xticklabels({sub.date});  
ylabel('time from LED-on (s)');
sp(spNum).YLim(1) = 0; % y-axis to start at 0 seconds
str = 'ledOn to hold(s):';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %.1f.', a, timeHold(a,1))];
end
title(str);

%% (5) time to hit from soundOn
spNum = 5;

sp(spNum) = subplot(spX, spY, spNum); hold on
errorbar(1:length(sub), timeHit(:,1), timeHit(:,2),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(2,:),'Color',clr(2,:),'LineStyle','none');
errorbar(1:length(sub), timeHit(:,3), timeHit(:,4),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(1,:),'Color',clr(1,:),'LineStyle','none');
xlim([0.5 0.5+length(sub)]); xticks(1:length(sub));
xlabel('recording date'); xticklabels({sub.date});  
ylabel('time from sound-on (s)'); yl = ylim; ylim([0 ceil(yl(2))]);
sp(spNum).YLim(1) = 0; % y-axis to start at 0 seconds
legend({'left','right'},'Location','southwest');
str = 'tone to hit(s):';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %.1f.', a, timeHit(a,1))];
end
title(str);

%% (6) inter-reward intervals
spNum = 6;

% histogram(iri{a},'BinWidth',5); xlabel('interval (s)'); ylabel('freq')
iri = cell(length(sub),1);
for a = 1:length(sub)
    beh = sub(a).beh; Fs = 1;
    iri{a} = diff(beh.hits./Fs); % inter-reward intervals in seconds
    iri{a} = [beh.hits(1)/Fs; iri{a}]; % add 1st reward delay
end
% Calculate the mean and minimum inter-reward intervals for plotting
iriMean = cellfun(@mean, iri);
iriMin = cellfun(@min, iri); iriMax = cellfun(@max, iri);
iriSEM = cellfun(@std,iri)./sqrt(cellfun(@length,iri));

sp(spNum) = subplot(spX, spY, spNum); hold on
errorbar(1:length(sub),iriMean,iriSEM,...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(5,:),'Color',clr(5,:),'LineStyle','none');
plot(1:length(sub), iriMin, '*k', 'MarkerSize', 10);
% plot(1:length(sub), iriMax, '*k', 'MarkerSize', 10);
legend({'mean','min'},'location','northwest');
xlim([0.5 0.5+length(sub)]); xticks(1:length(sub));
xlabel('recording date'); xticklabels({sub.date});  
ylabel('inter-reward interval (s)'); 
sp(spNum).YLim(1) = 0; % y-axis to start at 0 seconds
str = 'mean IRI(s):';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %d.', a, round(iriMean(a)))];
end
title(str);