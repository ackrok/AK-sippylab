% check on signal


%% 
for b = 1:2
    fig = figure; theme(fig,'light');
    for a = 1:length(comb)
        win = 600;
        out = detrendFP_drug(comb(a).FP{b}, comb(a).Fs, win);
        subplot(3,4,a); hold on
        plot(out.signal(1:100:end));
        plot(out.trend.exp2stitch(1:100:end),'r','LineWidth',1.5);
        % plot(out.dff(1:100:end)); grid on
        title(sprintf('%s-%s',comb(a).mouse,comb(a).date));
        comb(a).dff(:,b) = out.dff; % add to structure (uses exp2stitch)
    end
end

% % NOTE WEIRD
% 5-HT: a = 3 (exp2base), 8 (??), 9 (exp2stitch), 10 (exp2stitch)
% DA: a = 8 (exp2base)

%% check on weird ones
a = 10;
b = 1;
signal = comb(a).FP{b};
Fs = comb(a).Fs;
win = 600;
out = detrendFP_drug(signal, Fs, win);
plot_trend

%% fix weird
a = 3; b = 1; 

out = detrendFP_drug(comb(a).FP{b}, comb(a).Fs, 600);
detrend = out.y - out.trend.exp2base; % CHANGE WHICH TREND
mask = 1 : out.win*out.Fs;
F0 = mean(detrend(mask));
if F0 <= 1e-3
    offset  = mean(out.y(mask));
    detrend = detrend + offset;
    F0 = F0 + offset;
end
dff = (detrend - F0) ./ F0;
comb(a).dff(:,b) = dff; % add to structure
