%% plotFPtoHits_mult
% Description: align photometry signal(s) to behavioral event times using
% spike-triggered average functions. Necessitates prior photometry signal
% processing and behavioral data extraction into combined data structure.
% This script aims to compare STA across multiple sessions for each animal.
%
% INPUTS
% 'comb' - combined data structure from extractCombstruct
% 
% OUTPUTS
% 'fig' - generates figures plotting aligned signals
% 
% Anya Krok, Dec 2025

%% Analyze data
if ~exist('comb','var')
    error('ERROR: comb structure does not exist in workspace.');
end

%% 
win = [-1 5]; % STA window, in seconds
winBase = [win(1)-1, win(1)]; % baseline window, in seconds
out = analyzeFP_STA(comb, win, winBase);

time = out(1).time; % time vector
nFP  = out(1).nFP; % number of photometry signals
FPnames = out(1).FPnames; % photometry signal IDs
uni = unique({out.mouse}); nUni = length(uni);

%% Plot STA, comparing across recordings per animal
% Select behavioral event to plot
opts = out(1).sta.Properties.VariableNames;
idxEvent = menu('Select event: ',opts);
lblEvent = opts{idxEvent};

opts = cell(nFP,1);
for b = 1:nFP; opts{b} = [FPnames{b},' to ',lblEvent,', by mouse']; end
choice = listdlg('ListString',opts,'ListSize',[200 100],'PromptString','Select photometry to plot:');

for c = 1:length(choice)
    fig = figure; theme(fig,'light');
    spX = floor(sqrt(nUni)); spY = ceil(nUni/spX);
    clr = lines(7); % color matrix
    idxFP = choice(c); % index for photometry signal
    for idxMouse = 1:nUni
        subplot(spX,spY, idxMouse); hold on
        
        % iterate over each recording for unique mouse ID
        match = find(strcmp({out.mouse},uni{idxMouse}));
        for a = 1:length(match)
            idx = match(a); 
            mat = out(idx).sta{idxFP, idxEvent}; mat = mat{1};
            shadederrbar(time, mean(mat,2,'omitnan'), SEM(mat,2), clr(a,:));
        end
        xline(0);
        title(sprintf('%s - %s to %s', uni{idxMouse}, FPnames{idxFP}, lblEvent));
        xlabel(sprintf('time to %s (s)',lblEvent)); 
        ylabel(sprintf('%s (dF/F)',FPnames{idxFP}));
        legend({out(match).date}); 
    end
end
