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
    % identify colums R0 - G15 that include photometry values
    idx = find(~isnan(table2array(photoT(1, 5:size(photoT,2))))); 
    % extract data colums that have photometry signal
    photo = table2array(photoT(:,[1:3, idx+4])); 
    photo(1:length(frames),2)=frames(:,2);
    
    % R0 - red 
    % R1 - green
    signalRaw = {};
    ledState = 2; % which LED state we are drawing from, ledState 2 is 470nm
    if any(photo(:,3) == ledState)
        signalRaw{1} = photo(photo(:,3)==ledState,[2,5]); 
    end
    ledState = 4; % which LED state we are drawing from, ledState 4 is 565nm
    if any(photo(:,3) == ledState)
        signalRaw{2} = photo(photo(:,3)==ledState,[2,4]); 
    end

    % select photometry 
    opts = {'DA','5-HT','NE','GCaMP'};
    choice = menu('Select photometry signal for green channel',opts);
    data.acq.FPnames = opts(choice);
    fprintf('green: %s. ',opts{choice});
    if any(photo(:,3) == 4) % if used 565nm 
        opts = {'rDA','RCaMP'};
        choice = menu('Select photometry signal for red channel',opts);
        data.acq.FPnames{2} = opts{choice};
        fprintf('red: %s. ',opts{choice});
    end
    data.acq.nFPchan = length(data.acq.FPnames);
    cutLength = floor(size(signalRaw{1},1)/300)*300;
    for ii = 1:data.acq.nFPchan
        data.acq.time{ii} = signalRaw{ii}(1:cutLength, 1);
        data.acq.FP{ii} = signalRaw{ii}(1:cutLength, 2);
    end
    
    % compute acquisition rate
    fiberTS = data.acq.time{1}/1e3;  %in seconds - not starting at zero
    fiberTriggerBin = ((fiberTS(end-1,1)-fiberTS(1,1))/...
                        (length(fiberTS)-1)); %neurophotometrics acquisition rate
    acqFs = round (1 / fiberTriggerBin); % sampling rate
    data.gen.acqFs = acqFs;

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
        if isfield(data,'acq') && isfield(data.acq,'time')
            beh = extract2AFCdataAK(statetrans,'photo'); % time stamps will be in bonsai computer time
        else
            beh = extract2AFCdataAK(statetrans); % time stamps will be elapsed time
        end
        data.beh = beh;
        data.acq.beh = statetrans;
        if ~isempty(photoT) && istable(photoT) || isfield(data,'final')
            try
                data = alignBehTStoPhotoTS(data); % frame relative to photometry signal    
            catch, fprintf('error aligning behavior timeStamps to photometry timeStamps.\n')
            end
        end
        fprintf('DONE!\n');
    catch
        fprintf('error processing.');
    end

else
    data.beh = [];
    fprintf('no data found.\n');
end
fprintf('\n');
