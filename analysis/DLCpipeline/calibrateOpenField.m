%% Calibrate distance measurements based on image from video file

% import the video file (.mp4)
[fileName,filePath] = uigetfile({'*.mp4;*.png','files (*.mp4, *.png)'},'Select the VIDEO file');
[~,name,type] = fileparts(fileName);
cd(filePath);
switch type
    case '.mp4'
        % import the video file and save first frame as image
        obj = VideoReader(fileName);
        im = read(obj,1);
        imwrite(im, name, 'png');
        
        % read image into the workspace
        assert(exist(name,'file')==2, '%s does not exist.', name);
        im = imread(name);
end

% obtain data from image
sz = size(im);
% myData.Units = 'pixels';
% myData.MaxValue = hypot(sz(1),sz(2));
% myData.Colormap = hot;
% myData.ScaleFactor = 1;

% obtain center and size
[centerPixel, boxPixel] = selectCenterAndScale(im);
fprintf('Rectangle: [%.1f %.1f %.1f %.1f]\nLine length: %.1f pixels\n', centerPixel, boxPixel);
xLo = centerPixel(1);
xHi = centerPixel(1) + centerPixel(3);
yLo = centerPixel(2);
yHi = centerPixel(2) + centerPixel(4);

% calculate scaling based on pixel width of box
answer = inputdlg({'Pixel Width of Box','Known width in cm'},...
        'Specify known distance',[1 20],{num2str(boxPixel),'40'});
pix = str2double(answer{1});
cm = str2double(answer{2});
scale = cm/pix;

% output structure
mouseID = fileName(1:5); % extract mouse ID
date = fileName(8:15); date = erase(date,'-'); % extract date
calibrate.mouseID = mouseID; 
calibrate.date = date;
calibrate.filePath = filePath;
calibrate.fileName = fileName;
calibrate.frameRate = 30; % obj.FrameRate;
% calibrate.video = obj;
calibrate.image  = im; % .png single frame image
calibrate.size   = sz; % size of image, in pixels
calibrate.center = [xLo, yLo; xHi, yHi]; % corners of center box, in pixels
calibrate.width  = pix; % width, in pixels
calibrate.scale  = scale; % scaling factor
calibrate.units  = 'cm';

mouseID = fileName(1:5); % extract mouse ID
date = fileName(8:15); date = erase(date,'-'); % extract date
save([mouseID,'-',date,'_OFcalibration.mat'],'calibrate');