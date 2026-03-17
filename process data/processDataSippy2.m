% Process data from Neurophotometrics and Bonsai output into .mat file.
% For EACH animal, select MULTIPLE folders with data across multiple days
% for processing.
%
% processDataSippy2
%
% INPUT
% (1) Select MULTIPLE folders that contain .csv data
%
% (2) Select signal in each photometry channel
%       *note two separate pop-up windows for green and red channels*
%
% (3) (optional) Select folder to save .mat files for cohort
%
% (4) Check recording identifyers for EACH recording
%
%
% OUTPUT
% 'data' structure is saved as .mat in same folder as .csv file(s) for each
% recording
%
% Written by: Anya Krok, July 2026
%

%% Select MULTIPLE folders with data files
[allPath] = uigetdir2; % Essentially multiselect directories, returns filePath in cell array

%% photometry signal
opts = {'DA','5-HT','NE','GCaMP'};
choice = menu('Select photometry signal for green channel',opts);
sigGreen = opts{choice};

opts = {'rDA','RCaMP'};
choice = menu('Select photometry signal for red channel',opts);
sigRed = opts{choice};

opts = {'yes','no'};
saveCohort = menu('Save to cohort folder?',opts);
if saveCohort == 1
    [cohortFilePath] = uigetdir([],'Select Cohort Folder'); 
end

%%
for a = 1:length(allPath)
    tic
    filePath = allPath{a};
    cd(filePath);
    fileBeh = dir('State*.csv'); % check for .csv files starting with "State..."
    filePhoto = dir('Photo*.csv'); % check for .csv files starting with "Photo..."
    fileFrames = dir('Frames*.csv'); 
    c = 0;
    while isempty(fileFrames)
        tmp = dir(filePath);
        if isempty([tmp.isdir])
            error('ERROR: no files or folder in this directory.')
        end
        thisPathSubfolders = {tmp.name};
        idx = find(strlength(thisPathSubfolders)>9); % if folder name starts with YYYY-MM-DD, should be at least 9 characters long
        if length(idx) > 1
            choice = menu('Select sub-folder with data (can open it in Finder to confirm).',thisPathSubfolders);
            idx = thisPathSubfolders{choice}; 
        end
        cd(fullfile(filePath, thisPathSubfolders{idx}));
        fileBeh = dir('State*.csv'); % check for .csv files starting with "State'
        filePhoto = dir('Photo*.csv'); % check for .csv files starting with "Photo..."
        fileFrames = dir('Frames*.csv'); 
        c = c + 1; % add to ticker
        if c > 3
            break % exit loop when count exceeds 3
        end
    end
    thisPath = pwd; % return current folder as string
    fprintf('Folder with .csv files identified...')
    
    %% convert fileName into mouse and date IDs
    str = thisPath; % string with file path
    try
        mouse = regexp(str, 'JT0\d{2}', 'match', 'once'); % extract JT followed by 0 and two digits (e.g. JT019)
        date = regexp(str, '\d{6}', 'match', 'once'); % extract any sequence of exactly six digits (e.g. 251215)
        ans = inputdlg({sprintf('%s \n\n\n Mouse ID:',str), 'Recording Date:'},...
            'Input', [1 40; 1 40], {mouse, date});
        mouse = ans{1}; date = ans{2};
    catch
        ans = inputdlg({sprintf('%s \n\n\n Mouse ID:',str), 'Recording Date:'},...
            'Input', [1 40; 1 40], {'JT0XX','YYMMDD'});
        mouse = ans{1}; date = ans{2};
    end
    dayName = sprintf('%s-%s',mouse,date);

    %% create data structure
    data = struct;
    data.ID = dayName; 
    data.mouse = mouse; 
    data.date = date;

    %% extract data into workspace
    frames = table2array(GetBonsai_PhotometryFrames(fileFrames.name));
    % photometry
    try photoT = GetBonsai_Photometry(filePhoto.name);
    catch photoT = [];
    end
    % behavior
    try statetrans = GetBonsai_Pho_StateTransitions_Celeste(fileBeh.name);
    catch statetrans = [];
    end

    fprintf('Extracted data from .csv files...');

    %% extract into 'data' structure
    % beh = extract2AFCdataAK(statetrans);
    data = extractDataFromCsv(data, frames, photoT, statetrans);

    %% photometry signal names
    if ~isempty(photoT)
        FPnames = data.acq.FPnames;
        FPnames{1} = sigGreen;
        if data.acq.nFPchan > 1
            FPnames{2} = sigRed;
        end
        data.acq.FPnames = FPnames;
        data.final.FPnames = FPnames;
    end

    %% save file in same folder where .csv files are located
    saveName = sprintf('%s-%s_data.mat',data.mouse,data.date);
    save(saveName,'data');
    fprintf(' %s: SAVED data.mat \n', data.ID);
    if saveCohort == 1
        save(fullfile(cohortFilePath,saveName),'data'); % save to cohort folder
    end
    toc
end