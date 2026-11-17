% hit in column 1
% miss in column 2
% row per animal/recording

outcome = nan(length(comb), 3);
win = [0 15; 15 30; 45 60]; win = win.*60; % baseline, post-drug, washout
lbl = {'baseline','post-drug','washout'};
for a = 1:length(comb)
    tone = [comb(a).beh.hit.tone];
    for ii = 1:size(win,1)
        outcome(a,ii) = numel(find(tone >= win(ii,1) & tone <= win(ii,2)));
    end
    % outcome(a,1) = height(comb(a).beh.hit);
    % outcome(a,2) = height(comb(a).beh.miss);
end

%%
fig = figure; theme(fig,'light');
bar(outcome);
ylabel('number of trials');
xticklabels({comb.mouse});
legend(lbl);

%% 
% STATISTICS
% Repeated-measures anova
% outcome: 8x3, rows = subjects, columns = conditions
tbl = array2table(outcome, ...
    'VariableNames', lbl);
within = table(categorical(["baseline"; "postDrug"; "washout"]), ...
    'VariableNames', {'Condition'});
rm = fitrm(tbl, 'baseline-washout ~ 1', 'WithinDesign', within);
ranovatbl = ranova(rm, 'WithinModel', 'Condition');
multcompare(rm, 'Condition')

%%
% PLOT ALL
% load('c3C_beh_ketamine.mat');
drug = {all.drug};
baseVdrug = nan(length(all(1).mouse), length(drug)); % initialize variables
baseVwash = baseVdrug; % initialize variables
win = [0 15; 15 30; 45 60]; win = win.*60; % baseline, post-drug, washout
lbl = {'baseline','post-drug','washout'};
for b = 1:length(all)
    comb = all(b).comb; % extract sub-structure with behavioral data
    outcome = nan(length(comb), 3);
    for a = 1:length(comb)
        tone = [comb(a).beh.hit.tone]; % tone presentation for Hit trials
        % extract # hits within specified windows
        for ii = 1:size(win,1)
            outcome(a,ii) = numel(find(tone >= win(ii,1) & tone <= win(ii,2)));
        end
    end
    baseVdrug(:,b) = outcome(:,2)./outcome(:,1); % normalize to baseline # hits
    baseVwash(:,b) = outcome(:,3)./outcome(:,1); % normalize to baseline # hits
end

tbl = array2table(baseVdrug, 'VariableNames', drug);
within = table(categorical(drug(:)), 'VariableNames', {'Condition'});
rm = fitrm(tbl, 'saline-ket50 ~ 1', 'WithinDesign', within);
ranovatbl = ranova(rm, 'WithinModel', 'Condition');
pairwiseTbl = multcompare(rm, 'Condition');
p_drug = pairwiseTbl.pValue(10:12);

tbl = array2table(baseVwash, 'VariableNames', drug);
within = table(categorical(drug(:)), 'VariableNames', {'Condition'});
rm = fitrm(tbl, 'saline-ket50 ~ 1', 'WithinDesign', within);
ranovatbl = ranova(rm, 'WithinModel', 'Condition');
pairwiseTbl = multcompare(rm, 'Condition');
p_wash = pairwiseTbl.pValue(10:12);

fprintf('\nPost-drug hit rate normalized to baseline: \n    sal vs ket10: p = %.4f | vs ket25: p = %.4f | vs ket50: p = %.4f \n',...
    p_drug(1),p_drug(2),p_drug(3));
fprintf('Washout hit rate normalized to baseline: \n    sal vs ket10: p = %.4f | vs ket25: p = %.4f | vs ket50: p = %.4f \n',...
    p_wash(1),p_wash(2),p_wash(3));

%%
figure; theme(gcf,'light'); 
subplot(1,2,1); hold on
plot(baseVdrug','Color',[0 0 0 0.2]);
errorbar(1:4, mean(baseVdrug,1,'omitnan'), SEM(baseVdrug,1) , 'o-', ...
    'Color', 'r', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
yline(1,'--k');
ylabel('hit rate (norm to baseline)'); ylim([0 2]); yticks(0:0.5:2);
xlim([0.5 4.5]); xticks(1:4); xticklabels({'saline','ket 10','ket 25','ket 50'});
title('post-drug hit rate');

subplot(1,2,2); hold on
plot(baseVwash','Color',[0 0 0 0.2]);
errorbar(1:4, mean(baseVwash,1,'omitnan'), SEM(baseVwash,1) , 'o-', ...
    'Color', 'r', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
yline(1,'--k');
ylabel('hit rate (norm to baseline)'); ylim([0 2]); yticks(0:0.5:2);
xlim([0.5 4.5]); xticks(1:4); xticklabels({'saline','ket 10','ket 25','ket 50'});
title('washout hit rate');