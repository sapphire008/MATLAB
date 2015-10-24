function FB_make_vectors(behav_path,BlockDesign,save_path,file_suffix,varargin)
%FB_make_vectors(behav_path,BlockDesign,save_path,file_suffix,...)
%
%debug inputs
% behav_path = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/edat/MP020_050613.txt';
% save_path = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/';
% BlockDesign.Conditions.type = {'InstructionBlock','ZeroBack','OneBack','TwoBack','NULL'};
% BlockDesign.Conditions.durations = [1,9,9,9,8];%in terms of number of scans
% BlockDesign.Runs = 3; %number of runs
% BlockDesign.TR = 2;% TR in seconds
% BlockDesign.Onsets = {'ImageOnsetTime'};%'InstructionsOnsetTime',
% BlockDesign.Conditions.name = 'RunningTrial';
% BlockDesign.ColHeaders = 'Image.OnsetTime,Instructions.OnsetTime,Running[Trial]';
% file_suffix = '_estimated_vectors.mat';
%
%BlockDesign.Accuracy = 'ImageACC';%Image.ACC
% %Optional Input:
%   vect_mode: Only relevent if there is no Onset field in the data
%       'discrete': each scan within each condition is vectorized,
%                   making duration of occurrence 0
%       'continuous': each block of condition is vectorized,
%                   making duration of occurrence the length of the block

% check vector mode specified
if isempty(varargin)
    vect_mode = 'continuous';
else
    vect_mode = varargin{1};
end

% check if there is onset field
if isfield(BlockDesign,'Onsets')
    if ~isempty(BlockDesign.Onsets)
        has_onsets = 1;
    else
        has_onsets = 0;
    end
else
    has_onsets = 0;
end
    

% PART I: Import Data from .txt file (converted from .edat file)
%get subject name according to txt file name
files = getfield(dir(behav_path),'name');
subject = files(1:(length(files)-4));
mkdir(fullfile(save_path,subject));

%read condition header information
if ~exist([behav_path(1:(end-4)),'.csv'],'file')
    perl('edat2csv.pl',behav_path,...
        BlockDesign.ColHeaders);%convert txt to csv
end
csv_path = strrep(behav_path,'.txt','.csv');%change to csv file path
behav_data = ReadTable(csv_path,'numeric',true);%read csv file


% PART II: Analyze Condition vectors
% strip condition column
cond_col = behav_data(2:end,find(ismember(behav_data(1,:),...
    BlockDesign.Conditions.name)));
cond_ind = zeros(1,length(cond_col));

for m = 1:length(BlockDesign.Conditions.type)
    cond_ind(ismember(cond_col,BlockDesign.Conditions.type{m})) = m;
end
%remove any repeated numbering
cond_vect = cond_ind;
cond_vect(logical([0,diff(cond_vect)==0])) = NaN;

