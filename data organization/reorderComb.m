function comb = reorderComb(comb)
%%Loop through combined data structure containing photometry data across 
%%multiple recording sites and/or sensors and re-arrange to ensure that
%%FPnames are matching across recordings.
% 
% [comb] = reorderComb(comb);
%
% Description: Function will loop through {comb.FPnames} to ensure matching
% across each element in FPnames cell array and then apply same permutation
% to {comb.FP} and {comb.nbFP}.
%
% INPUTS
%   'comb' - Structure with data from multiple recordings
%       - created using function: comb = extractComb;
%
% OUPUTS
%   'comb' - Structure with data from multiple recordings
%
% Written by Anya Krok, July 2026

if ~isfield(comb,'FPnames')
    error('No photometry data in comb structure.');
end

% number of channels from first element
nCh = numel(comb(1).FPnames);
prompt = cell(1,nCh);
defaults = cell(1,nCh);
for k = 1:nCh
    prompt{k} = sprintf('Enter desired FP{%d} (ignore case):', k);
    defaults{k} = comb(1).FPnames{k};
end
dlgTitle = 'Photometry Signal Labels';
numLines = 1;
answer = inputdlg(prompt, dlgTitle, numLines, defaults);
if isempty(answer)
    error('User cancelled FP name input.');
end

% normalize answers to strings for contains checks
answerStr = string(answer);

% apply to each element of struct array
for ii = 1:numel(comb)
    fn = comb(ii).FPnames;            % 1xM cell of labels for this element
    M = numel(fn);
    idxs = zeros(1,min(nCh,M));
    % find index for each requested label in this element (first match)
    for k = 1:min(nCh,M)
        matches = contains(string(fn), answerStr(k), 'IgnoreCase', true);
        idx = find(matches, 1);
        if isempty(idx)
            idxs(k) = NaN;            % not found
        else
            idxs(k) = idx;
        end
    end
    % if all requested labels found, create permutation: requested ones first (in order),
    % then any remaining channels in original order
    if all(~isnan(idxs))
        idxs = idxs(:).';                      % ensure row
        others = setdiff(1:M, idxs, 'stable');
        perm = [idxs, others];
        % reorder FPnames
        comb(ii).FPnames = fn(perm);
        % reorder FP and nbFP if they exist and have compatible length
        if isfield(comb(ii),'FP') && numel(comb(ii).FP) == M
            comb(ii).FP = comb(ii).FP(perm);
        end
        if isfield(comb(ii),'nbFP') && numel(comb(ii).nbFP) == M
            comb(ii).nbFP = comb(ii).nbFP(perm);
        end
    else
        % if not all requested labels found, skip reordering for this element
        % (or handle as needed)
    end
end