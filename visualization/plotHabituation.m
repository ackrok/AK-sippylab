%%
if ~exist('comb','var')
    error('ERROR: run extractComb_beh script first to extract behavioral data into structure.');
end

% extract data from .csv files (bonsai output)
tic
filename=dir('*StateTransitions.csv');
statetrans=GetBonsai_Pho_StateTransitions_Celeste(filename.name);

beh = extract2AFCdataAK(statetrans);
toc

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
fig = figure;
spX = 2; spY = 2;

%% (1) outcome by trial
spNum = 1;

barY = nan(length(sub),5); % clear var
barLbl = {'hit R','hit L','miss','noHold','other'};
for a = 1:length(sub) % iterate over all recordings for this unique mouse ID
    beh = sub(a).beh; 

    side = [beh.lastAct.lastLick];
    side = side(beh.lastAct.lastAct == 'Hit');
    barY(a,1) = length(find(side == "LickRight"));
    barY(a,2) = length(find(side == "LickLeft"));

    lastAct = cellstr([beh.lastAct.lastAct]);
    if any(strcmp(cellstr([beh.lastAct.lastAct]),'LeftHit')) || ...
        any(strcmp(cellstr([beh.lastAct.lastAct]),'RightHit'))
        barY(a,1) = numel(find(strcmp(lastAct, 'RightHit')));
        barY(a,2) = numel(find(strcmp(lastAct, 'LeftHit')));
    end
    barY(a,3) = numel(find(strcmp(lastAct, 'Miss')));
    barY(a,4) = numel(find(strcmp(lastAct, 'IncorrectAction')));
    barY(a,5) = length(lastAct) - sum(barY(a,1:4));
end

sp(spNum) = subplot(spX, spY, spNum);
bar(1:length(sub), barY, 'stacked')
legend({'#hits R', '#hits L','#miss', '#error', '#other'}, ...
    'direction','reverse', 'location', 'southwest');
xlabel('recording date'); xticklabels({sub.date});  
ylabel('# trials'); sp(spNum).YLim = [0 255];
str = sprintf('%s - total #hits per #trials \n',sub(1).mouse);
for a = 1:length(sub)
    str = [str,sprintf('(%d) %d/%d.', a, sum(barY(a,1:2)), sum(barY(a,:)))];
end
title(str);

%% (2) lick vector to reward
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
xline(0);
xlabel('time to reward (s)'); ylabel('licks (Hz)');
title([lbl{b},' - frequency to reward']);
legend({sub.date},'Location','northwest');

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
legend({'1st reward','last reward'});
str = 'time to 1st:';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %d s = %.1f min.',...
        a, round(barY(a,1)), barY(a,1)/60)];
end
title(str);

%% (4) inter-reward intervals
spNum = 4;

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
    '-o','MarkerSize',10,'MarkerFaceColor','g','Color','g','LineStyle','none');
plot(1:length(sub), iriMin, '*c', 'MarkerSize', 10);
% plot(1:length(sub), iriMax, '*b', 'MarkerSize', 10);
legend({'mean','min'},'location','northwest');
xlim([0.5 0.5+length(sub)]); xticks(1:length(sub));
xlabel('recording date'); xticklabels({sub.date});  
ylabel('inter-reward interval (s)'); 
sp(spNum).YLim(1) = 0; % y-axis to start at 0 seconds
str = 'mean IRI:';
for a = 1:length(sub)
    str = [str,sprintf(' (%d) %.1f sec.', a, iriMean(a))];
end
title(str);