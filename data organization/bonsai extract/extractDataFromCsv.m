function data = extractDataFromCsv(data, frames, photoT, statetrans)

% data = extractDataFromCsv(data, frames, photoT, statetrans)
%
% INPUTS
% fileBeh    = dir('State*.csv'); % check for .csv files starting with "State'
% statetrans = GetBonsai_Pho_StateTransitions_Celeste(fileBeh.name);
%
% fileFrames = dir('Frames*.csv'); 
% frames     = table2array(GetBonsai_PhotometryFrames(fileFrames.name));
% 
% filePhoto = dir('Photo*.csv'); % check for .csv files starting with "Photo..."
% photoT    = GetBonsai_Photometry(filePhoto.name);
%
% Anya Krok, December 2025

%%
fprintf('\n%s: processing bonsai data...\n',data.ID);
%% EXTRACT PHOTOMETRY DATA
fprintf('    Photometry: ')
% Only runs if photometry data is present in table format as an input and
% 'frames' is present
if ~isempty(photoT) && istable(photoT) && ~isempty(frames)

    %%
    % detect photometry columns (same logic as before)
    opts = table2array(photoT(1,5:end));
    idx = find(~isnan(opts)) + 4;  % absolute table column indices

    % build photo array (cols: 1:3 are meta, then photometry cols)
    photo = table2array(photoT(:, [1:3, idx]));

    % adjust time stamps to be ELAPSED time
    photo(:,2) = photo(:,2) - photo(1,2);

    % variable names for the photometry columns
    varNames = photoT.Properties.VariableNames(idx);

    % classify photometry headers into G and R, keep numeric order
    getNum = @(s) str2double(regexp(s,'\d+','match','once'));
    isG = startsWith(varNames,'G','IgnoreCase',true);
    isR = startsWith(varNames,'R','IgnoreCase',true);
    
    Gnames = varNames(isG);
    Rnames = varNames(isR);
    [~,ordG] = sort(cellfun(getNum,Gnames));
    [~,ordR] = sort(cellfun(getNum,Rnames));
    Gnames = Gnames(ordG);
    Rnames = Rnames(ordR);

    % time and LED state columns in photo
    timeCol = 2;
    ledCol = 3;

    % map varNames to photo column indices (photo has photometry cols starting at col 4)
    photStartCol = 4;
    nameToPhotoCol = containers.Map(varNames, num2cell(photStartCol:(photStartCol+numel(varNames)-1)));
    
    %%
    % build signalRaw: first all green channels, then all red channels
    signalRaw = {};
    % green channels (LED state for green assumed 2)
    ledStateG = 2; % which LED state we are drawing from, ledState 2 is 470nm
    for k = 1:numel(Gnames)
        col = nameToPhotoCol(Gnames{k});
        rows = photo(:,ledCol)==ledStateG;
        if any(rows)
            signalRaw{end+1} = photo(rows, [timeCol, col]); 
        else
            signalRaw{end+1} = []; 
        end
    end
    % red channels (LED state for red assumed 4)
    ledStateR = 4; % which LED state we are drawing from, ledState 4 is 565nm
    for k = 1:numel(Rnames)
        col = nameToPhotoCol(Rnames{k});
        rows = photo(:,ledCol)==ledStateR;
        if any(rows)
            signalRaw{end+1} = photo(rows, [timeCol, col]); 
        else
            signalRaw{end+1} = []; 
        end
    end

    %%
    % prompt for FP names with an input dialog (one entry per detected channel)
    nSignals = numel(signalRaw);
    prompt = cell(1,nSignals);
    default = cell(1,nSignals);
    for k = 1:nSignals
        if k <= numel(Gnames)
            chanLabel = Gnames{k};
            examples = 'eg, DA, 5-HT, NE, GCaMP';
        else
            chanLabel = Rnames{k - numel(Gnames)};
            examples = 'eg, rDA, RCaMP';
        end
        prompt{k} = sprintf('Label for %s (%s):', chanLabel, examples);
        default{k} = chanLabel; % draft from name (e.g., 'G0' or 'R2')
    end
    if ~isfield(data,'ID'), data.ID = [data.mouse,'-',data.date]; end
    answer = inputdlg(prompt, data.ID, 1, default);
    if isempty(answer)
        error('User cancelled FP label input.');
    end
    % trim and store responses
    data.acq.FPnames = strtrim(answer);

    % finalize acquisition fields
    data.acq.nFPchan = numel(data.acq.FPnames);
    
    % compute cutLength as largest multiple of 300 that fits all non-empty channels
    lengths = cellfun(@(c) size(c,1), signalRaw);
    lengths(lengths==0) = inf; % ignore empty channels for min computation
    minLen = min(lengths);
    if isinf(minLen)
        cutLength = 0;
    else
        cutLength = floor(minLen/300)*300;
    end
    
    % populate data.acq.time and data.acq.FP
    for ii = 1:data.acq.nFPchan
        if ~isempty(signalRaw{ii}) && cutLength>0
            data.acq.time{ii} = signalRaw{ii}(1:cutLength,1);
            data.acq.FP{ii}   = signalRaw{ii}(1:cutLength,2);
        else
            data.acq.time{ii} = [];
            data.acq.FP{ii}   = [];
        end
    end

    %%
    % compute acquisition rate
    fiberTS = data.acq.time{1};
    % fiberTS = data.acq.time{1}/1e3;  %in seconds - not starting at zero
    fiberTriggerBin = ((fiberTS(end-1,1)-fiberTS(1,1))/...
                        (length(fiberTS)-1)); %neurophotometrics acquisition rate
    acqFs = round (1 / fiberTriggerBin); % sampling rate
    data.gen.acqFs = acqFs;
    data.gen.acqSamp = numel(data.acq.FP{1});
    
    %%
    % process photometry data
    params = struct;
    params.FP.lpCut = 15; % Cut-off frequency for filter
    params.FP.filtOrder = 8; % Order of the filter
    params.dsRate = 1; params.dsType = 2; % 1 = Bin Summing; 2 = Bin Averaging;
    params.FP.interpType = 'linear'; params.FP.fitType = 'interp';
    params.FP.winSize = 10; params.FP.winOv = 0; params.FP.basePrc = 5;
    params.FP.software = 'bonsai';
    params.FP.acqType = 'alternate';
    data.gen.params = params;
    
    try [data] = processFP_NPM(data, data.gen.params);
    catch, fprintf('error processing. \n');
    end
    fprintf('DONE! \n');
