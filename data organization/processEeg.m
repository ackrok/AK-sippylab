%% process EEG data
%
% Written by Anya Krok, June 2026

%%
[fileName,filePath] = uigetfile('*.edf');
info = edfinfo(fullfile(filePath,fileName)); % read header info
tt = edfread(fullfile(filePath,fileName)); % read signals and annotations into a timetable
varNames = tt.Properties.VariableNames;

%% RECORDING INFORMATION
try
    mouse = regexp(fileName, 'JT\d{3}', 'match', 'once'); % extract JT followed by 0 and two digits (e.g. JT019)
    date = regexp(fileName, '\d{4}-\d{2}-\d{2}', 'match', 'once'); % extract sequence of XXXX-XX-XX
    date = date(3:end); date = regexprep(date, '-', ''); % YYMMDD format
catch
    mouse = 'JT0XX'; date = 'YYMMDD';
end
opts = inputdlg({sprintf('%s \n\n\n Mouse ID:',fileName), ...
    'Recording Date:','Sampling Rate:','Gain:'}, ...
    'Input', [1 40].*ones(4,2), ...
    {mouse, date, num2str(2000), num2str(10)});
mouse = opts{1}; 
date = opts{2};
Fs = str2double(opts{3});
gain = str2double(opts{4});

%% CREATE DATA STRUCTURE
data = struct;
data.mouse = mouse;
data.date = date;
data.ID = sprintf('%s-%s',mouse,date); 
data.gen.Fs = Fs; 
data.gen.gain = gain;
data.gen.varNames = tt.Properties.VariableNames; % OR = info.SignalLabels;
data.gen.comments = info.Annotations;
data.gen.startDate = info.StartDate;
data.gen.startTime = info.StartTime;

%% ADD SIGNAL
for a = 1:length(varNames)
    sig = vertcat(tt.(varNames{a}){:});
    data.acq.eeg{a} = sig;
    tok = regexp(varNames{a}, '\d+', 'match', 'once');   % find first sequence of digits
    data.acq.eegNames{a} = ['eeg',tok];
    data.acq.unit = info.PhysicalDimensions(1);
end
data.gen.recLength = numel(data.acq.eeg{1})/Fs;
% t = (0:numel(sig)-1)/Fs; 

%% SAVE
saveName = sprintf('%s-%s_data.mat',data.mouse,data.date);
save(fullfile(filePath, saveName), 'data');