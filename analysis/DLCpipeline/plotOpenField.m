%% plotOpenField
% 
% Description: script to run after processOpenField to plot
%
% INPUTS
% beh - structure with data
%
% Written by Anya Krok March 2026

%% load data
[fileName,filePath] = uigetfile('*.mat','Select OF data','MultiSelect','off');
load(fullfile(filePath, fileName));
% data may be in 'data' structure with additional photometery, etc
if exist('data','var') && isfield(data,'beh') && isfield(data.beh,'calibrate')
    beh = data.beh; % Assign the behavior data from the loaded structure
elseif exist('beh','var') && isfield(beh,'calibrate')
else
    error('No open field data loaded. \n')
end

%% extract variables
mouseID = beh.mouseID; 
date    = beh.date;
Nx = beh.coorNorm(:,1); 
Ny = beh.coorNorm(:,2);
binTime = beh.binTime;
binDist = beh.binDist;

%% optional rotation, if necessary
[Nx, Ny, theta] = rotateOpenField(Nx, Ny, theta);

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
fig = figure; theme(fig, 'light');

subplot(1,3,1);
s = scatter(Nx, Ny, 20, 'filled'); s.MarkerFaceAlpha = 0.2; 
% plot(Nx, Ny, ".b", LineWidth=2);
axis equal; axis square; xlim([0 1]); ylim([0 1]);
set(gca,'ydir','reverse');
title([mouseID,'-',date])

subplot(1,3,2);
imagesc(pts, pts, conv2(ave, g, 'same'));
axis equal; axis square
set(gca, 'xLim', pts([1 end]), 'yLim', pts([1 end]), 'yDir', 'normal');
colormap(turbo(256)); clim([0 5]); colorbar;
ylim([0 500]); xlim([0 500]);
set(gca,'ydir','reverse');
title('Heatmap');

subplot(1,3,3); hold on
xline(0,'LineWidth',1.5);
plot(binTime, binDist, 'o-b', 'MarkerFaceColor', [0 0 0]);
axis square;
xlabel('Time (min)'); ylabel('Distance (cm per 5 min)');
title('Distance Travelled')