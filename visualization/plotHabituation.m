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
    [uni,~,idxMap] = unique({comb.mouse});
    choice = menu('Select mouse to analyze',uni);
    match = find(strcmp({comb.mouse},uni{choice}));
    sub = comb(match);
else
    sub = comb; % else plot data from all recordings in comb
end

%%
fig = figure; theme(fig,'light');
spX = 2; spY = 3;

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
fprintf('%s \n',str);

%% (2-3) lick vector to reward
spNum = 2;

bin = 0.1; % bin width, in seconds
win = [-1 1]; % window, in seconds
lickHit = cell(length(sub),2); % initialize cell array
lbl = {'lick right','lick left'}; % labels for plotting
for a = 1:length(sub)
    beh = sub(a).beh; Fs = 1;
    pethR = getClusterPETH (beh.lickRight./Fs, beh.hits./Fs, bin, win);
    pethL = getClusterPETH (beh.lickLeft./Fs,  beh.hits./Fs, bin, win);
    lickHit{a,1} = pethR.cts{1};
    lickHit{a,2} = pethL.cts{1};
end
pethTime = pethR.time; % extract time vector for plotting

sp(spNum) = subplot(spX, spY, spNum); hold on
clr = lines(7); 
b = 1; % lickRight
for a = 1:size(lickHit,1)
    shadederrbar(pethTime, nanmean(lickHit{a,b},2), SEM(lickHit{a,b},2), clr(a,:));
end
xline(0); xlabel('time to reward (s)'); ylim([0 1]); ylabel('licks (Hz)');
title([lbl{b},' - freq to reward']);
legend({sub.date},'Location','northwest');

sp(spNum) = subplot(spX, spY, spNum+1); hold on
clr = lines(7); 
b = 2; % lickLeft
for a = 1:size(lickHit,1)
    shadederrbar(pethTime, nanmean(lickHit{a,b},2), SEM(lickHit{a,b},2), clr(a,:));
end
xline(0); xlabel('time to reward (s)'); ylim([0 1]); ylabel('licks (Hz)');
title([lbl{b},' - freq to reward']);
legend({sub.date},'Location','northwest');

%% (4) time to firstPoke from ledOn
spNum = 4;

hitPoke = nan(length(sub),4); 
hitTime = nan(length(sub),4);
lbl = {'poke','hit'};
for a = 1:length(sub)
    beh = sub(a).beh;
    tmpPoke = beh.trial.firstPoke - beh.trial.ledOn; % first poke from ledOn
    tmpHit  = beh.trial.end - beh.trial.soundOn; % hit time from soundOn
    tLeft = beh.hitT.trial(strcmpi(beh.hitT.side,'left'));
    tRight = beh.hitT.trial(strcmpi(beh.hitT.side,'right'));
    hitPoke(a,1) = mean(tmpPoke(tLeft),1); % mean, left trials
    hitPoke(a,2) = std(tmpPoke(tLeft),[],1)./sqrt(numel(tLeft)); % SEM, left trials
    hitPoke(a,3) = mean(tmpPoke(tRight),1); % mean, right trials
    hitPoke(a,4) = std(tmpPoke(tRight),[],1)./sqrt(numel(tRight)); % SEM, right trials

    hitTime(a,1) = mean(tmpHit(tLeft),1); % mean, left trials
    hitTime(a,2) = std(tmpHit(tLeft),[],1)./sqrt(numel(tLeft)); % SEM, left trials
    hitTime(a,3) = mean(tmpHit(tRight),1); % mean, right trials
    hitTime(a,4) = std(tmpHit(tRight),[],1)./sqrt(numel(tRight)); % SEM, right trials
end

sp(spNum) = subplot(spX, spY, spNum); hold on
clr = orderedcolors('gem'); % default colors
errorbar(1:length(sub), hitPoke(:,1), hitPoke(:,2),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(2,:),'Color',clr(2,:),'LineStyle','none');
errorbar(1:length(sub), hitPoke(:,3), hitPoke(:,4),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(1,:),'Color',clr(1,:),'LineStyle','none');
xlim([0.5 0.5+length(sub)]); xticks(1:length(sub));
xlabel('recording date'); xticklabels({sub.date});  
ylabel('time from LED-on (s)'); 
sp(spNum).YLim(1) = 0; % y-axis to start at 0 seconds
legend({'left','right'},'Location','northeast');
str = 'firstPoke:';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %.1fs.', a, hitPoke(a,1))];
end
title(str);

%% (5) time to hit from soundOn
spNum = 5;

sp(spNum) = subplot(spX, spY, spNum); hold on
errorbar(1:length(sub), hitTime(:,1), hitTime(:,2),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(2,:),'Color',clr(2,:),'LineStyle','none');
errorbar(1:length(sub), hitTime(:,3), hitTime(:,4),...
    '-o','MarkerSize',10,'MarkerFaceColor',clr(1,:),'Color',clr(1,:),'LineStyle','none');
xlim([0.5 0.5+length(sub)]); xticks(1:length(sub));
xlabel('recording date'); xticklabels({sub.date});  
ylabel('time from sound-on (s)'); yl = ylim; ylim([0 ceil(yl(2))]);
sp(spNum).YLim(1) = 0; % y-axis to start at 0 seconds
legend({'left','right'},'Location','southwest');
str = 'hitTime:';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %.1fs.', a, hitTime(a,1))];
end
title(str);

%% (5) timing of rewards
% spNum = 5;
% barY = nan(length(sub),2); % preallocate matrix
% for a = 1:length(sub)
%     beh = sub(a).beh; 
%     barY(a,1) = beh.hits(1); % time to 1st reward in samples
%     barY(a,2) = beh.hits(end); % time to last reward
% end
% sp(spNum) = subplot(spX, spY, spNum);
% b = bar(barY); % plot bar graph
% for a = 1:length(b)
%     b(a).Labels = round(b(a).YData);
% end
% xlabel('recording date'); xticklabels({sub.date});  
% ylabel('time to reward (s)');
% legend({'1st reward','last reward'});
% str = 'time to 1st:';
% for a = 1:length(sub)
%     str = [str,sprintf(' (%d) %d s = %.1f min.',...
%         a, round(barY(a,1)), barY(a,1)/60)];
% end
% title(str);

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
str = 'mean IRI:';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %ds.', a, round(iriMean(a)))];
end
title(str);