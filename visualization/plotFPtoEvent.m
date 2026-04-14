%
% plotFPtoEvent
%
% Description: align photometry signal(s) to behavioral event times using
% spike-triggered average functions. Necessitates prior photometry signal
% processing and behavioral data extraction into combined data structure.
%
% Align photometry for rewarded trials to
%   (1) first poke (2) reward delivery (3) soundOnRight (4) soundOnLeft
%
% Inputs:
%   'comb' - combined data structure from extractCombstruct
% 
% Outputs:
%   'fig' - generates multiple figures (one per photometry signal)
% 
% Anya Krok, Dec 2025
% Updated April 2026

if ~exist('comb','var')
    error('ERROR: comb structure does not exist in workspace.');
end

%%
win = [-1 5]; % window, in seconds
out = analyzeFP_STA(comb, win);

% extract variables:
uni  = unique({out.mouse}); % unique mouse IDs
nUni = length(uni);
time = out(1).time; % time vector
win  = [round(time(1)), round(time(end))]; % recreate plotting window
nFP  = out(1).nFP;  % number of photometry signals
lblPhoto = out(1).lblPhoto; % photometry signal IDs
lblEvent = out(1).evPhoto.Properties.VariableNames; % event labels

%% 
% select behavior events to align to:
chooseEv = listdlg('PromptString','Select events: ','SelectionMode','multiple',...
    'ListString',lblEvent);
if isempty(chooseEv); error('No event select, try again.'); end
%%
clr = lines(7); % color matrix for plotting
if isscalar(chooseEv)
    % Generate single figure with subplots for each unique mouse ID
    % Multiple rows if recording includes multiple photometry signals
    fig = figure; theme(fig,'light');
    for idxFP = 1:nFP
        for idxMouse = 1:nUni
            subplot(nFP, nUni, idxMouse + (idxFP-1)*nUni); hold on
            match = find(strcmp({out.mouse},uni{idxMouse})); % indices for all recs for this mouse
            for m = 1:length(match)
                a = match(m);
                mat = out(a).evPhoto{idxFP, chooseEv}; mat = mat{1}; % extract data
                shadederrbar(time, mean(mat,2,'omitnan'), SEM(mat,2), clr(m,:));
            end
            xline(0);
            title(sprintf('%s - %s to %s', uni{idxMouse}, lblPhoto{idxFP}, lblEvent{chooseEv}));
            xlabel(sprintf('time to %s (s)',lblEvent{chooseEv})); xlim(win); xticks(-10:10);
            ylabel(sprintf('%s (dF/F)',lblPhoto{idxFP}));
            legend({out(match).date});
        end
    end
    fprintf('Generated %d figure; [%s] to %s.\n',...
        1, strjoin(lblPhoto,', '), strjoin(lblEvent(chooseEv),', '));

elseif length(chooseEv) > 1
    % Generate multiple figures, one for each unique photometry signal
    for idxFP = 1:nFP
        fig = figure; theme(fig,'light');
        for idxMouse = 1:nUni
            match = find(strcmp({out.mouse},uni{idxMouse})); % indices for all recs for this mouse
            for i = 1:length(chooseEv)
                idxEvent = chooseEv(i);
                subplot(4, nUni, idxMouse + (i-1)*nUni); hold on
                for m = 1:length(match)
                    a = match(m);
                    mat = out(a).evPhoto{idxFP, idxEvent}; mat = mat{1}; % extract data
                    shadederrbar(time, mean(mat,2,'omitnan'), SEM(mat,2), clr(m,:));
                end
                xline(0,'LineWidth',1.5);
                title(sprintf('%s - %s to %s', uni{idxMouse}, lblPhoto{idxFP}, lblEvent{idxEvent}));
                xlabel(sprintf('time to %s (s)',lblEvent{idxEvent})); xlim(win); xticks(-10:10);
                ylabel(sprintf('%s (dF/F)',lblPhoto{idxFP}));
                legend({out(match).date});
            end
        end
    end
    fprintf('Generated %d figures: [%s] aligned to %s.\n',...
        nFP,strjoin(lblPhoto,', '),strjoin(lblEvent(chooseEv),', '));
end