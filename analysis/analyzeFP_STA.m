function out = analyzeFP_STA(comb, varargin)
% Analyze photometry signal to align to behavioral events
%
% out = analyzeFP_STA(comb)
% out = analyzeFP_STA(comb, win, base)
%
% INPUTS
% 'comb' - structure with data from multiple recordings, created using 
%           script "extractComb"
% 'win'  - window for STA analysis, default is [-1 2] seconds
% 'base' - window for baselining, default is [-2 -1]
%
% OUTPUTS
% 'out' - structure with behavior performance metrics
%   - out(a).mouse   - mouse ID
%   - out(a).date    - all recording dates
%   - out(a).sta     - table with STA data
%       - table columns are behavioral events that are aligned to
%       - table rows are each photometry signal (eg, 2 rows 5-HT, rDA)
%   - out(a).time - time vector for plotting STA
%
% Note: to extract table headers, use headers = T.Properties.VariableNames
%
% Written by Anne Krok, Dec 2025
%

% Default inputs
win = [-1 2]; % STA window, in seconds
win_base = [-2 -1]; % baseline window, in seconds
switch nargin
    case 2
        win = varargin{1};  % Update STA window if provided
    case 3
        win = varargin{1};
        win_base = varargin{2}; % Update baseline window if provided
end

%% Initialize output variable
out = struct;


%% Align photometry signals to behavioral event
opts = {'rightHit','leftHit','miss','incorrectAction','abort'};

% uni = unique({comb.mouse});
% for ii = 1:length(uni)
%     match = find(strcmp({comb.mouse},uni{ii}));
% 
%     for jj = 1:length(match)
%         a = match(jj);

for a = 1:length(comb)
        Fs  = comb(a).Fs;
        nFP = length(comb(a).FP);
        beh = comb(a).beh;

        idxHits  = beh.hitT.trial; % index for rewarded trials
        firstPoke = beh.trial.firstPoke; % alignment to mouse self-initiation of rewarded trial
        soundOn   = beh.trial.soundOn; 
        hit       = beh.hitT.hits;
        if isnan(beh.trial.start(1))
            rmv = find(isnan(beh.trial.start)); % index of first trial that starts after photometry
            idxHits(ismember(idxHits, rmv)) = [];
        end
    
        photo2event = cell(length(opts)+2, nFP); % initialize temporary variable
        time = win(1) : 1/Fs : win(2);
        for b = 1:nFP
            signal = comb(a).FP{b}; % signal
            
            event = firstPoke(idxHits)./Fs; % firstPoke for rewarded trials
            sta = getSTA(signal, event, Fs, win);
            sta_base = getSTA(signal, event, Fs, win_base);
            sta = sta - mean(sta_base,1,'omitnan');
            photo2event{1,b} = sta;
        
            event = hit./Fs; % reward delivery
            sta = getSTA(signal, event, Fs, win);
            sta_base = getSTA(signal, event, Fs, win_base);
            sta = sta - mean(sta_base,1,'omitnan');
            photo2event{2,b} = sta;
            
            for kk = 1:length(opts)
                ll = strcmpi(beh.trial.lastAct, opts{kk});
                if any(ll)
                    event = soundOn(ll)./Fs; % soundOn by outcome
                    sta = getSTA(signal, event, Fs, win);
                    sta_base = getSTA(signal, event, Fs, win_base);
                    sta = sta - mean(sta_base,1,'omitnan');
                    photo2event{2+kk,b} = sta;
                else
                    photo2event{2+kk,b} = nan(numel(time),1);
                end
            end
        end
        lbls = {'pokeRew','reward','soundOnHitR','soundOnHitL','soundOnMiss','soundOnError','soundOnAbort'};
        T = cell2table(photo2event.', 'VariableNames', lbls);
        out(a).mouse = comb(a).mouse;
        out(a).date  = comb(a).date;
        out(a).nFP   = nFP;
        out(a).FPnames = comb(a).FPnames;
        out(a).sta   = T;
        out(a).time  = time;
end




%%
% opts = fieldnames(comb(1).beh); % options are all behavioral events names
% lbls = {'hits','miss','error','lickStartTrial','lickStartHitTrial'}; % hard-coded which behavioral events to process
% 
% uniMouse = unique({comb.mouse}); %  unique mouse IDs from the input structure
% 
% % Loop through each unique mouse ID to calculate performance metrics
% for thisMouse = 1:length(uniMouse)
%     % Loop through each recording for each unique mouse ID
%     match = find(strcmp({comb.mouse},uniMouse{thisMouse}));
% 
%     out(thisMouse).mouse = uniMouse{thisMouse}; % STORE
%     out(thisMouse).recs  = {comb(match).date}; % STORE
%     C = cell(length(match), 2, length(lbls)); % Initiate cell array
%     % #rows is #recordings for unique mouse ID
%     % #columns is #photometry signals
%     % #pages is #behavioral events
%     C2 = cell(2, length(lbls)); % Initiate cell array for averaged data
% 
%     for a = 1:length(match)
%         FP  = comb(match(a)).FP; % Photometry signal(s)
%         nFP = length(comb(match(a)).FPnames); % Number of phototometry signals
%         beh = comb(match(a)).beh; % Behavioral data for one recording
%         beh.error = sort([beh.error; beh.noHold]);
%         Fs  = comb(match(a)).Fs; % Sampling frequency
%         mouse = comb(match(a)).mouse; date = comb(match(a)).date; % Store to be able to check in case of errors
% 
%         % Loop through each behavioral events
%         for pickEv = 1:length(lbls)
%             % Extract event times based on label
%             ev = getfield(beh, opts{strcmp(opts, lbls{pickEv})});
%             ev = ev./Fs; % convert to seconds
% 
%             % Loop through each photometry signal
%             for thisFP = 1:nFP
%                 signal = FP{thisFP}; 
%                 [sta, time] = getSTA(signal, ev, Fs, win);
%                 base        = getSTA(signal, ev, Fs, winBase);
%                 base = nanmean(base,1); % average across entire baseline window to create vector of length(nHits)
%                 staAdj = sta - base; % subtract baseline
% 
%                 C{a, thisFP, pickEv} = staAdj; % STORE
%                 C2{thisFP, pickEv}(:,a) = nanmean(staAdj,2); % STORE
% 
%             end
%         end
%     end
% 
%     T = table();
%     for p = 1:size(C,3)
%         T.(lbls{p}) = C(:,:,p);
%     end
%     out(thisMouse).sta = T;
%     out(thisMouse).time = time;
%     out(thisMouse).nFP = nFP; out(thisMouse).FPnames = comb(1).FPnames;
% end

