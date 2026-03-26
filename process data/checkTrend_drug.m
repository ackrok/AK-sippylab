% check on signal
%%
win = 600;
nFPchan = 2;
opts = {'exp2stitch','exp2base','stitch','stretch'};

for b = 1:nFPchan
    fig = figure; theme(fig,'light');
    for a = 1:length(comb)
        signal = comb(a).FP{b}; Fs = comb(a).Fs;
        out = detrendFP_drug(signal, Fs, win);
        [ax, fig] = plotTrend_drug(out);
        ID = [comb(a).mouse,'-',comb(a).date];
        choice = menu(sprintf('Select trend for dF/F: %s',ID),opts);
        chosen = opts{choice};
        dff = getdff_drug(out.y, out.trend.(chosen), Fs, win);
        comb(a).dff(:,b) = dff;
        comb(a).trend{b} = chosen; 
    end
end
