%% extract all
comb = struct;
[fileName,filePath] = uigetfile('*.mat','Select data file(s)','MultiSelect','on');
if ~iscell(fileName); fileName = {fileName}; end
fileName = sort(fileName);
for ii = 1:length(fileName)
    load(fullfile(filePath, fileName{ii}));
    beh = getDistanceOF(beh);
    comb(ii).mouse = beh.mouse;
    comb(ii).date = beh.date;
    comb(ii).beh = rmfield(beh,{'mouse','date'});
end

nDrug = 4;
nMouse = 9; 
injTime = 20; totTime = 80;
clr = [0 0 0; 0.0 0.5 0.75; 0.0 0.75 0.25; 1 0.25 0.0];

%% analyze distance
uni = unique({comb.mouse});
out = cell(length(uni),1);
binTime = 0:totTime; binTime = binTime(:) - injTime; % make time vector
for n = 1:length(uni)
    match = strcmpi({comb.mouse},uni{n});
    sub = comb(match);
    for k = 1:length(sub)
        binDist = sub(k).beh.binDist(2:end);
        binDist(injTime:injTime+1) = nan; % remove data points at injection
        if length(binDist) < (totTime+1)
            binDist(length(binDist)+1 : (totTime+1)) = nan;
        end
        binDist = binDist(1:numel(binTime));
        out{n}(:,k) = binDist(:);
    end
end
binTime = 0:totTime; binTime = binTime(:) - injTime;

%% re-organize output by drug condition
out_byDrug = cell(1,nDrug);
for k = 1:2
    col = cellfun(@(x) x(:,k), out, 'UniformOutput', false); 
    out_byDrug{k} = horzcat(col{:});
end
out_byDrug{3} = out_byDrug{2}(:,2:3:end); % ket 25
out_byDrug{4} = out_byDrug{2}(:,3:3:end); % ket 50
out_byDrug{2} = out_byDrug{2}(:,1:3:end); % ket 10

% calculate mean, stdev, standard error of mean
binDist_mu = cellfun(@(x) mean(x,2,'omitnan'), out_byDrug, 'UniformOutput', false);
binDist_mu = cell2mat(binDist_mu)./100;
binDist_sigma = cellfun(@(x) std(x,0,2,'omitnan'), out_byDrug, 'UniformOutput', false);
binDist_sigma = cell2mat(binDist_sigma)./100;
binDist_sem = binDist_sigma./sqrt(length(uni));

%% PLOT dose-response shaded plot
fig = figure; theme(fig, 'light'); hold on
for k = 1:nDrug
    maskPre = 1:injTime-1; 
    maskPost = injTime+2 : numel(binTime);
    preDrug = [binTime(maskPre), binDist_mu(maskPre, k), binDist_sem(maskPre,k)];
    postDrug = [binTime(maskPost), binDist_mu(maskPost, k), binDist_sem(maskPost,k)];
    mask = isnan(postDrug(:,2:3)); % NaNs not plottable
    if ~isempty(find(mask,1))
        idx = arrayfun(@(x) find(mask(:,x)), 1:2, 'UniformOutput', false);
        if ~all(cellfun(@isempty, idx))
            idx = min(cellfun(@(x) min(x(:)), idx));
            postDrug(idx-1 : end, :) = []; % remove NaNs to allow for plotting
        end
    end
    shadederrbar(preDrug(:,1), preDrug(:,2), preDrug(:,3), clr(k,:));
    shadederrbar(postDrug(:,1), postDrug(:,2), postDrug(:,3), clr(k,:));
end
shadedband([-2 1],ylim);
xlabel('time (min)'); 
ylabel('distance (m per 1 min)');
legend({'saline','','ketamine 10','','ketamine 25','','ketamine 50'});
title('Locomotion Ketamine Dose-Response');

%% total distance:
vec = []; total = [];
for i = 1:length(comb)
    distance = comb(i).beh.distance;
    mask = 1:(injTime+2) * 60 * comb(i).beh.calibrate.frameRate;
    distance(mask) = nan; 
    distPost = sum(distance, 'omitnan');
    timePost = numel(find(~isnan(distance))) ./ comb(i).beh.calibrate.frameRate;
    vec(i,1) = distPost/timePost;
end
total = [vec(1:2:end), vec(2:2:end)];
group = [1:3:9; 2:3:9; 3:3:9];

%% (1b) COMPARE GROUPS
fig = figure; theme(fig, 'light'); 

bar(total([1 4 7 2 5 8 3 6 9],:));


for k = 2:nDrug
    plot(total(group(k-1,:),:)', '*-', 'Color', clr(k,:));
end

b = bar(1:2, mean(total)); b.FaceColor = [0.8 0.8 0.8]; b.EdgeColor = 'none';
errorbar(1:2, mean(total), SEM(total,1), 'k', 'LineWidth', 2);
plot(total','*-', 'LineWidth', 1);
xticks(1:2); xticklabels({'saline','ketamine 30','meth 10'});
ylabel('velocity post-injection (cm/s)');
grid on



% if parametric, do within-subject comparison:
[nMouse, nDrug] = size(total);
varNames = arrayfun(@(k) sprintf('Cond%d', k), 1:nDrug, 'UniformOutput', false);
T = array2table(total, 'VariableNames', varNames);
Within = table((1:nDrug).', 'VariableNames', {'Time'});
formula = sprintf('%s-%s ~ 1', varNames{1}, varNames{end});
% Fit repeated-measures model and do multiple comparisons
rm = fitrm(T, formula, 'WithinDesign', Within);
results = multcompare(rm, 'Time');

title(sprintf('sal v ket: p = %1.3f || sal v meth: p = %1.3f',...
    results.pValue(1), results.pValue(2)));

%% (1b) STATS
[p, rawP, adjP, isParametric] = checkParametric(total);
% if parametric, do within-subject comparison:


%% figure (2) -- plot movement
fig = figure; theme(fig, 'light');
for ii = 1:length(comb)
    subplot(nDrug, nMouse, ii);
    Nx = comb(ii).beh.coor (:,1); 
    Ny = comb(ii).beh.coor (:,2);   
    %close all plot(Nx, Ny, '-');
    s = scatter(Nx, Ny, 10, 'filled'); 
        s.MarkerFaceColor = 'k';
        s.MarkerFaceAlpha = 0.01; 
    axis equal; axis square; 
    xlim([0 1]); ylim([0 1]); xticks(0:0.5:1); yticks(0:0.5:1); 
    set(gca,'ydir','reverse');
    title(comb(ii).beh.rec);
end

%% figure (3) -- plot heatmaps
sub = comb(2:2:end); 

fig = figure; theme(fig, 'light');
for ii = 1:length(sub)
    Nx = sub(ii).beh.coor (:,1); 
    Ny = sub(ii).beh.coor (:,2);   
    pts = linspace(0, 500, 201);
    ave = histcounts2(Ny.*500, Nx.*500, pts, pts);
    % create Gaussian filter matrix:
        [xG, yG] = meshgrid(-500:500);
        sigma = 3.5;
        g = exp(-xG.^2./(2.*sigma.^2)-yG.^2./(2.*sigma.^2));
        g = g./sum(g(:));
    
    subplot(2,4,ii);
    imagesc(pts, pts, conv2(ave, g, 'same'));
    % axis equal; axis square; 
    ylim([0 500]); xlim([0 500]); axis off
    colormap(turbo(256)); clim([0 5]); colorbar('southoutside');
    set(gca,'ydir','reverse');
    title([sub(ii).mouse,'-',sub(ii).date]);
end

