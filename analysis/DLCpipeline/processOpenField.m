%% processOpenField
% 
% Description: script to compute behavioral measures from DLC output 
% (x,y,likelihood)
%
% INPUTS
% User will be prompted to (1) run calibrateOpenField, and then
%                          (2) open .csv DLC output data file
% 
% OUTPUTS
% beh - structure with data
%
% Written by Anya Krok March 2026
%
%% adjustable variables
frameRate = 30; % in Hz
threshold = 0.9; % cutoff for low-likelihood values
binSize = 1; % in minutes, for analyzing locomotion in X min bins

%% Calibrate based on pixel width of video file
calibrateOpenField;

% [fileName,filePath] = uigetfile('*.mat', 'Select data file', '.');
% if filePath==0
%     choice = menu('Run calibrateOpenField?','Yes','No');
%     if choice == 1
%         calibrateOpenField;
%     end
% else
%     load(fullfile(filePath,fileName) );
% end

%% Import coordinates
[fileName,filePath] = uigetfile('*.csv','Select the DLC file');
cd(filePath); 
assert(exist(fileName,'file')==2, '%s does not exist.', fileName);
file=fullfile(filePath,fileName);
mouseID = fileName(1:5); % extract mouse ID
date = fileName(8:15); date = erase(date,'-'); % extract date

tic
hdr2 = readcell(fileName,'Range','2:2');
colToGet = find(strcmpi(hdr2,'fiber')); % columns with headrow 2 as 'fiber'
opts = detectImportOptions(fileName);
opts.DataLines = [4 Inf]; % skip first 3 header rows, read from row 4 onward
opts.VariableNamesLine = 3; % read variable names on line 3
opts = setvaropts(opts, opts.VariableNames);
opts.SelectedVariableNames = opts.VariableNames(colToGet); % default columns are 11:13
opts = setvartype(opts, opts.SelectedVariableNames, 'double'); 
tbl = readtable(fileName, opts);
toc

%% Extract variables
x = tbl.x; 
y = tbl.y;
likelihood = tbl.likelihood;

coor = [x(:), y(:)];
coor = coor - min(coor); % adjust so values are positive
coor = coor .* calibrate.scale; % adjust by calibration scale

% trim to nearest minute
cut = floor(numel(x)/(60 * calibrate.frameRate)); % round to nearest min
cut = cut * 60 * calibrate.frameRate;    % convert to samples
coor = coor(1:cut,:);          % trim
likelihood = likelihood(1:cut);% trim
x = coor(:,1);
y = coor(:,2); 

%% Get distance
beh = getDistanceOF(x, y, likelihood);

%% Plot and adjust
Nx = beh.coor(:,1); 
Ny = beh.coor(:,2);
lik = likelihood; 

fig = figure; theme(fig, 'light');
% show background image beneath scatter
subplot(1,2,1,'Parent',fig); 
title('first frame');
imshow(calibrate.image); drawnow;
% plot normalized x- and y- coordinates
ax = subplot(1,2,2,'Parent',fig); hold(ax,'on');
title(sprintf('Draw box. \n Double-click or press Enter to finish.')); 
scatter(ax, Nx, Ny, 10, 'filled', 'MarkerFaceAlpha', 0.2);
axis equal; axis square; xlim([0 1]); ylim([0 1]);
set(gca,'ydir','reverse');
drawnow; % ensure titles render
% prompt and draw rectangle ROI on the same axes
msg = 'Draw a rectangle labeled "Center". Double-click or press Enter to finish.';
disp(msg);
hRect = drawrectangle(ax, 'Color', [1 0 0], 'Label', 'BOX');
wait(hRect); % returns when ROI is finished
title('Done!'); drawnow;

% extract box position
pos = hRect.Position; % [xmin, ymin, width, height]
xmin = pos(1); ymin = pos(2);
xmax = xmin + pos(3); ymax = ymin + pos(4); 

% remove outside coordinates
outside = Nx <= xmin | Nx >= xmax | Ny <= ymin | Ny >= ymax;
lik(outside) = 0.1; % set likelihood for outside points to 0.1

% repeat analysis
beh = getDistanceOF(x, y, lik);

%% optional rotation, if necessary
% Nx = beh.coor(:,1); 
% Ny = beh.coor(:,2);
% [Nx, Ny, theta] = rotateOpenField(Nx, Ny, theta);

%% Save 
beh.mouseID   = mouseID;
beh.date      = date;
beh.calibrate = calibrate;
save([mouseID,'-',date,'_OF.mat'],'beh');