% PART II: Make the vectors
switch has_onsets
    case {0} 
        %################################################################
        % Case I: there is no Onset inputs:
        % Solution: interpolate the onsets of each block by TR
        % get the order of the condition
        cond_order = cond_vect(~isnan(cond_vect));
        %store contrast vector
        all_onsets = [];
        for u = cond_order
            all_onsets = [all_onsets,u*ones(1,...
                BlockDesign.Conditions.durations(u))];
        end
        
        %separate into runs
        all_onsets = reshape(all_onsets,length(all_onsets)/...
            BlockDesign.Runs,BlockDesign.Runs);
        
        %create vectors for each run
        for r = 1:BlockDesign.Runs
            clear onsets names durations;
            [onsets,names,durations] = create_SPM_vectors_with_TR(...
                all_onsets(:,r),BlockDesign.Conditions.type,...
                BlockDesign.TR,BlockDesign.Conditions.durations,vect_mode);
            block = ['block',num2str(r)];
            %save vecotr
            save(fullfile(save_path,subject,[block,file_suffix]),...
                'block','onsets','names','durations');
        end
        %#################################################################
        % Case II: There are onset column
    case {1}
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Onset Corrections%%%%%%%%%%%%%%%%%%%%%%
        % combine Onsets, if more than one columns specified
        if ischar(BlockDesign.Onsets)
            BlockDesign.Onsets = cellstr(BlockDesign.Onsets);
        end
        %getting rid of nonnumeric data
        combine_col = cell2mat(cellfun(@(x) find(ismember(...
            behav_data(1,:),x)),BlockDesign.Onsets,'un',0));
        data_to_combine = behav_data(2:end,combine_col);
        %merge columns
        combined_data = merge_columns_and_leave_only_numeric_data(...
            data_to_combine);
        %putting everything else back
        old_behav_data = behav_data;
        behav_data = cell(size(old_behav_data,1),size(...
            old_behav_data,2)-length(combine_col)+1);
        behav_data{1,1} = 'Onsets';
        behav_data(2:end,1) = num2cell(combined_data);
        behav_data(:, 2:end) = old_behav_data(:,setdiff(1:size(...
            old_behav_data,2),combine_col));
        clear old_behav_data combine_col data_to_combine combined_data;
        %%%%%%%%%%%%%%%%%%%%%%%%%% END Data Corrections%%%%%%%%%%%%%%%%%%%%
        %reshape cond_ind into runs
        run_onsets_ind = reshape(cond_ind,length(cond_ind)/...
            BlockDesign.Runs,BlockDesign.Runs);
        %reshape the cond_vect into runs
        run_onsets_vect = reshape(cond_vect,length(cond_vect)/...
            BlockDesign.Runs,BlockDesign.Runs);
        %find onset column (or any column that contains onsets)
        onsets_col_num = find(ismember(behav_data(1,:),'Onsets'),1);
        if isempty(onsets_col_num)
            onsets_col_num = find(cell2mat(cellfun(@(x) ~isempty(...
                regexpi(x,'onset')),behav_data(1,:),'un',0)));
        end
        %reshape onsets time into runs
        run_onsets_time = reshape(cell2mat(behav_data(2:end,...
            onsets_col_num)),length(cond_vect)/BlockDesign.Runs,...
            BlockDesign.Runs)/1000;%make sure convert to seconds
        run_onsets_time = interpolate_onsets(run_onsets_time,...
            run_onsets_vect,BlockDesign.Conditions.durations*...
            BlockDesign.TR);
        for r = 1:BlockDesign.Runs
            clear onsets names durations;
            [onsets,names,durations] = create_SPM_vectors_with_onsets(...
                run_onsets_time(:,r)-run_onsets_time(1,r),run_onsets_vect(:,r),...
                BlockDesign.Conditions.type,BlockDesign.TR,...
                BlockDesign.Conditions.durations);
            block = ['block',num2str(r)];
            save(fullfile(save_path,subject,[block,file_suffix]),'block',...
                'onsets','names','durations');
        end
end

end

function [onsets,names,durations] = ...
    create_SPM_vectors_with_TR(col_vect,conditions,TR,dur,vect_mode)
%col_vect: condition of task occured in in order, within one run
%conditions: names of the conditions
%TR: TR of the scan
%dur: vector of durations corresponding to each conditions, in units of
%     scans
%
%vect_mode:
%       'discrete': each scan within each condition is vectorized,
%                   making duration of occurrence 0
%       'continuous': each block of condition is vectorized,
%                   mkaing duration of occurrence the length of the block

clear names tmp_onsets onsets durations;
names = conditions;
tmp_onsets = cell(1,length(names));
for m = 1:length(names)
    tmp_onsets{m} = (col_vect==m);
end

%convert data to SPM format, remove empty ones
names = names(cell2mat(cellfun(@(x) sum(x)~=0,tmp_onsets,...
    'UniformOutput',false)));%get rid of names with empty onsets
tmp_onsets = tmp_onsets(cell2mat(cellfun(@(x) sum(x)~=0,tmp_onsets,...
    'UniformOutput',false)));%get rid of onsets with empty onsets
tmp_onsets = cellfun(@double,tmp_onsets,'UniformOutput',false);

switch vect_mode
    case {'discrete'}
        onsets = cellfun(@(x) (find(x)-1)*TR,...
            tmp_onsets,'UniformOutput',false);
        durations = num2cell(zeros(1,length(names)));
    case {'continuous'}
        onsets = cell(1,length(tmp_onsets));
        for n = 1:length(tmp_onsets)
            tmp_onsets{n}(diff([~tmp_onsets{n}(1);tmp_onsets{n}])==0)=NaN;
            onsets{n} = (find(tmp_onsets{n}>0)-1)*TR;
        end
        %get the durations only for the names, leaving out any potential
        %empty conditions
        durations = num2cell(dur(ismember(conditions,names))*TR);
