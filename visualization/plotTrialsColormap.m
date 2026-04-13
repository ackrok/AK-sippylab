% Photometry dynamics and licks recorded from an example mouse during a 
% bandit task session. 
% - For plotting, each row depicts the baselined sensor signal of a trial.
% - t = 0 reflect trial start time as determined by mouse center poke.
% - red dots reflect trial end time, aka final correct lick / "hit".

if ~exist('out','var') || exist('out','var') && ~isfield(out,'evLicks')
    a = 1;
    win = [-1 5];
    out = analyzeTrialExample(comb(a), win);
end

%% Plot licks to behavioral event
figure; 
for s = 1:2
    try
        mat     = out.evLicks{s}; % licks aligned to event for this port
        nSide   = length(out.idxSide{s}); % number of hits at this port
        rewLat  = out.rewLat(out.idxSide{s}); % hitLatency only for this port
        [~,idx] = sort(rewLat); % sort by latency
        
        subplot(2,2,s); hold on
        [X, Y] = meshgrid(out.timePeth, 1:nSide);
        pcolor(X, Y, mat(:,idx)', 'EdgeColor', 'none'); % colorplot
        c = colorbar; c.Label.String = 'licks';
        xline(0,'LineWidth',2); % xline at 0, representing trial start
        scatter(rewLat(idx), 1:nSide, 10, 'filled', 'r'); % plot hit licks
        ylabel('trial (#)'); ylim([0 nSide]); xlim(out.win);
        title([out.lblSide{s},' - rewarded']);
    catch
        fprintf('Unable to plot %s. \n', out.lblSide{s});
        delete(subplot(2,2,s));
    end
    mat     = out.evLicks{s}; % licks aligned to event for this port
    nSide   = length(out.idxSide{s}); % number of hits at this port
    rewLat  = out.rewLat(out.idxSide{s}); % hitLatency only for this port
    [~,idx] = sort(rewLat); % sort by latency
    if nSide == 0; continue; end % exit loop if no data
    
    subplot(2,2,s); hold on
    [X, Y] = meshgrid(out.timePeth, 1:nSide);
    pcolor(X, Y, mat(:,idx)', 'EdgeColor', 'none'); % colorplot
    c = colorbar; c.Label.String = 'licks';
    xline(0,'LineWidth',2); % xline at 0, representing trial start
    scatter(rewLat(idx), 1:nSide, 10, 'filled', 'r'); % plot hit licks
    ylabel('trial (#)'); ylim([0 nSide]); xlim(out.win);
    title([out.lblSide{s},' - rewarded']);
end

%% Plot photometry signals to behavioral event
rewLat = out.rewLat; % latency to hit for all rewarded trials
[~,idx] = sort(rewLat); % sort by latency for all rewarded trials
nHits = length(out.rewLat); % number of hits
for b = 1:2
    mat = out.evPhoto.pokeRew(b); % photometry to first poke for rewarded trials

    subplot(2,2,b+2); hold on
    [X, Y] = meshgrid(out.timeSta, 1:nHits);
    pcolor(X, Y, mat(:,idx)', 'EdgeColor', 'none');
    c = colorbar; c.Label.String = '(dF/F)';
    xline(0,'LineWidth',2);
    scatter(rewLat(idx), 1:nHits, 10, 'filled', 'r');
    ylabel('trial (#)'); ylim([0 nHits]); xlim(out.win);
    xlabel('time to center poke (s)'); 
    title(sprintf('%s-%s: %s',out.mouse,out.date,out.lblPhoto{b}));
end