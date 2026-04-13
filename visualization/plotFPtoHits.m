%% plotFPtoHits
% Description: align photometry signal(s) to behavioral event times using
% spike-triggered average functions. Necessitates prior photometry signal
% processing and behavioral data extraction into combined data structure.
%
% INPUTS
% 'comb' - combined data structure from extractCombstruct
% 
% OUTPUTS
% 'alignAll', 'alignAvg' - analysis outputs with STA to event
% 'fig' - generates 1-3 figures plotting aligned signals
% 
% Anya Krok, Dec 2025

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

%% Group analyzed data based on unique mouse IDs
% [uni,~,idxMap] = unique({comb.mouse});
% alignUni = cell(length(uni),nFP);
% for ii = 1:length(uni)
%     match = find(strcmp({comb.mouse}, uni{ii})); % idx of recordings with same unique mouse ID
%     for b = 1:nFP
%         pull = alignAll(match, b);
%         alignUni{ii,b} = horzcat(pull{:}); % concatenate data
%     end
% end

%% Plot by photometry signal
thisMouse = menu('Select mouse: ',uni);
match = find(strcmp({out.mouse},uni{thisMouse}));
sub = out(match);

opts = out(1).sta.Properties.VariableNames;
idxEvent = menu('Select event: ',opts);
lbl = opts{idxEvent};

opts2 = cell(nFP+1,1);
for idxFP = 1:nFP; opts2{idxFP} = [FPnames{idxFP},' to ',lbl,', by mouse']; end
opts2{nFP+1} = ['all photometry to ',lbl,', averaged'];
choice = listdlg('ListString',opts2,'ListSize',[300 100],'PromptString','Select photometry to plot:');

for ii = 1:length(choice)
    switch choice(ii)
        case 1
            idxFP = 1; clr = 'g';
            fig = figure; theme(fig,'light');
            spX = floor(sqrt(length(match))); spY = ceil(length(match)/spX);
            for a = 1:length(sub)
                subplot(spX,spY,a); hold on
                mat = sub(a).sta{idxFP, idxEvent}; mat = mat{1};
                shadederrbar(time, mean(mat,2,'omitnan'), SEM(mat,2),clr);
                xline(0);
                title(sprintf('%s-%s: (%d trials)',...
                    sub(a).mouse,sub(a).date,size(mat,2)));
                xlabel(sprintf('time to %s (s)',lbl)); 
                ylabel(sprintf('%s FP (dF/F)',FPnames{idxFP}));
            end
        
        case 2
            idxFP = 2; clr = 'r';
            fig = figure; theme(fig,'light');
            spX = floor(sqrt(length(match))); spY = ceil(length(match)/spX);
            for a = 1:length(sub)
                subplot(spX,spY,a); hold on
                mat = sub(a).sta{idxFP, idxEvent}; mat = mat{1};
                shadederrbar(time, mean(mat,2,'omitnan'), SEM(mat,2),clr);
                xline(0);
                title(sprintf('%s-%s: (%d trials)',...
                    sub(a).mouse,sub(a).date,size(mat,2)));
                xlabel(sprintf('time to %s (s)',lbl)); 
                ylabel(sprintf('%s FP (dF/F)',FPnames{idxFP}));
            end

        case 3
            % fig = figure; theme(fig,'light');
            % for idxFP = 1:length(FPnames)
                % subplot(2,nFP,idxFP);
                % edit to have averages
                % plot(staTime, alignAvg{idxFP});
                % xline(0);
                % title(sprintf('%s to %s (n = %d)',comb(1).FPnames{idxFP},lbl,size(alignAvg{idxFP},2)))
                % xlabel(sprintf('time to %s (s)',lbl)); ylabel('FP (dF/F)');
                % legend({comb.mouse});
                % 
                % subplot(2,nFP,idxFP+2);
                % switch idxFP; case 1; clr = 'g'; case 2; clr = 'r'; end
                % shadederrbar(staTime, mean(alignAvg{idxFP},2,'omitnan'), SEM(alignAvg{idxFP},2), clr);
                % xline(0);
                % xlabel(sprintf('time to %s (s)',lbl)); ylabel('FP (dF/F)');
                % legend(FPnames{idxFP});
            %end
    end
end
