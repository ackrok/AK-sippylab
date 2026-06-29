function comb = extractComb_beh(varargin)
%%Extract behavioral data from multiple recordings into a single
%%structure for further analysis
%
% [comb] = extractComb_beh();
% [comb] = extractComb_beh(comb);
%
% Description: Extract behavioral data from multiple recording files into 
% a larger structure to be used for further analysis. Only extracts
% behavioral data
%
% INPUTS
%   'fPath' - Select folder with behavioral data in popup window.
%       for a single mouse, navigate to Behavior folder
%       select multiple folders that contain Bonsai behavioral data
%       eg '251205 - Task1', '251208 - Task2', '231210 - Task3'
%   IMPORTANT -- sub-folder within these folder must contain
%       StateTransitions.csv to work properly
%
% OUPUTS
%   'comb' - Structure with data from multiple recordings
%
% Updated by Anya Krok, December 2025

%%
switch nargin
    case 1
        comb = varargin{1}; % If comb is provided, use it to store data
    case 0
        comb = struct; % Initiate structure to store data such that works with other plotting scripts
end

%%
fprintf('Select folder(s) with Bonsai behavioral data in pop-up window.\n');
[filePath] = uigetdir2; % Essentially multiselect directories, returns filePath in cell array

%%
for a = 1:length(filePath)
    tic
    thisPath = filePath{a};
    cd(thisPath);
    fileBeh = dir('State*.csv'); % check for .csv files starting with "State'
    if isempty(fileBeh)
        tmp = dir(thisPath);
        if isempty([tmp.isdir])
            error('ERROR: no files or folder in this directory.')
        end
        thisPathSubfolders = {tmp.name};
        idx = find(strlength(thisPathSubfolders)>9); % if folder name starts with YYYY-MM-DD, should be at least 9 characters long
        if length(idx) > 1
            choice = menu('Select sub-folder with data (can open it in Finder to confirm).',thisPathSubfolders);
            idx = thisPathSubfolders{choice}; 
        end
        cd(fullfile(thisPath, thisPathSubfolders{idx}));
        d = dir("*.csv");                      % list csv files
        filesCsv = string({d.name})';          % string array of names
        fileBeh = filesCsv(contains(filesCsv,'StateTrans'));
        % fileBeh = dir('State*.csv'); % check for .csv files starting with "State'
    end
    
    %% 2AFC task
    if ~isempty(dir('State*.csv')) % if directory contains file StateTransitions.csv
        fileBeh = dir('State*.csv');
        statetrans = GetBonsai_Pho_StateTransitions_Celeste(fileBeh.name);
        if statetrans.Trial(1) == 0 % Adjust for zero index
            statetrans.Trial = statetrans.Trial + 1;
        end
        beh = extract2AFCdataAK(statetrans);
    end

    %% Go NoGo task
    if isempty(dir('State*.csv')) & ~isempty(fileBeh)
        fileBeh = filesCsv(contains(filesCsv,'StateTrans'));
        opts = delimitedTextImportOptions("NumVariables", 4);
        opts.DataLines = [2, Inf];
        opts.Delimiter = ",";
        opts.VariableNames = ["Trial", "Id", "ElapsedTime"];
        opts.SelectedVariableNames = ["Trial", "Id", "ElapsedTime"];
        opts.VariableTypes = ["double", "categorical", "double"];
        opts.ExtraColumnsRule = "ignore"; % Specify file level properties
        opts.EmptyLineRule = "read"; % Specify file level properties
        opts = setvaropts(opts, "Id", "EmptyFieldRule", "auto"); % Specify variable properties
        statetrans = readtable(fileBeh, opts); % Import the data
        if any(statetrans.Id == 'Joystick')
            statetrans.Id = renamecats(statetrans.Id,"Joystick","Lick"); % Fix error in logging Lick as Joystick
        end
        if statetrans.Trial(1) == 0 % Adjust for zero index
            statetrans.Trial = statetrans.Trial + 1;  % change to one-index
        end
        beh = extractGoNoGodataAK(statetrans);
    end

%% STORE
    str = thisPath; % string with file path
    mouse = regexp(str, 'JT0\d{2}', 'match', 'once'); % extract JT followed by 0 and two digits (e.g. JT019)
    date = regexp(str, '\d{6}', 'match', 'once'); % extract any sequence of exactly six digits (e.g. 251215)

    b = size(comb,2); if isempty(fieldnames(comb)); b = 0; end
    comb(b+1).mouse = mouse; 
    comb(b+1).date  = date;
    comb(b+1).Fs    = 50;
    comb(b+1).beh   = beh; % Store behavioral data in the structure
    toc
    fprintf('Extracted behavioral data for: %s-%s \n',mouse,date);
end