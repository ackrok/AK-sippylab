%% 
% simple plots for assessing photometry data
%
% Anya Krok, April 2026

%%
% plot raw data
fig = figure; theme(fig, 'light');
ds = 100;
for y = 1:2
    subplot(2,1,y); hold on
    signal = data.acq.FP{y}; 
    signal = signal(1:ds:end);
    plot(signal, 'DisplayName', data.acq.FPnames{y});
    xlabel('time (samples)'); ylabel('photo (V)');
    title(sprintf('%s - raw photometry',data.acq.FPnames{y}));
end 

%%
% plot processed photometry signal
time = makeTime(numel(data.final.FP{1}), data.gen.Fs); % make time vector from nSamp and Fs
fig = figure; theme(fig, 'light');
for y = 1:2
    subplot(2,1,y); 
    plot(time, data.final.FP{y}, 'DisplayName', data.final.FPnames{y});
    xlabel('time (s)'); ylabel('photo (dF/F)');
    legend
end

%%
% quick fourier transform of raw photometry signal to double-check that it
% was frequency modulated
fig = figure; hold on
for y = 1:2
    signal = data.acq.FP{y}; 
    Fs = data.gen.acqFs;
    signal(isnan(signal)) = [];
    T = 1/Fs;               % Sampling period
    L = length(signal);     % Length of signal
    needL = 2500*Fs;        % Ensure signal length is at least 2500 seconds
    signal = repmat(signal,[ceil(needL/L) 1]);
    signal = signal(1:needL); % Trim if went over
    L = length(signal);       
    ffttmp = fft(signal);   % Discrete Fourier Transform of photometry signal
    P2 = abs(ffttmp/L);     % Two-sided spectrum P2
    P1 = P2(1:L/2+1);       % Single-sided spectrum P1 based on P2 and even-valued signal length L
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;     % Frequency domain vector
    P1 = medfilt1(P1);      % Median filter initial FFT
    P1 = movmean(P1,500);   % Smooth FFT output
    subplot(2,1,y);
    plot(log10(f),P1,'DisplayName',data.acq.FPnames{y});
    xlim([0 3.5]);
    xticks([0 1 log10(60) 2 log10(217) log10(319) 3]); 
    xticklabels({'1','10','60','100','217','319','1000'});
    title(sprintf('%s - raw photometry FFT',data.acq.FPnames{y}));
end
