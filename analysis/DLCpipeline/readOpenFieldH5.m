function data = readOpenFieldH5(varargin)
% This function will extract coordinates from .h5 file, which is output
% from DLC tracking pipeline.
%
% Syntax:
%   data = readOpenFieldH5();
%   data = readOpenFieldH5(fileName, filePath);
%
% Anya Krok, March 2026

% Parse input arguments for file name and path
if nargin > 0
    fileName = varargin{1};
    filePath = varargin{2};
    h5 = h5read(fullfile(filePath, fileName));
else
    error('File name and path must be provided.');
end

idx = double(h5.Groups.Datasets.Value.index);
mat = double(h5.Groups.Datasets.Value.values_block_0)';
