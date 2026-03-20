function [x, y, theta] = rotateOpenField(x, y, theta)
% rotateOpenField
%
% Description: rotate open-field X, Y coordinates around a center point.
%
% INPUTS: 
%   x, y - column vectors with normalized X, Y coordinates
%       (output from processOpenField)
%   theta - in degrees
%
% Anya Krok, March 2026

%%
ans = inputdlg('Angle (in degrees)',...
    'Input', [1 40], {num2str(theta)});
theta = str2num(ans{1});

fig = figure; theme(fig, 'light');
while ~isempty(theta)

    thetaRad = deg2rad(theta);
    R = [cos(thetaRad) -sin(thetaRad); sin(thetaRad) cos(thetaRad)];
    cx = 0.5; cy = 0.5;              % center of rotation
    XY = [x(:)-cx, y(:)-cy] * R.'; % translate, rotate
    xr = XY(:,1) + cx;
    yr = XY(:,2) + cy;
    
    subplot(1,2,1); hold off
    s = scatter(x, y, 20, 'filled'); s.MarkerFaceAlpha = 0.2; 
    axis equal; axis square; xlim([0 1]); ylim([0 1]);
    set(gca,'ydir','reverse');
    title('original');
    subplot(1,2,2); hold off
    s = scatter(xr, yr, 20, 'filled'); s.MarkerFaceAlpha = 0.2; 
    axis equal; axis square; xlim([0 1]); ylim([0 1]);
    set(gca,'ydir','reverse');
    title(sprintf('rotation: %1.1f',theta));

    ans = inputdlg('Angle (in degrees). LEAVE BLANK IF DONE.',...
    'Input', [1 50], {num2str(theta)});
    theta = str2num(ans{1});

end
close(fig);
theta = rad2deg(thetaRad);
fprintf('Rotation angle: %1.1f degrees \n', theta);