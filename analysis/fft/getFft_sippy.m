%% Description:
% Adaptation of plot_achda_fft code from Tritsch lab analyses
%
% Briefly, this code will use FFT analysis to extract frequency components 
% in photometry signal. Simple FFT will be run on photometry signal, then
% output will be normalized and then substracted from pre-processed FFT 
% from stable fluorophore signal.
%
% OUTPUTS
%   'f'     - frequency vector
%   'flog'  - frequency vector (log-scale)
%   'out_fft'  - matrix with FFT output for all recordings
%   'out_norm' - normalized across specified frequency range
%   'out_sub'  - subtracted from stable fluorophore
%   'auc' - area under the curve 
%
% Anya Krok, July 2022
% Updated Anya Krok, December 2025 for use in Sippy lab

if ~exist('comb','var'); comb = extractComb_raw(); end
y = menu('Input',comb(1).FPnames); % select which signal to analyze

%% FFT
needL = 900; % analyze first 15 minutes of recording
out_fft = []; % clear variable
h = waitbar(0, 'FFT photometry signals');
for x = 1:length(comb)
    vec = [comb(x).FP{y}]; 
    if isempty(vec); continue; end
    Fs = comb(x).Fs;
    vec = repmat(vec,[ceil(needL*Fs/length(vec)) 1]);
    vec = vec(1:needL*Fs);
    L = length(vec);        % Length of signal
    vec(isnan(vec)) = [];
    fftTmp = fft(vec);      % Discrete Fourier Transform of photometry signal
    P2 = abs(fftTmp/L);     % Two-sided spectrum P2
    P1 = P2(1:L/2+1);       % Single-sided spectrum P1 based on P2 and even-valued signal length L
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;     % Frequency domain vector
    P1 = medfilt1(P1);      % Median filter initial FFT
    P1 = movmean(P1,500);   % Smooth FFT output
    out_fft = [out_fft, P1]; % Concatenate output
    waitbar(x/length(comb),h);
end
close(h);
f = f(:);

%% normalize FFT across specified range
range_norm = [0.1 50]; % range for normalization of FFT output, in Hz

out_norm = [];
r = find(f == range_norm(1)):find(f == range_norm(2)); % restrict range to specified above
flog = log10(f(r)); % log-scale frequency vector
for x = 1:size(out_fft,2)
    a = log10(out_fft(r,x));
    a_end = mean(log10(out_fft(find(f == 20):find(f == 25),x)));
    vec_norm = (a - a_end)./(a(1) - a_end); 
    % vec_norm = normalize(log10(p1_mat(r,x)),'range'); % Normalize range from [0.01 100], scaling so range covers [0 1]
    out_norm(:,x) = vec_norm;
end

%% subtract stable fluorophore signal
% out_sub = []; 
% switch y
%     case 1 % green
%         out_sub = out_sub - nanmean(norm_grn);
%     case 2 % red
%         out_sub = out_sub - nanmean(norm_red);
% end

%%
figure;
uni = unique({comb.mouse});
spX = floor(sqrt(length(uni))); spY = ceil(length(uni)/spX);
for ii = 1:length(uni)
    match = strcmp({comb.mouse},uni{ii});
    subplot(spX,spY,ii); hold on
    plot(flog, out_norm(:,match)); % plot normalized FFT
    xlabel('Frequency');
        xlim([flog(f == 0.5) flog(f == 20)]); 
        xticks(-2:2); xticklabels({'0.01','0.1','1','10','100'});
    ylabel('Power (a.u.)'); ylim = [0 1]; yticks([0 1]);
    title(sprintf('%s: fft (%s)',uni{ii},comb(1).FPnames{y}));
    legend('pre','ket','post');
end
