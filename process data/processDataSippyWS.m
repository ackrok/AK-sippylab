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
%       (2) Dialog to recording identifyers
%       (optional) Select cohort path to save copy of .mat file
%
% Output:
%   'data' structure saved as .mat in same folder as photometry .h5 file.
%
% Written by: Anya Krok, April 2026

%%
[h5NameAll,h5Path] = uigetfile('*.h5','Select photometry .h5', pwd, 'MultiSelect', 'on');
if ~iscell(h5NameAll); h5NameAll = {h5NameAll}; end
cd(h5Path);  % open file directory

for thisFile = 1:length(h5NameAll)

    h5Name = h5NameAll{thisFile};

%% mouse/date identifiers from folder name
try
    tok = regexp(h5Name, '^([A-Za-z0-9]+).*?(\d{4}-\d{2}-\d{2})', 'tokens', 'once');
    mouse = tok{1}; % 'extract mouseID from file name
    ymd   = tok{2}; % 'extract date in 2026-05-05 format from file name
    dt = datetime(ymd, 'InputFormat', 'yyyy-MM-dd'); % convert YYYY-MM-DD to 'YYMMDD'  
    date = char(dt, 'yyMMdd');     % '260505'
catch
    mouse = 'JT0XX'; date = 'YYMMDD';
end

params = struct;
params.acqFs = 5000;              % Acquisition sampling frequency
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

opts = {sprintf('%s \n\n\n Mouse ID:',h5Name), 'Recording Date:', ...
        'Acquisition Hz:', ...
        'Modulation Hz (green):', 'Modulation Hz (red):', ...
        '** Process Behavior? (yes/no) **', ...
        'Save to cohort folder? (yes/no)'};
opts = inputdlg(opts, 'Input', [1 40].*ones(length(opts),1), ...
        {mouse, date, ...
        num2str(params.acqFs), ...
        num2str(params.FP.modFreq(1)), num2str(params.FP.modFreq(2)), ...
        'no', 'no'});

mouse = opts{1}; date = opts{2}; 
dayName = sprintf('%s-%s',mouse,date);
params.acqFs = str2double(opts{3});
params.dsRate = params.acqFs/50;
params.modFreq = [str2double(opts{4}), str2double(opts{5})];
runBeh = opts{6};
cohortSave = opts{7};

%% photometry: extract data from .h5 into matlab structure
fprintf('\nPhotometry: \n     Extract data from .h5 file. ');
tic
dataWS = extractH5_WS(fullfile(h5Path, h5Name));
data   = createDataStruct(dataWS, mouse, date);
data.gen.params = params; % add params to data structure
data.gen.params.acqFs = data.gen.acqFs; % overwrite with actual acquision sampling rate
data.gen.params.dsRate = data.gen.params.acqFs/50; % overwrite
data.gen.startSec = data.gen.startTime(4)*3600 + data.gen.startTime(5)*60 + data.gen.startTime(6);
% added a check to ensure that 470nm LED modulation frequency relates to
% the correct photometry signal
switch length(data.acq.FPnames)
    case 2
        whereDA = find(strcmpi(data.acq.FPnames,'DA'));
        if whereDA ~= 2
            data.acq.FP = data.acq.FP([2 1]); 
            data.acq.FPnames = data.acq.FPnames([2 1]);
        end
end
cutLenMin = floor((numel(data.acq.FP{1})/data.gen.acqFs)/60); % cutLength in minutes
cutLenSamp = cutLenMin*60*data.gen.acqFs;
for ii = 1:length(data.acq.FP)
    data.acq.FP{ii} = data.acq.FP{ii}(1:cutLenSamp);
end
if isfield(data.acq,'refSig')
    for ii = 1:length(data.acq.refSig)
        data.acq.refSig{ii} = data.acq.refSig{ii}(1:cutLenSamp);
    end
end
data.gen.acqSamp = numel(data.acq.FP{1});
toc
%% photometry: process
fprintf('     Process photometry data. ');
tic
data = processDual(data, data.gen.params); % if frequency modulation
% data = processFP(data, data.gen.params); % if continuous excitation
toc
fprintf('\n');

%% ttl if applicable
if isfield(data.acq,'ttl')
    for ii = 1:length(data.acq.ttl)
        [tmpOn, tmpOff] = getPulseOnsetOffset(data.acq.ttl{ii}, 0.5);
        data.final.ttl{ii} = [tmpOn(:)./data.gen.acqFs, tmpOff(:)./data.gen.acqFs];
    end
end

%% behavior: process
switch runBeh
    case 'yes'
        data = processBehBonsai(data);
end

%% SAVE
if isfield(data.acq,'time')
    data.acq = rmfield(data.acq,'time'); % remove time vector to make data file smaller
end
if isfield(data,'final') && isfield(data.final,'time')
    data.final = rmfield(data.final,'time'); 
end
% data = rmfield(data,'acq'); % CAN CHANGE -- removes raw signals to reduce space

saveName = sprintf('%s-%s_data.mat',data.mouse,data.date);
save(fullfile(h5Path, saveName),'data');
fprintf('\nSAVED %s \n\n',saveName);

%%
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

end