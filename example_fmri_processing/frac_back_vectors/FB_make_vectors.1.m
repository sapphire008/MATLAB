function [onsets,names,durations,block] = FB_make_vectors(...
    behav_path,file_suffix)
%FB_make_vectors(behav_path,BlockDesign,save_path,file_suffix,...)
%
%BlockDesign.Accuracy = 'ImageACC';%Image.ACC
% %Optional Input:
%   vect_mode: Only relevent if there is no Onset field in the data
%       'discrete': each scan within each condition is vectorized,
%                   making duration of occurrence 0
%       'continuous': each block of condition is vectorized,
%                   making duration of occurrence the length of the block

BlockDesign.ColHeaders = {'Block','Miniblock','TrialType','MiniBlockOnset','CueOnset'};
BlockDesign.Conditions.type = {'Instruction','ZeroBack','OneBack','TwoBack','Fixation'};
BlockDesign.Conditions.label = {-1,0,1,2,3};
BlockDesign.Conditions.durations = [1,10,10,10,10];%in terms of number of scans
BlockDesign.Runs = 3; %number of runs
BlockDesign.TR = 3;% TR in seconds

% PART I: Import Data from .csv file
files = SearchFiles(behav_path{:});
if isempty(files),error('Cannot locate data file!');end
Data = read_fracback_csv(files,BlockDesign);

% PART II: Analyze Condition vectors
% Get current block
for d = 1:length(Data)
    block = sprintf('block%d',unique(Data(d).('Block')));
    names     = BlockDesign.Conditions.type;
    onsets    = cell(1,numel(names));
    durations = num2cell(BlockDesign.Conditions.durations*BlockDesign.TR);
    % instruction
    [ONSETS.Instruction,IB,IC] = unique(Data(d).('MiniBlockOnset'));
    IND = IB(:)'-hist(IC,unique(IC))+1;
    ONSETS.ABS = ONSETS.Instruction(1);%reference for all the onsets
    % MiniBlocks
    ONSETS.MiniBlocks = [Data(d).('TrialType'),Data(d).('CueOnset')];
    ONSETS.MiniBlocks = ONSETS.MiniBlocks(IND,:);
    ONSETS.MiniBlocks = [ONSETS.MiniBlocks;[-1*ones(numel(ONSETS.Instruction),1),ONSETS.Instruction]];
    ONSETS.MiniBlocks(:,2) = ONSETS.MiniBlocks(:,2) - ONSETS.ABS;
    % Aggergate into cell array
    for r = 1:size(ONSETS.MiniBlocks)
        onsets{ONSETS.MiniBlocks(r,1)+2}(end+1,:) = ONSETS.MiniBlocks(r,2);
    end
    save(fullfile(behav_path{1},sprintf('%s%s',block,file_suffix)),...
        'block','names','onsets','durations');
end
end

function S = read_fracback_csv(files,BlockDesign)
Data = cellfun(@ReadTable,files,'un',0);%read csv
S = struct();
for d = 1:length(Data)
    row = 0;
    % find the last attempt to run current run
    for r = 1:size(Data{d},1)
        if ~iscellstr(Data{d}(r,:))
            continue;
        end
        for c = 1:length(BlockDesign.ColHeaders)
            if ismember(BlockDesign.ColHeaders{c},Data{d}(r,:))
                if row<r,row=r;end
            end
        end
    end
    %remove all the previous headers
    Data{d} = Data{d}(row:end,:);
    %convert to structure
    for c = 1:size(Data{d},2)
        tmp = Data{d}(2:end,c);
        if all(cellfun(@isnumeric,tmp))
            tmp = cell2mat(tmp);
        end
        S(d).(Data{d}{1,c}) = tmp;
        clear tmp;
    end
end
end




