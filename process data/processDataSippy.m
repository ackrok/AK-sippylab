
% selectDir = uigetdir('Select Directory with Photometry files'); % pop-up window to select file directory
[~,filePath] = uigetfile('Photometry*.csv','Select photometry CSV file','MultiSelect','off');
cd(filePath);  % open file directory

%%
try
    mouse = regexp(filePath, 'JT0\d{2}', 'match', 'once'); % extract JT followed by 0 and two digits (e.g. JT019)
    date = regexp(filePath, '\d{6}', 'match', 'once'); % extract any sequence of exactly six digits (e.g. 251215)
    ans = inputdlg({sprintf('%s \n\n\n Mouse ID:',filePath), 'Recording Date:'},...
        'Input', [1 40; 1 40], {mouse, date});
    mouse = ans{1}; date = ans{2};
catch
    ans = inputdlg({sprintf('%s \n\n\n Mouse ID:',filePath), 'Recording Date:'},...
        'Input', [1 40; 1 40], {'JT0XX','YYMMDD'});
    mouse = ans{1}; date = ans{2};
end
dayName = sprintf('%s-%s',mouse,date);

%% extract photometry data
tic
FramesFile=dir('Frames*.csv'); 
Frames=table2array(GetBonsai_PhotometryFrames(FramesFile.name));

File=dir('*Photometry_*.csv');
RawTable=GetBonsai_Photometry(File.name);
pull = find(~isnan(table2array(RawTable(1, 5:size(RawTable,2))))); % identify colums R0 - G15 that include photometry values
PhotometryTable=table2array(RawTable(:,[1:3, pull+4])); % extract data colums that have photometry signal
PhotometryTable(1:length(Frames),2)=Frames(:,2);
toc

%% G0 - red 
% R1 - green
clearvars signalRaw
ledState = 2; % which LED state we are drawing from, ledState 2 is 470nm
if any(PhotometryTable(:,3) == ledState)
    % signalRaw_grn = PhotometryTable(PhotometryTable(:,3)==ledState,[2,5]); 
    signalRaw{1} = PhotometryTable(PhotometryTable(:,3)==ledState,[2,5]); 
end
ledState = 4; % which LED state we are drawing from, ledState 4 is 565nm
if any(PhotometryTable(:,3) == ledState)
    % signalRaw_red = PhotometryTable(PhotometryTable(:,3)==ledState,[2,4]); 
    signalRaw{2} = PhotometryTable(PhotometryTable(:,3)==ledState,[2,4]); 
end

%% create data structure
data = struct;
data.ID = dayName; data.mouse = mouse; data.date = date;
opts = {'DA','5-HT','NE','GCaMP'};
choice = menu('Select photometry signal for green channel',opts);
data.acq.FPnames = {opts{choice}};
if any(PhotometryTable(:,3) == 4) % if used 565nm 
    opts = {'rDA','RCaMP'};
    choice = menu('Select photometry signal for red channel',opts);
    data.acq.FPnames{2} = opts{choice};
end
data.acq.nFPchan = length(data.acq.FPnames);
cutLength = floor(size(signalRaw{1},1)/300)*300;
for a = 1:data.acq.nFPchan
    data.acq.time{a} = signalRaw{a}(1:cutLength, 1);
    data.acq.FP{a} = signalRaw{a}(1:cutLength, 2);
end

fiberTS = data.acq.time{1}/1e3;  %in seconds - not starting at zero
fiberTriggerBin = ((fiberTS(end-1,1)-fiberTS(1,1))/...
                    (length(fiberTS)-1)); %neurophotometrics acquisition rate
acqFs = round (1 / fiberTriggerBin); % sampling rate
data.gen.acqFs = acqFs;

params = struct;
params.FP.lpCut = 15; % Cut-off frequency for filter
params.FP.filtOrder = 8; % Order of the filter
params.dsRate = 1; params.dsType = 2; % 1 = Bin Summing; 2 = Bin Averaging;
params.FP.interpType = 'linear'; params.FP.fitType = 'interp';
params.FP.winSize = 10; params.FP.winOv = 0; params.FP.basePrc = 5;
data.gen.params = params;

[data] = processFP_NPM(data,params);
% [dFF] = baselineFP_SM(data.acq.FP{1}, data.gen.acqFs, params);

%% extract behavior data
% filename = 'StateTransitions.csv';
% behaviorFile = extractLickData(filename, 1); % for non-habituation data
% beh = extract2AFCdataFun(behaviorFile, dayName, 1);
% beh.LR_R = beh.LR_R(:); beh.pokeRate = beh.pokeRate(:); beh.rewLatency = beh.rewLatency(:); % make column vectors

% align time stamps for behavioral events (hits) to photometry time stamps
try 
    filename=dir('*StateTransitions.csv');
    statetrans=GetBonsai_Pho_StateTransitions_Celeste(filename.name);
    beh = alignBehTStoPhotoTS(data, statetrans); % frame relative to photometry signal
    
    data.beh = beh;
    data.acq.beh = statetrans;
catch
    fprintf('No behavior data file found. Proceeding without behavioral data.\n');
    data.beh = []; % Initialize behavior data as empty if not found
end

%% SAVE
saveName = sprintf('%s-%s_data.mat',data.mouse,data.date);
save(fullfile(filePath,saveName),'data');
%filePathCohort = 'R:\sippylab\Data\Jaden Tauber\cohort1_5HTDA_ketamine';
%save(fullfile(filePathCohort,saveName),'data');
fprintf('SAVED %s \n',saveName);

%% PLOT RW FP
% fig = figure; hold on
% for x = 1:2
%     subplot(1,2,x);
%     plot(data.acq.time{x}, data.acq.FP{x});
%     xlabel('Time'); ylabel('raw signal'); 
%     title(data.acq.FPnames{x});
% end 

%% processed FP 
% fig = figure; hold on
% for x = 1:2
%     subplot(1,2,x);
%     plot(data.final.time{x}, data.final.FP{x});
%     xlabel('Time (s)'); ylabel('FP (dF/F)'); 
%     title(data.final.FPnames{x});
% end 
