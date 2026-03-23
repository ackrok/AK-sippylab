%% 
% Plot ONE figure with 5-HT and DA signals on two different subplots,
% comparing saline and ketamine for ONE animal
x = 6;

uni = unique({comb.mouse}); % unique mouse ID
match = find(strcmp({comb.mouse}, uni{x})); % rows for this mouse
sub = comb(match); % sub-structure
figure;
clr = {'c','r'}; 
for b = 1:2 % two photometry signals
    subplot(2,1,b); hold on
        for a = 1:2 % saline/ketamine
            plot(sub(a).FP{b}, clr{a});
        end
        xline(600*sub(a).Fs,'LineWidth',3);
        xlabel('samples');
        ylabel('raw photometry');
        legend({'SAL','KET'})
        title([sub(a).mouse,'-',sub(a).FPnames{b}]);
end

%%
comb = extractComb_raw;

%% (1) 
% EXTRACT DATA
yunit = 2;   % CHANGE -- (1) raw, (2) dF/F, (3) z-score
drug = {'saline','KET 30'}; % CHANGE
injT = 600;  % CHANGE -- injection time, in seconds
%
nFPchan = 2; nDrug = length(drug);
yPlot = cell(nDrug, nFPchan); % output -- columns are FPchan, row are Drug
% lens = arrayfun(@(s) numel(s.FP{1}), comb); % lengths of samples
Fs = mode([comb.Fs]);
cut2 = 34 * (60*Fs); % 34 minute long recording
cut1 = 1; % cut1 = 5 * (60*Fs); injT = injT - (cut1/Fs);
%
time = makeTime(numel(signal), Fs);
time = time - injT; [~,idx0] = min(abs(time));
%
uni = unique({comb.mouse}); nMouse = length(uni); % unique mouse IDs
for m = 1:nMouse                   % for this mouse
    match = find(strcmp({comb.mouse}, uni{m})); % rows per mouse
    for c = 1:nDrug, a = match(c); % for this drug
        Fs = comb(a).Fs;
        for b = 1:nFPchan          % for this photometry channel
            signal = comb(a).FP{b};
            signal = signal(cut1:cut2);
            [sigdff, sigZ] = dFF_drug(signal, Fs, injT);
            switch yunit
                case 1, keep = signal; % raw signal
                case 2, keep = sigdff; % dF/F
                case 3, keep = sigZ;   % z-score
            end
            yPlot{c, b}(:,m) = keep;
        end
    end
end
time = makeTime(numel(signal), Fs);
time = time - injT; 
[~,idx0] = min(abs(time));
%
% variables for plotting:
xadj = 60; % time-scale, if sec (adj = 1), if min (adj = 60)
sm = 1;   % smoothing window, in samples
ds = 10;   % downsample factor to reduce plot points
clr = {'k','r'};
suffix = {'(sec)','(min)'}; xlbl = ['time ', suffix{[1,60]==xadj}];
suffix = {'(raw)','(dF/F)','(z)'}; ylbl = ['photometry ', suffix{yunit}];

%% (2) 
% PLOT subplots for each mouse, comparing processed photometry signal after saline or drug
%
b = 2;  % CHANGE -- green or red signal
fig = figure; theme(fig,'light');
for m = 1:nMouse
    subplot(2,3,m); hold on; 
    drawnow;
    for c = 1:nDrug
        vec = yPlot{c, b} (:,m); % cell array column FPchan, row drug
        assert(isnumeric(vec));
        plot(time(1:ds:end)./xadj, movmean(vec(1:ds:end), sm), clr{c}); 
        drawnow;
    end
    shadedband([0 1],ylim);
    xlabel(xlbl); ylabel(ylbl);
    legend(drug);
    title(sprintf('%s - %s NAcSh', uni{m}, comb(1).FPnames{b}));
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
for b = 1:nFPchan
    nexttile(b);
    for ii = 1:nDrug
        mu = yPlotmu{ii,b}(:); sigma = yPlotstd{ii,b}(:); % extract from cell array
        shadederrbar(time(1:ds:end)./xadj, ...
            mu(1:ds:end), sigma(1:ds:end), clr{ii});
    end
    shadedband([0 1],ylim); xlim([-5 25]);
    xlabel(xlbl); ylabel(ylbl);
    legend(drug);
    title(sprintf('%s (n = %d)',comb(1).FPnames{b}, nMouse));
    grid on;
end

%% OLD VARIANTS
% % IF Bottom 5th percentile of signal
% interpType = 'linear'; % 'linear' 'spline' 
% fitType = 'interp';  % Fit method 'interp' , 'exp' , 'line'
% basePrc = 25; % Percentile value from 1 - 100 to use when finding baseline
% winSize = 10; % Window size for baselining in seconds
% winOv = 0; %Window overlap size in seconds
% [~, bottom] = baselineFP (signal,interpType,fitType,basePrc,winSize,winOv,Fs);
% bottomSm = movmean(bottom, sm*Fs);
% plot(time./adj, bottomSm, clr{c}, 'LineWidth',1); ylabel('photometry (z)');