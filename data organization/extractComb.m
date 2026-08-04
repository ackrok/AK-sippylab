function comb = extractComb(varargin)
%%Extract processed photometry data from multiple recordings into a single
%%structure for further analysis
%
% [comb] = extractComb();
% [comb] = extractComb(fName,fPath);
%
% Description: Extract processed data from multiple recording 
% files into a larger structure to be used for further analysis
%
% INPUTS
%   'fPath' - Character array containing folder path where data files are
%       example: 'R:\tritsn01labspace\Anya\FiberPhotometry\AK201-206\220105'
%   'fName' - Cell array, with each cell containing file names for each
%   recording to be added to structure
%
% OUPUTS
%   'comb' - Structure with data from multiple recordings
%
% Updated by Anya Krok, December 2025

%% INPUTS
switch nargin
    case 0
        [fileName,filePath] = uigetfile('*.mat','Select the DATA files','MultiSelect','on');
        if ~iscell(fileName); fileName = {fileName}; end
    case 2
        fileName = varargin{1}; 
        filePath = varargin{2};
        if ~iscell(fileName); fileName = {fileName}; end
end
fileName = sort(fileName);
    
%% Extract data
comb = struct; % Initialize

for a = 1:length(fileName)
    fprintf('%d of %d...',a,length(fileName));
    tic
    load(fullfile(filePath, fileName{a}),'data'); % load each .mat file
    beh = extractGoNoGodataAK(data.acq.beh);
    data.beh = beh;
    save(fullfile(filePath, fileName{a}),'data');
    comb = addDataComb(comb, data);
    try
        if ~isinteger(data.beh.trial.ledOn(1))
            if isfield(data,'acq')
                data.beh = extract2AFCdataAK(data.acq.beh);
                comb(a).beh = data.beh;
            end
        end
    catch
    end
    toc
end
fprintf('SAVED comb.mat in filePath \n');