% Script to process photometry recording acquired with Wavesurfer (.h5) 
% and behavior recording acquired with Bonsai (.csv) and organize processed
% data into .mat data file.
%
% Syntax:
%   processDataSippyWS
%
% Inputs:
%   - no inputs necessary
%   - script will prompt you to select files and input information:
%       (1) Select Wavesurfer photometry output (.h5 file)
%       (1) Select Bonsai behavior output (.csv file)
%       (3) Dialog to recording identifyers
%       (4) (optional) Select cohort path to save copy of .mat file
%
% Output:
%   'data' structure saved as .mat in same folder as photometry .h5 file.
%
% Written by: Anya Krok, April 2026

%%
[h5Name,h5Path] = uigetfile('*.h5','Select photometry .h5', pwd);
cd(h5Path);  % open file directory

[~, behPath] = uigetfile('*.csv','Select bonsai data folder with .csv', pwd);
cd(behPath);  % open file directory

%% mouse/date identifiers from folder name
try
    mouse = regexp(behPath, 'JT0\d{2}', 'match', 'once'); % extract JT followed by 0 and two digits (e.g. JT019)
    date = regexp(behPath, '\d{6}', 'match', 'once'); % extract any sequence of exactly six digits (e.g. 251215)
catch
    mouse = 'JT0XX'; date = 'YYMMDD';
end

params = struct;
params.acqFs = 1000;              % Acquisition sampling frequency
params.dsType = 2;                % 1 = Bin Summing; 2 = Bin Averaging; 3 = Traditional (NOT RECOMMENDED)
params.dsRate = params.acqFs/50;  % Downsampling rate if you want to downsample the signal
params.FP.lpCut = 15;             % Cut-off frequency for filter
params.FP.filtOrder = 8;          % Order of the filter
params.FP.basePrc = 5;            % Percentile value from 1 - 100 to use when finding baseline points
params.FP.winSize = 10;           % Window size for baselining in seconds
params.FP.winOv = 0;              % Window overlap size in seconds
params.FP.interpType = 'linear';  % Interp type: 'linear' 'spline' 
params.FP.fitType = 'interp';     % Fit method: 'interp' 'exp' 'line'
params.FP.sigEdge = 30;           % Time in seconds of data to be removed from beginning and end of signal
params.FP.modFreq = [217 319];    % Modulation frequency
params.FP.software = 'wavesurfer';

opts = {sprintf('%s \n\n\n Mouse ID:',behPath), 'Recording Date:', ...
        'Save to cohort folder? (yes/no)', ...
        'Acquisition Hz:', ...
        'Modulation Hz (green):', 'Modulation Hz (red):'};
opts = inputdlg(opts, 'Input', [1 40].*ones(length(opts),1), ...
        {mouse, date, 'no', ...
        num2str(params.acqFs), ...
        num2str(params.FP.modFreq(1)), num2str(params.FP.modFreq(2))});

mouse = opts{1}; date = opts{2}; 
dayName = sprintf('%s-%s',mouse,date);
cohortSave = opts{3};
params.acqFs = str2double(opts{4});
params.dsRate = params.acqFs/50;
params.modFreq = [str2double(opts{5}), str2double(opts{6})];

