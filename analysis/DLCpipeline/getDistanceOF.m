function beh = getDistanceOF(x, y, likelihood)
% This function will use DLC output, scaled to cm, to calculate locomotion 
% metrics from valid coordinates.
%
% Syntax:
%   beh = getDistanceOF(x, y, likelihood);
%
% Inputs:
%   x - x coordinate, in cm (vector)
%   y - y coordinate, in cm (vector)
%   likelihood - confidence (vector)
%
% Outputs:
%   beh - structure with outputs
%
%       beh.coorCm - x, y coordinates, in cm       (vector, nFrames x 1)
%       beh.coor   - x, y coordinates, normalized  (vector, nFrames x 1)
%       beh.validPrc  - proportion of x, y above likelihood threshold
%       beh.distance  - frame-to-frame distance, in cm  (vector, nFrames-1 x 1)
%       beh.totalDist - total distance travelled, in cm (scaler)
%       beh.binSize   - bin size, in minutes (scalar)
%       beh.binDist   - distance travelled in X minute bins (vector)
%       beh.binTime   - time vector for plotting binDist    (vector)
%           > nBins = nFrames / (frameRate * binSize * 60)
%
% Defaults:
%   threshold - 0.9
%   frameRate - 30 Hz
%   binSize   - 1 minute
%
% Written by Anya Krok, March 2026
% 

%%
x = x(:); 
y = y(:);
likelihood = likelihood(:);
coor = [x, y];
frame = (1:numel(x)).';

%% parameters
frameRate = 30; % in Hz
threshold = 0.9; % cutoff for low-likelihood values
binSize = 1; % in minutes, for analyzing locomotion in X min bins

%% Retain only valid coordinates
% mask low-likelihood coordinates, replace values with NaN
mask = likelihood < threshold;
coor(mask,:) = nan;

% return percentage of frames that were above threshold
n = length(coor);
valid = ~isnan(coor(:,1));
validPrc = length(find(valid))/n; % save proportion of valid coordinates

% interpolate missing values
% note if endpoints are NaN, use nearest extrapolation.
idx = (1:n).'; 
if any(valid)
    coor(~valid,:) = interp1(idx(valid), coor(valid,:), idx(~valid), 'linear', 'extrap');
    else, coor(:) = NaN;
end

%% Frame-to-frame distance
x = coor(:,1); 
y = coor(:,2);
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
% binSize = 1; % minutes <-- coded above
binSec = binSize*60;                % seconds per bin
framesPerBin = frameRate * binSec;  % frames in bin
numBins = (numel(x)/frameRate)/binSec; % number of bins
numBins = ceil(numBins);               % ensure integer
% assign each frame to a bin (1-based), clamp to numBins
binIdx = min(ceil((1:numel(distance)).' ./ framesPerBin), numBins);
% sum distances per bin --> total cm per X-minute bin
distPerBin = accumarray(binIdx, distance(:), [numBins, 1], @sum, 0); % cm per bin
% time vector: bin start times
timeBin = (0:numBins-1).' * binSize;

%% Normalize x and y coordinates
Nx = normalize(x,'range');
Ny = normalize(y,'range');

%% Output
beh = struct;
beh.mouseID  = []; % to be filled later
beh.date     = []; % to be filled later
beh.coorCm   = [x, y];
beh.coor     = [Nx, Ny];
beh.validPrc = validPrc;
beh.distance  = distance(:);
beh.totalDist = totDist;
beh.binSize = binSize; % in minutes
beh.binTime = timeBin(:); % in minutes
beh.binDist = distPerBin(:);

end