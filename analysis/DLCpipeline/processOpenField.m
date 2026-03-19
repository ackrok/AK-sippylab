%% processOpenField
% 
% Description: script to run after calibrateOpenField to compute behavioral
% measures from DLC output (x,y,likelihood) and time in center
%
% INPUTS
% User will be prompted to (1) open OFCalibration.mat, and then
%                          (2) open XXX.csv DLC output data file
% 
% OUTPUTS
% beh - structure with data
%
% Written by Anya Krok March 2026
%
%% adjustable variables
frameRate = 30; % in Hz
thresholdLikelihood = 0.9; % cutoff for low-likelihood values
binSec = 300; % analyze locomotion in 5 min bins
maxVidLength = 35*60; % ENTER number of seconds at which to cut off video

%% Select Calibration Structure
[fileName,filePath] = uigetfile('*.mat', 'Select data file', '.');
if filePath==0, error('None selected!');
end
calibrate = load(fullfile(filePath,fileName) );
calibrate = calibrate.calibrate;
cd(filePath); 

%% Import the data
[fileName,filePath] = uigetfile('*.csv','Select the DLC file','MultiSelect','on');
cd(filePath); 
assert(exist(fileName,'file')==2, '%s does not exist.', fileName);
file=fullfile(filePath,fileName);
date = fileName(1:10);
subID = fileName(21:25);

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

%%
frame = 1:size(tbl,1);
x = tbl.x;
y = tbl.y;
likelihood = tbl.likelihood;

% adjust by calibration
x = x .* calibrate.scale;
y = y .* calibrate.scale;

% cut to maximal video length
cut = maxVidLength*frameRate ;
x = x(1:floor(cut));
y = y(1:floor(cut));
frame = frame(1:floor(cut));
likelihood = likelihood(1:floor(cut));

%% Retain only valid coordinates

% 1) mask low likelihood coordinates
mask = likelihood < thresholdLikelihood;
x(mask) = nan;
y(mask) = nan;
belowThres = length(find(isnan(x)))/length(x); % save how many were below threshold

% 2) trim frames where either x or y are missing at edges
validX = ~isnan(x);
validY = ~isnan(y);
firstIdx = max(find(validX,1,'first'), find(validY,1,'first'));
lastIdx  = min(find(validX,1,'last'),  find(validY,1,'last'));

% If no valid frames remain, return empty outputs
if isempty(firstIdx) || isempty(lastIdx) || firstIdx > lastIdx
    x = []; y = [];
    frame = frame([]);
    distance = [];
    totDist = 0;
    return
else
    x = x(firstIdx:lastIdx);
    y = y(firstIdx:lastIdx);
    frame = frame(firstIdx:lastIdx);
end

% 3) Interpolate missing values (linear). If endpoints are NaN, use nearest extrapolation.
n = numel(x);
idx = (1:n).';
valid = ~isnan(x);
if any(valid)
    x(~valid) = interp1(idx(valid), x(valid), idx(~valid), 'linear', 'extrap');
else
    x(:) = NaN;
end
valid = ~isnan(y);
if any(valid)
    y(~valid) = interp1(idx(valid), y(valid), idx(~valid), 'linear', 'extrap');
else
    y(:) = NaN;
end

%% Distance

% compute frame-to-frame distance and remove leading/trailing NaNs
distance = hypot(diff(x), diff(y));

% Remove NaNs at edges (if any)
validD = ~isnan(distance);
if any(validD)
    distance = distance(find(validD,1,'first') : find(validD,1,'last'));
else
    distance = [];
end
% interpolate any remaining NaNs in distance
m = numel(distance);
if m>0
    idxD = (1:m).';
    valid = ~isnan(distance);
    if any(valid)
        distance(~valid) = interp1(idxD(valid), distance(valid), idxD(~valid), 'linear', 'extrap');
    else
        distance(:) = 0;
    end
end

% total distance (scaled)
totDist = sum(distance, 'omitnan') * calibrate.scale;

% by bins
binSec = 1*60;
framesPerBin = frameRate * binSec;  % number of frames in 5 min bin
% assign each distance sample to a bin (1-based)
binIdx = ceil((1:numel(distance)) / framesPerBin).';
% sum distances per bin
numBins = max(binIdx);
distPerBin = accumarray(binIdx, distance, [numBins, 1], @sum, 0);  % cm per bin
% adjust for bin size and make time vector
distPerBin = distPerBin / binSec;
timeBin = ((0:numBins-1) * binSec) / 60;
timeBin = timeBin - 10;

%% Normalize x and y coordinates and save as .csv for heatmapping
% Nx = normalize(x,'range');
% Ny = normalize(y,'range');
% normData = [frame, Nx, Ny];
% S1 = subID;
% S1 = char(S1);
% S2 = '_norm';
% normName = sprintf('%s%s.csv',S1,S2);
% csvwrite(normName, normData);

%% Plot individual animal tracks to normalized space
fig = figure; theme(fig, 'light');
subplot(1,2,1);
plot(x, y, "ob", LineWidth=2);
axis equal; axis square;
set(gca,'ydir','reverse');
title(subID,'FontSize',20)
% saveAs=fullfile(filePath,[subID, date, '.png']);
% saveas(gcf, saveAs);

subplot(1,2,2); hold on
xline(0,'LineWidth',1.5);
plot(timeBin, distPerBin, 'o-');
axis square;
xlabel('Time (min)'); ylabel('Distance (cm per 5 min)');
title('Distance Travelled)')

%% Save Results to .mat structure
beh = struct;
beh.calibrate = calibrate;
beh.filePath = filePath;
beh.fileName = fileName;
beh.distance = distance;
beh.totalDist = totDist;
beh.binSize = binSec;
beh.binTime = timeBin;
beh.binDist = distPerBin;
beh.belowThres = belowThres;
mat_suffix = '.mat';
matFile = fullfile(filePath, [subID date mat_suffix]);
save(matFile,'beh');