%% photometry: extract data from .h5 into matlab structure
fprintf('\nPhotometry: \n     Extract data from .h5 file. ');
tic
dataWS = extractH5_WS(fullfile(h5Path, h5Name));
data   = createDataStruct(dataWS, mouse, date);
data.gen.params = params; % add params to data structure
data.gen.params.acqFs = data.gen.acqFs; % overwrite with actual acquision sampling rate
data.gen.params.dsRate = data.gen.params.acqFs/50; % overwrite
data.gen.startSec = data.gen.startTime(4)*3600 + data.gen.startTime(5)*60 + data.gen.startTime(6);
toc
%% photometry: process
fprintf('     Process photometry data. ');
tic
data = processDual(data, data.gen.params); % if frequency modulation
% data = processFP(data, data.gen.params); % if continuous excitation
toc
fprintf('\n');
%% behavior: extract collection start time
[~, name, ~] = fileparts(regexprep(behPath,'/$',''));   % remove trailing slash then fileparts
parts = split(name, 'T');                                % {'2026-04-09','15-11-22'}
YMD = cellfun(@str2double, split(parts{1}, '-'));        % [2026 04 09]
HMS = cellfun(@str2double, split(parts{end}, '-'));      % [15 11 22]
%% behavior
csvNames = {dir('*.csv').name};
idxState = find(startsWith(csvNames, 'State')); % StateTransitions.csv
idxVideo = find(startsWith(csvNames, 'video')); % video.csv
% (a) attempt to process StateTransitions.csv Bonsai output (for 2AFC task)
if ~isempty(idxState)
    statetrans = GetBonsai_Pho_StateTransitions_Celeste(csvNames{idxState});
    if statetrans.Trial(1) == 0
        statetrans.Trial = statetrans.Trial + 1; % change zero- to one-index
    end
    bonsai_T0 = statetrans.TimeOfDay - statetrans.TimeOfDay(1);
    beh_startSec = statetrans.TimeOfDay(1)./1000;  % convert to seconds
    HMS(3) = HMS(3) + (beh_startSec - (HMS(1)*3600 + HMS(2)*60 + HMS(3))); % add millisecond precision
    % During data acquisition, bonsai / behavior acquisiton starts first and 
    % then wavesurfer / photometry acquisition. Thus, there will likely be
    % events/trials that occur prior to any photometry data. Later
    % processing will change time stamps for these events to NaN.
    startDelay = data.gen.startSec - beh_startSec; % wavesurfer starts AFTER bonsai behavior
    statetrans.PhotoTime = bonsai_T0 - startDelay; % new photometry-adjusted time
    fprintf('\nBehavior: \n     Extract data from .csv file. ');
    tic
    beh = extract2AFCdataAK(statetrans,'photoWS');
    beh.startTime = [YMD;HMS]';
    beh.startSec = beh_startSec;
    toc
    % Match timing:
    % Convert time stamps for behavioral data from seconds relative to
    % photometry acquisition start time --> samples relative to photometry.
    data.beh = beh;
    data.acq.beh = statetrans;
    fprintf('     Time stamps relative to photometry frames. ')
    tic
    data = alignBehTStoPhotoTS(data); % frames relative to photometry signal
    toc
    fprintf('\n');
end
% (b) attempt to extract video frames for openField recording in Bonsai
if ~isempty(idxVideo)
    fprintf('\nBehavior: \n     Extract data from .csv file. ');
    tic
    opts = detectImportOptions(csvNames{idxVideo});
    opts.SelectedVariableNames = opts.VariableNames(1);
    tmp = readtable(csvNames{idxVideo}, opts);
    frames = table(tmp{:,1}, 'VariableNames', {'TimeOfDay'});
    bonsai_T0 = frames.TimeOfDay - frames.TimeOfDay(1);
    beh_startSec = frames.TimeOfDay(1)./1000;      % convert to seconds
    HMS(3) = HMS(3) + (beh_startSec - (HMS(1)*3600 + HMS(2)*60 + HMS(3))); % add millisecond precision
    startDelay = data.gen.startSec - beh_startSec; % wavesurfer starts AFTER bonsai behavior
    frames.PhotoTime = bonsai_T0 - startDelay;     % new photometry-adjusted time
    newTS = firstFrameBeforeEventIndex(frames.PhotoTime, data.gen.acqFs, numel(data.acq.FP{1}));
    data.beh.frames = newTS; % frames relative to photometry signal
    data.beh.framesTS = frames.PhotoTime;
    toc
    fprintf('\n');
end
%% SAVE
if isfield(data.acq,'time')
    data.acq = rmfield(data.acq,'time'); % remove time vector to make data file smaller
end
if isfield(data,'final') && isfield(data.final,'time')
    data.final = rmfield(data.final,'time'); 
end
saveName = sprintf('%s-%s_data.mat',data.mouse,data.date);
save(fullfile(h5Path, saveName),'data');
fprintf('SAVED %s \n',saveName);
switch cohortSave
    case 'yes'
        cohortPath = uigetdir('Select cohort directory.',pwd);
        save(fullfile(cohortPath,saveName),'data');
end

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
