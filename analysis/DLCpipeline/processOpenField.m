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
binSec = 1; % analyze locomotion in X min bins
maxVidLength = 35*60; % ENTER number of seconds at which to cut off video

%% Calibrate based on pixel width of video file
calibrateOpenField;

% [fileName,filePath] = uigetfile('*.mat', 'Select data file', '.');
% if filePath==0
%     choice = menu('Run calibrateOpenField?','Yes','No');
%     if choice == 1
%         calibrateOpenField;
%     end
% else
%     calibrate = load(fullfile(filePath,fileName) );
% end

%% Import coordinates
[fileName,filePath] = uigetfile('*.csv','Select the DLC file','MultiSelect','on');
cd(filePath); 
assert(exist(fileName,'file')==2, '%s does not exist.', fileName);
file=fullfile(filePath,fileName);
mouseID = fileName(1:5); % extract mouse ID
date = fileName(8:15); date = erase(date,'-'); % extract date

tic
hdr2 = readcell(fileName,'Range','2:2');
colToGet = find(hdr2 == 'fiber'); % columns with headrow 2 as 'fiber'
opts = detectImportOptions(fileName);
opts.DataLines = [4 Inf]; % skip first 3 header rows, read from row 4 onward
opts.VariableNamesLine = 3; % read variable names on line 3
opts = setvaropts(opts, opts.VariableNames);
opts.SelectedVariableNames = opts.VariableNames(colToGet); % default columns are 11:13
opts = setvartype(opts, opts.SelectedVariableNames, 'double'); 
tbl = readtable(fileName, opts);
toc

%% Extract variables
frame = 1:size(tbl,1); frame = frame(:);
x = tbl.x;
y = tbl.y;
likelihood = tbl.likelihood;
coor = [x(:), y(:)];

% adjust by calibration scale
coor = coor .* calibrate.scale;

% cut to maximal video length
cut = maxVidLength*frameRate ;
coor = coor(1:floor(cut),:);
frame = frame(1:floor(cut));
likelihood = likelihood(1:floor(cut));

%% Retain only valid coordinates

% mask low-likelihood coordinates, replace values with NaN
mask = likelihood < threshold;
coor(mask,:) = nan;

% return percentage of frames that were above threshold
n = length(coor);
valid = ~isnan(coor(:,1));
aboveThres = length(find(valid))/n; % save proportion of valid coordinates

% interpolate missing values
% note if endpoints are NaN, use nearest extrapolation.
idx = (1:n).'; 
if any(valid)
    coor(~valid,:) = interp1(idx(valid), coor(valid,:), idx(~valid), 'linear', 'extrap');
    else, coor(:) = NaN;
end
x = coor(:,1); y = coor(:,2);

%% Frame-to-frame distance
distance = hypot(diff(x), diff(y));

% interpolate nans in distance
if any(isnan(distance))
    m = numel(distance); idxD = (1:m).';
    valid = ~isnan(distance);
    distance(~valid) = interp1(idxD(valid), distance(valid), idxD(~valid), 'linear', 'extrap');
end

% total distance (in cm)
totDist = sum(distance, 'omitnan');

% distance by bins
binSec = 1*60;
framesPerBin = frameRate * binSec;  % number of frames in bin
% assign each distance sample to a bin (1-based)
binIdx = ceil((1:numel(distance)) / framesPerBin).';
% sum distances per bin
numBins = max(binIdx);
distPerBin = accumarray(binIdx, distance, [numBins, 1], @sum, 0);  % cm per bin
% adjust for bin size and make time vector
distPerBin = distPerBin / binSec;
timeBin = ((0:numBins-1) * binSec) / 60;
timeBin = timeBin - 10; 

%% Normalize x and y coordinates
Nx = normalize(x,'range');
Ny = normalize(y,'range');
normData = [frame, Nx, Ny];

% counts for heatmap
pts = linspace(0, 500, 201);
ave = histcounts2(Ny.*500, Nx.*500, pts, pts);

% create Gaussian filter matrix:
[xG, yG] = meshgrid(-500:500);
sigma = 3.5;
g = exp(-xG.^2./(2.*sigma.^2)-yG.^2./(2.*sigma.^2));
g = g./sum(g(:));

%% Plot individual animal tracks to normalized space
% fig = figure; theme(fig, 'light');
% 
% subplot(1,3,1);
% s = scatter(Nx, Ny, 20, 'filled'); s.MarkerFaceAlpha = 0.2; 
% % plot(Nx, Ny, ".b", LineWidth=2);
% axis equal; axis square;
% set(gca,'ydir','reverse');
% title([mouseID,'-',date])
% 
% subplot(1,3,2);
% imagesc(pts, pts, conv2(ave, g, 'same'));
% axis equal; axis square
% set(gca, 'xLim', pts([1 end]), 'yLim', pts([1 end]), 'yDir', 'normal');
% colormap(turbo(256)); clim([0 5]); colorbar;
% ylim([0 500]); xlim([0 500]);
% set(gca,'ydir','reverse');
% title('Heatmap');
% 
% subplot(1,3,3); hold on
% xline(0,'LineWidth',1.5);
% plot(timeBin, distPerBin, 'o-b', 'MarkerFaceColor', [0 0 0]);
% axis square;
% xlabel('Time (min)'); ylabel('Distance (cm per 5 min)');
% title('Distance Travelled')

%% Save Results to .mat structure
beh = struct;
beh.mouseID  = mouseID;
beh.date     = date;
beh.calibrate = calibrate;
beh.coorNorm  = [Nx, Ny];
beh.distance  = distance(:);
beh.totalDist = totDist;
beh.binSize = binSec;
beh.binTime = timeBin(:);
beh.binDist = distPerBin(:);
beh.aboveThres = aboveThres;
mat_suffix = '.mat';
matFile = fullfile(filePath, [mouseID date mat_suffix]);
save(matFile,'beh');