end
end


function [onsets,names,durations] = ...
    create_SPM_vectors_with_onsets(col_vect,col_ind,conditions,TR, dur)
% col_vect: column vector of onset times
% col_ind: index of each condition. The number inside corresponds to which
% conditions
% conditions: cellstr of condition names
% dur: durations, corresponding to each condition

onsets = cell(1,length(conditions));
for c = 1:length(conditions)
    onsets{c} = col_vect(col_ind == c);
end
non_empty_IND = ~cellfun(@isempty,onsets);
names = conditions(non_empty_IND);
durations = num2cell(dur(non_empty_IND)*TR);
end



function combined_data = merge_columns_and_leave_only_numeric_data(data_to_combine)
%check how many columns there are
if size(data_to_combine)<2
    combined_data = data_to_combine;
    return;%return if nothing to combine
end
%place holding
combined_data = nan(size(data_to_combine,1),1);
for vv = 1:size(data_to_combine,1)
    clear num_ind;
    %within each row, find which column is numeric
    num_ind = find(cellfun(@isnumeric,data_to_combine(vv,:)));
    %if one and only one of the column is numeric
    if length(num_ind)==1
        combined_data(vv) = data_to_combine{vv,num_ind};
    elseif length(num_ind)>1%if there are more than one cols are numeric
        %combined_data(vv) = -999;
        error('Combined onsets do not have unique observations.');
    end
    %otherwise, keep it NaN
end
end

function onsets_time_vect = interpolate_onsets(onsets_time_vect, cond_ind,dur)
% onsets_time_vect = interpolate_onsets(onsets_time_vect,cond_ind,dur)
% Fill in the NaN missing values/data, and interpolate according to
% duration specified in dur, based on conditions specified in cond_ind
% 
% Required inputs:
%       onsets_time_vect: onset time, either a vector of numbers, with
%                         missing value filed in as NaN, or a matrix/ The
%                         unit of onsets must be the same as duration.
%
%       cond_ind: indices of conditions, in which the value corresponds to
%                 index of duration, which is a vector of durations
%                 corresponding to each conditions
%
%       dur: durations, a vector of durations corresponding to the
%            conditinos; the unit of dur must be the same as onsets


%make sure dur is in colulmn
% onsets_time_vect = run_onsets_time;
% dur = BlockDesign.Conditions.durations*BlockDesign.TR;
% cond_ind = run_onsets_vect;

dur = dur(:);
for r = 1:size(onsets_time_vect,2)
    clear current_NaN_IND current_nunmeric_IND;
    %find the index of all NaNs
    current_NaN_IND = find(isnan(onsets_time_vect(:,r)));
    %check if there is still NaN in the vector
    has_nan = ~isempty(find(isnan(onsets_time_vect(:,r)),1));
    if ~has_nan
        continue;%continue if there is no need to interpolate
    end
    %find the numeric
    current_numeric_IND = find(~isnan(onsets_time_vect(:,r)));
    
    %find indices with condition onsets available
    available_IND = find(~isnan(cond_ind));
    %find cond and numeric ind
    cond_and_num_IND = intersect(available_IND,current_numeric_IND);
    
    %for each NaN IND, find the closest numeric index available
    [~,IND] = arrayfun(@(x) min(abs(cond_and_num_IND-x)),current_NaN_IND);
    nearest_numeric_IND = cond_and_num_IND(IND);
   
    for k = 1:length(current_NaN_IND)
        %if the current NaN's nearest numeric has a condition (which marks
        % the start of a condition in block deisgn) and
        % NaN is one step next to the onset of a condition
        
        m = current_NaN_IND(k);%current NaN value
        %now find the nearest numeric with available conditions
        step = m-nearest_numeric_IND(k);
        if abs(step) ==1
            %interpolate by one step
            onsets_time_vect(m,r) = ...
                onsets_time_vect(nearest_numeric_IND(k),r) + ...
                step*dur(cond_ind(m));
        else %more than one step away from the previous onset
            %find the nearest onset of current block
            tmp = m-intersect(available_IND,current_numeric_IND);
            %only look in indices before the current NaN
            nearest_onset_steps = min(tmp(tmp>0));
            onsets_time_vect(m,r) = ...
                onsets_time_vect(m-nearest_onset_steps,r)+...
                dur(cond_ind(m-nearest_onset_steps));
        end
    end
end
end

