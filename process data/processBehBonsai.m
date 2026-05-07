% For data acquired using Wavesurfer software (photometry) and Bonsai
% (behavior), this script will process Bonsai .csv output files and ensure 
% time stamp alignment with photometry.
% NOTE: run processDataSippyWS first!
%
% Syntax:
%   data = processBehBonsai(data);
%
% Inputs:
%   'data', structure with photometry data, from processDataSippyWS
%
% NOTE: you will be prompted to select Bonsai behavior output (.csv file).
%
% Output:
%   'data' structure now with behavior data and/or aligned time stamps.
%
% Written by: Anya Krok, May 2026

function data = processBehBonsai(data)

% select Bonsai behavior output (.csv file folder)
[~, behPath] = uigetfile('*.csv','Select bonsai data folder with .csv', pwd);
cd(behPath);  % open file directory

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
    fprintf('Behavior: \n     Extract data from .csv file. ');
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
    fprintf('Behavior: \n     Extract data from .csv file. ');
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
    newTS = firstFrameBeforeEventIndex(frames.PhotoTime, data.gen.acqFs, data.gen.acqSamp);
    data.beh.frames = newTS; % frames relative to photometry signal
    data.beh.framesTS = frames.PhotoTime;
    toc
    fprintf('\n');
end

end