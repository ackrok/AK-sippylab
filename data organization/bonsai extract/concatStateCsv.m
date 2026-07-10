function [] = concatStateCsv(varargin)
%%Concatenate multiple 'StateTransitions.csv' files in event of crash
%
% [] = concatStateCsv();
%
% Description: Concatenate multiple 'statetrans' .csv files, using multiple
% recordings from the same day for same animal.
% USE CASE is when Bonsai crashes and re-start recording
%
% INPUTS
%   'fPath' - Select folder with behavioral data in popup window.
%       for a single mouse, navigate to Behavior folder
%       select ONE folders that contains Bonsai behavioral data
%       eg '251205 - Task1', which has duplicate .csv files
%
%   IMPORTANT -- sub-folder within these folder must contain
%       StateTransitions.csv to work properly
%
% OUPUTS
%   '' - returns concatenated .csv file into folder
%
% Written by Anya Krok, February 2026

%%
[filePath] = uigetdir2; % Essentially multiselect directories, returns filePath in cell array

%%
for a = 1:length(filePath)
    tic
    thisPath = filePath{a};
    cd(thisPath);
    d = dir("*.csv");                      % list csv files
    filesCsv = string({d.name})';          % string array of names
    fileBeh = filesCsv(contains(filesCsv,'StateTrans'));
    T = readtable(fileBeh, 'VariableNamingRule', 'preserve');
    if isempty(T); continue; end

    % extract column 'Item2.Trial' or 'Trial' from table T into vector vals
    cands = {'Item2.Trial','Trial'};
    vn = cands(find(ismember(cands, T.Properties.VariableNames), 1));
    if isempty(vn)
        error('Neither ''Item2.Trial'' nor ''Trial'' found in table T.');
    end
    trials = T{:, vn};          % contents of entire column
    trials = trials(:);         % ensure column vector

    if T.(vn{1})(1) == 0
        T.(vn{1}) = T.(vn{1}) + 1; % zero-index to one-index
    end

    % concatenate
    if a == 1
        Tall = T;
    elseif a > 1
        lastTrial = T.(vn{1})(end); % last trial number for concatenated table
        T.(vn{1}) = T.(vn{1}) + lastTrial;
        Tall = [Tall; T];
    end

    % % remove last trial if does not meet parameters
    % lastAct = T.("Item2.Id")(end); lastAct = lastAct{1};
    % opts = {'Hit','LeftHit','RightHit','Miss','IncorrectAction','Timeout'};
    % lastTrial = T.("Item2.Trial")(end); % last tria; number
    % if ~any(ismember(opts, lastAct))
    %     T(T.("Item2.Trial") == lastTrial, :) = []; % remove last trial
    % end
    % if isempty(T); continue; end
    toc
    fprintf('Table %d of %d concatenated \n',a,length(filePath));
end

%% MOVE OLD FOLDERS
[~,b] = strtok(fliplr(filePath{1}), '/');
parentFolder = fliplr(b); % parent folder
newFolderName = 'archived_folders'; % name for new folder
cd(parentFolder)
newArchivePath = fullfile(parentFolder, newFolderName);
mkdir(parentFolder, newFolderName); % create new folder within parent
subfolderNames = cell(length(filePath),1); % empty cell array
for a = 1:length(filePath)
    subfolderNames{a} = fliplr(strtok(fliplr(filePath{a}), '/'));
end

% Move each subfolder into the new folder (defensive against name conflicts)
for k = 1:numel(subfolderNames)
    tic
    src = fullfile(parentFolder, subfolderNames{k});
    dest = fullfile(newArchivePath, subfolderNames{k});
    if isfolder(dest)
        % destination exists — choose a unique name by appending suffix
        suffix = 1;
        while isfolder(fullfile(newArchivePath, sprintf('%s_%d', subfolderNames{k}, suffix)))
            suffix = suffix + 1;
        end
        dest = fullfile(newArchivePath, sprintf('%s_%d', subfolderNames{k}, suffix));
    end
    % move
    [status, msg, msgID] = movefile(src, dest);
    if ~status
        warning('Failed to move "%s": %s (%s)', src, msg, msgID);
    end
    toc
    fprintf('Moved folders into "archived_folders" - %d of %d \n',k,numel(subfolderNames));
end

% Create new folder within parent
mkdir(parentFolder, subfolderNames{end}); % create new folder, using most recent folder name
newDataPath = fullfile(parentFolder, subfolderNames{end});
cd(newDataPath); % open new folder

% Move archive into this new folder
[status, msg, msgID] = movefile(newArchivePath, newDataPath);
if ~status
    error('Failed to move folder: %s (%s)', msg, msgID);
end

%% WRITE NEW .CSV INTO EMPTY FOLDER
writetable(Tall, "StateTransitions.csv"); % SAVE FILE

end