else
    fprintf('no data found. \n');
end

%% extract behavior data
fprintf('    Behavior: ')
if ~isempty(statetrans) && istable(statetrans)
    if statetrans.Trial(1) == 0
        statetrans.Trial = statetrans.Trial + 1; % change zero- to one-index
    end
    try
        switch data.gen.behType
            case '2AFC'
                beh = extract2AFCdataAK(statetrans);
                data.beh = beh;
                data.acq.beh = statetrans;
                if ~isempty(photoT) && istable(photoT) || isfield(data,'final')
                    try
                        data = alignBehTStoPhotoTS(data); % frame relative to photometry signal    
                    catch, fprintf('error aligning behavior timeStamps to photometry timeStamps.\n')
                    end
                end
                fprintf('DONE!\n');
            case 'GoNoGo'
                beh = extractGoNoGodataAK(statetrans);
                data.beh = beh;
                data.acq.beh = statetrans;
                if ~isempty(photoT) && istable(photoT) || isfield(data,'final')
                    try
                        data = alignBehTStoPhotoTS_GoNoGo(data); % frame relative to photometry signal    
                    catch, fprintf('error aligning behavior timeStamps to photometry timeStamps.\n')
                    end
                end
                fprintf('DONE!\n');
        end
    catch, fprintf('error processing.');
    end
else
    data.beh = [];
    fprintf('no data found.\n');
end
