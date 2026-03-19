%% Calibrate distance measurements based on image from video file

% import the video file (.mp4)
[fileName,filePath] = uigetfile('*.mp4','Select the VIDEO file','MultiSelect','on');
[~,name,ext] = fileparts(fileName);

% import the video file and save first frame as image
cd(filePath);  
obj = VideoReader(fileName);
im = read(obj,1);
imwrite(im, name, 'png');

% read image into the workspace
assert(exist(name,'file')==2, '%s does not exist.', name);
im = imread(name);

% obtain data from image
sz = size(im);
myData.Units = 'pixels';
myData.MaxValue = hypot(sz(1),sz(2));
myData.Colormap = hot;
myData.ScaleFactor = 1;

% obtain center and size
[centerPixel, boxPixel] = selectCenterAndScale(im);
fprintf('Rectangle: [%.1f %.1f %.1f %.1f]\nLine length: %.1f pixels\n', centerPixel, boxPixel);
xLo = centerPixel(1);
xHi = centerPixel(1) + centerPixel(3);
yLo = centerPixel(2);
yHi = centerPixel(2) + centerPixel(4);

% convert to size
answer = inputdlg({'Pixel Width of Box','Known width in cm'},...
        'Specify known distance',[1 20],{num2str(boxPixel),'40'});
pix = str2double(answer{1});
cm = str2double(answer{2});
scale = cm/pix;
calibrate.filePath = filePath;
calibrate.fileName = fileName;
calibrate.frameRate = obj.FrameRate;
% calibrate.video = obj; % dont save large file
calibrate.image = im; % .png single frame image
calibrate.size = sz;
calibrate.centerLoc = {xLo, yLo; xHi, yHi};
calibrate.Units = 'centimeters';
calibrate.scale = scale;
save('OFCalibration.mat','calibrate');