%%
% Description: plotting FFT, band power over time, and comparison of band
% power within windows for RSC GCaMP recordings
%
% Anya Krok, Jan 29 2026

%% FFT with pwelch
out = struct;
for a = 1:length(comb)
    b = 1; 
    signal = comb(a).FP{b};  % signal
    Fs = comb(a).Fs;         % sampling frequency, Hz
    params.winSec = 10; params.fmax = 15; % parameters
    [P, T, F] = getWelch(signal, Fs, params); % ANALYZE
    out(a).mouse = comb(a).mouse; out(a).date = comb(a).date;
    out(a).P = P; out(a).T = T; out(a).F = F;
end

band = [1 3]; % Hz
win1 = [0 10]; % baseline window pre-injection
win2 = [12 15]; % post-injection window
inj  = 11; % injection time

% compute band power for each time bin, output is 1 x nTimeBins 
for a = 1:length(out)
    out(a).band = band;
    out(a).bandPower = bandpower(out(a).P, out(a).F, band, "psd"); % power within specified band
    idx1 = out(a).T >= win1(1) & out(a).T < win1(2);
    idx2 = out(a).T >= win2(1) & out(a).T < win2(2);
    mean1 = mean(out(a).bandPower(idx1)); 
    mean2 = mean(out(a).bandPower(idx2));
    out(a).win = [win1; win2];
    out(a).winPower = [mean1; mean2];
end


%% Plot band power (1-3Hz) over time
uni = unique({out.mouse}); 

figure;
for x = 1:length(uni)
    match = find(strcmp({out.mouse},uni{x}));
    subplot(length(uni),1,x); hold on
    for y = 1:length(match)
        a = match(y);
        plot(out(a).T - inj, out(a).bandPower); % plot trace
    end
    xline(0, '--k', 'LineWidth', 2);
    xlabel('time from injection (min)'); xlim([-10 20]);
    ylabel(sprintf('power in RSP (%d-%d Hz)', band(1), band(2))); ylim([0 1]);
    title(sprintf('Band Power - %s',out(a).mouse))
    legend({'saline','ketamine'});
end

%% Plot comparison of mean band power
winPower = [out.winPower]';
injLbl = {'saline','ketamine','saline','ketamine'};

figure;
bb = bar(winPower(:,2)); ylabel('band power');
% hold on; yline(1,'--k','LineWidth',2); ylabel('band power divided by baseline');
xticklabels(strcat({out.mouse},{'-'},injLbl));
title('comparison of mean band power');
grid on;

bb.FaceColor = 'flat'; % allows per-bar colors
clr = repmat([0.6 0.6 0.9], size(winPower,1), 1); % default colors for bars
clr(2:2:end, :) = repmat([1 0 0], numel(2:2:size(winPower,1)), 1);
bb.CData = clr;

%% Plot spectrogram (for ONE recording)
% a = 4;
% figure;
% imagesc(out(a).T, out(a).F, 10*log10(out(a).P));
% axis xy;
% xlabel('time (min)'); ylabel('frequency (Hz)');
% title(sprintf('PSD'));
% colorbar;
