% Photometry dynamics and licks recorded from an example mouse during a 
% bandit task session. 
% - For plotting, each row depicts the baselined sensor signal of a trial.
% - t = 0 reflect trial start time as determined by mouse center poke.
% - red dots reflect trial end time, aka final correct lick / "hit".

a = menu('Select data to plot: ',strcat({comb.mouse},'-',{comb.date}));
win = [-1 5];
out = analyzeFP_STA(comb(a), win);

%% PLOT
fig = figure; theme(fig,'light');
win = [-1 5];
% Top row:
% Plot licks aligned to poke (t = 0) with red dot at time of reward
% delivery, for rewarded trials
for s = 1:2
    mat     = out.evLicks{s}; % licks aligned to event for this port
    rewLat  = out.rewLat{s};  % hitLatency only for this port
    rmv     = isnan(mat(1,:));
    mat(:,rmv) = []; rewLat(rmv) = []; % if NaNs in lick matrix, remove from plot
    nSide   = size(mat,2); % number of hits for this port
    [~,idx] = sort(rewLat); % sort by latency for plotting
    
    subplot(2,2,s); hold on
    [X, Y] = meshgrid(out.timePeth, 1:nSide);
    pcolor(X, Y, mat(:,idx)', 'EdgeColor', 'none'); % colorplot
    c = colorbar; c.Label.String = 'licks';
    xline(0,'LineWidth',2,'Color','r'); % xline at 0, representing trial start
    scatter(rewLat(idx), 1:nSide, 10, 'filled', 'r'); % plot hit licks
    xlabel('time to center poke (s), dot is hit'); 
    ylabel(sprintf('trial - %s rewarded',out.lblSide{s})); 
    xlim(win); ylim([0 nSide]); 
    title(sprintf('%s-%s: lick to poke (%s rew)',out.mouse,out.date,out.lblSide{s}));
end

% Bottom row:
% Plot photomtery aligned ot poke (t = 0) with red dot at time of reward
% delivery for all rewarded trials, by photometry signals
for b = 1:length(out.lblPhoto)
    mat = out.evPhoto.pokeRew{b,:}; % photometry to first poke for rewarded trials
    rewLat = vertcat(out.rewLat{:}); % combine all rewarded trials
    rmv     = isnan(mat(1,:));
    mat(:,rmv) = []; rewLat(rmv) = []; % if NaNs in lick matrix, remove from plot
    [~,idx] = sort(rewLat); % sort by latency for plotting
    nHits = length(rewLat); % number of hits

    subplot(2,2,b+2); hold on
    [X, Y] = meshgrid(out.time, 1:nHits);
    pcolor(X, Y, mat(:,idx)', 'EdgeColor', 'none');
    c = colorbar; c.Label.String = '(dF/F)';
    xline(0,'LineWidth',2,'Color','r');
    scatter(rewLat(idx), 1:nHits, 10, 'filled', 'r');
    xlabel('time to center poke (s), dot is hit');
    ylabel('trial - all rewarded');
    xlim(win); ylim([0 nHits]); 
    title(sprintf('%s-%s: %s to poke (all rew)',out.mouse,out.date,out.lblPhoto{b}));
end