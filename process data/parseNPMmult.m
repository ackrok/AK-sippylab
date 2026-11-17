% Description: parse processed .mat output file from 'processDataSippy' for
% a multi-animal NPM recording into separate .mat files for each animal.
% File will be renamed 'data' and saved in same folder as original file.
%
% Assumed naming format for G0, G1, G2, G3 is data.acq.FPnames = ...
%   {'JT078 PFC DA', 'JT078 DMS DA', 'JT080 PFC DA', 'JT080 DMS DA'};
%   and will create separate data files such that
%   (1) data.mouse = JT078; data.acq.FPnames= {'PFC DA', 'DMS DA'} and 
%   (2) data.mouse = JT080; data.acq.FPnames= {'PFC DA', 'DMS DA'} and 
%
% Anya Krok 2026

[fileNames, filePath] = uigetfile('*.mat','MultiSelect','On');
if isequal(fileNames, 0), return; end % if no files
if ischar(fileNames), fileNames = {fileNames}; end % if single file

%%
for f = 1:length(fileNames)
    load(fullfile(filePath,fileNames{f})); % load data into workspace
    % parse unique mouse names from FPnames
    mouseNames = cellfun(@(s) strtok(s), data.acq.FPnames, 'UniformOutput', false);
    uniqueMice = unique(mouseNames, 'stable');
    if numel(uniqueMice) < 2
        warning('Skipping %s: expected multiple mice, found %d.', fileNames{f}, numel(uniqueMice));
        continue
    end
    [mouse, baseName] = strtok(fileNames{f},'-');
    dataMult = data; % rename variable, otherwise will be overwritten prior to save

    for m = 1:numel(uniqueMice)
        mouse = uniqueMice{m};
        idx = strcmp(mouseNames, mouse);

        dataOut = dataMult;
        dataOut.mouse = mouse; % rename mouse 
        dataOut.ID = [mouse, '-', dataOut.date];

        dataOut.acq.time = dataOut.acq.time(idx);
        dataOut.acq.FP = dataOut.acq.FP(idx);
        namesIn = dataOut.acq.FPnames(idx);
        namesOut = namesIn;
        for k = 1:numel(namesIn)
            [~, part] = strtok(namesIn{k});
            namesOut{k} = strtrim(part);
        end
        dataOut.acq.FPnames = namesOut;

        dataOut.final.FP = dataOut.final.FP(idx);
        dataOut.final.nbFP = dataOut.final.nbFP(idx);
        dataOut.final.FPbaseline = dataOut.final.FPbaseline(idx);
        dataOut.final.FPnames = dataOut.acq.FPnames;

        outFile = fullfile(filePath, sprintf('%s%s', dataOut.mouse, baseName));
        data = dataOut; 
        save(outFile, 'data');
        fprintf('SAVED: %s\n', outFile);
    end
end