%% plotOpenField
% 
% Description: script to run after processOpenField to plot
%
% INPUTS
% beh - structure with data
%
% Written by Anya Krok March 2026

%% load data
% data may be in 'data' structure with additional photometery, etc
if exist('data','var') && isfield(data,'beh') && isfield(data.beh,'calibrate')
    beh = data.beh; % Assign the behavior data from the loaded structure
elseif exist('beh','var') && isfield(beh,'calibrate')
else
    [fileName,filePath] = uigetfile('*.mat','Select OF data','MultiSelect','off');
    load(fullfile(filePath, fileName));
end

%% extract variables
mouseID = beh.mouseID; 
date    = beh.date;
Nx = beh.coor (:,1); 
Ny = beh.coor (:,2);
binTime = beh.binTime;
binDist = beh.binDist;

%% heatmap
% counts for heatmap
pts = linspace(0, 500, 201);
ave = histcounts2(Ny.*500, Nx.*500, pts, pts);
% create Gaussian filter matrix:
[xG, yG] = meshgrid(-500:500);
sigma = 3.5;
g = exp(-xG.^2./(2.*sigma.^2)-yG.^2./(2.*sigma.^2));
g = g./sum(g(:));

%% PLOT
injTime = 10.75; % injection time, in minutes

fig = figure; theme(fig, 'light');

subplot(1,3,1);
s = scatter(Nx, Ny, 20, 'filled'); s.MarkerFaceAlpha = 0.2; 
% plot(Nx, Ny, ".b", LineWidth=2);
axis equal; axis square; 
xlim([0 1]); ylim([0 1]); xticks(0:0.5:1); yticks(0:0.5:1); 
set(gca,'ydir','reverse');
title([mouseID,'-',date])

subplot(1,3,2);
imagesc(pts, pts, conv2(ave, g, 'same'));
axis equal; axis square; 
ylim([0 500]); xlim([0 500]); axis off
colormap(turbo(256)); clim([0 5]); colorbar('southoutside');
set(gca,'ydir','reverse');
title('heatmap');

subplot(1,3,3); hold on
xline(0,'LineWidth',1.5);
plot(binTime - injTime, binDist./100, 'o-b', 'MarkerFaceColor', [0 0 0]);
axis square;
xlabel('time (min)'); 
ylabel('distance (m per 1 min)'); ylim([0 20]); yticks(0:5:20);
title('distance travelled')