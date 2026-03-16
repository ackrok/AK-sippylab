function comb = extractComb_raw(varargin)
%%Extract raw photometry data from multiple recordings into a single
%%structure for FFT analysis with function getFft
%
% [comb] = extractComb_raw();
% [comb] = extractComb_raw(fName,fPath);
%
% Description: Extract raw photometry signal from multiple recording files 
% into a larger structure to be used for FFT analysis with function getFft
%
% INPUTS
%   'fPath' - Character array containing folder path where data files are
%       example: 'R:\tritsn01labspace\Anya\FiberPhotometry\AK201-206\220105'
%   'fName' - Cell array, with each cell containing file names for each
%   recording to be added to structure
%
% OUPUTS
%   'comb' - Structure with raw photometry signals from multiple recordings
%
% Originally written by Anya Krok, January 2022
% Adapted from extractRaw_fft() initially used with Tritsch Lab data
% Updated by Anya Krok, December 2025
%
%% INPUTS
switch nargin
    case 0
        fprintf('Select .mat files that contain raw photometry data. \n');
        [fName,fPath] = uigetfile('*.mat','Select the DATA files','MultiSelect','on');
    case 2
        fName = varargin{1}; 
        filePath = varargin{2};
        if ~iscell(fName); fName = {fName}; end
end
    
%% Extract data
comb = struct;
h = waitbar(0, 'Extracting raw photometry signals into structure');
for f = 1:length(fName)
    fprintf('Extracting raw photometry data %s ... ',fName{f});
    load(fullfile(fPath,fName{f})); % Load raw data file

    x = size(comb,2)+1; if isempty(fieldnames(comb)); x = 1; end
    comb(x).mouse = data.mouse; comb(x).date = data.date;
    comb(x).rec = data.ID;
    
    %% Pull parameters required for this analysis
    if isfield(data.gen,'params')
        params = data.gen.params; % Extract params structure
        dsRate = params.dsRate; 
        dsType = params.dsType; % General downsampling parameter
        rawFs = data.gen.acqFs; 
        Fs = data.gen.Fs;
    else
        error('No parameters saved during processData');
    end
    
    %% Extract photometry and behavior data
    comb(x).FPnames = data.acq.FPnames;
    comb(x).FP = data.acq.FP;
    comb(x).Fs = rawFs;
    fprintf('DONE.\n');
    waitbar(f/length(fName),h);
    
end
close(h);
    
end
