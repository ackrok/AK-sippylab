%% For photometry recordings with drug injections
%
% (1) comb = extractComb_raw; 
%
% (2) open checkTrend
%
%       - confirm most accurate de-trending
%       - dff stored as matrix in comb(a).dff;
%
% (3) run this script to plot and compare
%
% Written by Anya Krok, March 2026
%
%%
% EXTRACT DATA from 'comb' structure
%   creates 'yPlot' cell array with dimensions:
%       j = nDrug
%       k = nFPchan
%       within each cell, matrix with dimensions: nSamples x nMouse
% 
drug = {'saline','KET 30'}; % CHANGE
injT = 600;  % CHANGE -- injection time, in seconds
yunit = 2;   % CHANGE -- (1) raw, (2) dF/F, (3) z-score
%
nFPchan = 2; nDrug = length(drug);
yPlot = cell(nDrug, nFPchan); % output -- columns are FPchan, row are Drug
Fs = mode([comb.Fs]);
cut2 = 34 * (60*Fs); % cut to 34 min
%
uni = unique({comb.mouse}); nMouse = length(uni); % unique mouse IDs
for m = 1:nMouse                   
    match = find(strcmp({comb.mouse}, uni{m})); % rows per mouse
    for j = 1:nDrug, a = match(j);
        Fs = comb(a).Fs;
        for k = 1:nFPchan          
            keep = comb(a).dff(:, k); % ** CHANGE **
            keep = keep(1:cut2); % trim
            yPlot{j, k}(:, m) = keep;
        end
    end
end
time = makeTime(numel(keep), Fs);
time = time - injT; 
[~,idx0] = min(abs(time));
%
% variables for plotting:
xadj = 60; % time-scale, if sec (adj = 1), if min (adj = 60)
sm = 1;   % smoothing window, in samples
ds = 10;   % downsample factor to reduce plot points
ds = 1:ds:numel(time);
clr = {'k','r'};
suffix = {'(sec)','(min)'}; xlbl = ['time ', suffix{[1,60]==xadj}];
suffix = {'(raw)','(dF/F)','(z)'}; ylbl = ['photometry ', suffix{yunit}];


%% (2) 
% PLOT subplots for each mouse, comparing processed photometry signal after saline or drug
%
k = 2;  % CHANGE -- green or red signal
fig = figure; theme(fig,'light');
for m = 1:nMouse
    subplot(2,3,m); hold on; 
    drawnow;
    for j = 1:nDrug
        vec = yPlot{j, k} (:,m); % cell array column FPchan, row drug
        assert(isnumeric(vec));
        plot(time(ds)./xadj, movmean(vec(ds), sm), clr{j}); 
        drawnow;
    end
    shadedband([0 1],ylim);
    xlabel(xlbl); ylabel(ylbl);
    legend(drug);
    title(sprintf('%s - %s NAcSh', uni{m}, comb(1).FPnames{k}));
    grid on
end
%
% any minor changes to plot go here
for m = 1:length(uni), subplot(2,3,m);
    ylim([-0.4 1]); xlim([-5 25]);
end

%% (3)
% PLOT MEAN
yPlotmu = cellfun(@(x) mean(x,2,'omitnan'), yPlot, 'UniformOutput', false);
yPlotstd = cellfun(@(x) std(x,[],2,'omitnan'), yPlot, 'UniformOutput', false);

fig = figure; theme(fig,'light');
tiledlayout(1,nFPchan, 'Padding','compact', 'TileSpacing','compact');
for k = 1:nFPchan
    nexttile(k);
    for j = 1:nDrug
        mu = yPlotmu{j,k}(:);     % extract from cell array
        sigma = yPlotstd{j,k}(:); % extract from cell array
        shadederrbar(time(ds)./xadj, ...
            mu(ds), sigma(ds), clr{j});
    end
    shadedband([0 1],ylim); xlim([-5 25]);
    xlabel(xlbl); ylabel(ylbl);
    legend(drug);
    title(sprintf('%s (n = %d)',comb(1).FPnames{k}, nMouse));
    grid on;
end

%% (4)
% Subtract DRUG from SALINE and plot
sigDiff = cell(1,nFPchan);

for k = 1:nFPchan
    for m = 1:nMouse
        mat = [];
        j = 1; mat(:,j) = yPlot{j,k}(:,m);
        j = 2; mat(:,j) = yPlot{j,k}(:,m);
        sigDiff{k}(:,m) = diff(mat,1,2); % subtract
    end
    mat = sigDiff{k};
    mat = mat - mean(mat(1:injT*Fs,:),1); % subtract baseline mean
    sigDiff{k} = mat;
end

fig = figure; theme(fig,'light');
tiledlayout(1,nFPchan, 'Padding','compact', 'TileSpacing','compact');
for k = 1:nFPchan
    nexttile(k); hold on
    mat = sigDiff{k}; 
    mu = mean(sigDiff{k},2,'omitnan');
    mu = mu(ds); mu = movmean(mu, 1*Fs); 
    sem = SEM(sigDiff{k},2);
    sem = sem(ds); sem = movmean(sem, 5*Fs);
    shadederrbar(time(ds)./xadj, mu, sem, 'b');
    shadedband([0 1],[-0.2 0.5]);
    xlabel('time (min)'); xlim([-10 15]);
    ylabel('signal difference (dF/F)'); ylim([-0.1 0.15]);
    title(sprintf('%s: %s minus %s (n = %d)',...
        comb(a).FPnames{k}, drug{2}, drug{1}, nMouse));
    grid on
end

