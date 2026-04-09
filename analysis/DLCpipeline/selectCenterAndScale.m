function [centerPixel, linePixel] = selectCenterAndScale(img)
% selectCenterAndScale  
% 
% Description: using image generated from first frame of open-field video 
% file pre-processed in DLC or SLEAP, prompt user to identify CENTER as a
% rectangular box and LENGTH with a line to measure length in pixels.
%
% [centerPixel, linePixel] = selectCenterAndScale(img);
%
% Inputs:
%   img        - image matrix (MxNx[1|3])
% Outputs:
%   centerPixel - 1x4 vector [xmin ymin width height] for center rectangle
%   linePixel   - scalar, length of the drawn line in pixels
%
% Anya Krok, March 2026
% adapted from Sarah Mennenga code
%%
% Display image
hFig = figure('Name','Draw Center Rectangle then One Line','NumberTitle','off');
hAx = axes(hFig);
imshow(img, 'Parent', hAx);
title(hAx, 'Draw a rectangle labeled "Center", double-click or press Enter to finish');

% Draw rectangle (red) and wait until user finalizes it
hRect = drawrectangle(hAx, 'Color', [1 0 0], 'Label', 'Center');
% wait for the ROI to be finished (double-click or Enter). R2018b+ supports wait.
wait(hRect);

% Get rectangle position
centerPixel = hRect.Position;   % [xmin ymin width height]

% Prompt user to draw a single blue line
title(hAx, 'Now draw ONE line (click-drag), release or double-click to finish');
hLine = drawline(hAx, 'Color', [0 0 1]);
wait(hLine);   % wait until user finishes interaction

% Get line endpoints and compute length
linePos = hLine.Position;   % 2x2 matrix: [x1 y1; x2 y2]
dx = diff(linePos(:,1));
dy = diff(linePos(:,2));
linePixel = hypot(dx, dy); % pixels

% Cleanup UI callback and leave figure open (or close if desired)
title(hAx, sprintf('Done: Rect=[%.1f %.1f %.1f %.1f], Line=%.1f px', centerPixel, linePixel));

% Close the figure after displaying the results
close(hFig);
end