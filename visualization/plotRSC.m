%
% comb = extractComb_raw;
%
%% compute dFF and z-score
win = 600;
nFPchan = 1;
for b = 1:nFPchan
    for a = 1:length(comb)
        signal = comb(a).FP{b}; Fs = comb(a).Fs;
        out = detrend_drug(signal, Fs, win);
        % ran checkTrend_drug and all use exp2stitch trend
        comb(a).dff = out.dff; 
        comb(a).z = out.z;
    end
end

%%
fig = figure; theme(fig, 'light');

subplot(2,1,1); 
a = 3;
signal = comb(a).z; 
Fs = comb(a).Fs;
time = makeTime(numel(signal), Fs);
plot(time, signal,'k','LineWidth',1.5,'DisplayName','saline');
xlabel('Time (s)'); ylabel('RSC GCaMP (z-score)');
xlim([710 720]);  xticks(600:5:800);
ylim([-2 2]); yticks(-4:4);
title('RSC GCaMP + saline')

subplot(2,1,2);
a = 4;
signal = comb(a).z; 
Fs = comb(a).Fs;
time = makeTime(numel(signal), Fs);
plot(time, signal,'b','LineWidth',1.5,'DisplayName','ketamine');
xlabel('Time (s)'); ylabel('RSC GCaMP (z-score)');
% xlim([710 720]);
xlim([727 737]); xticks(600:5:800);
ylim([0 4]); yticks(-4:4);
title('RSC GCaMP + ketamine')