function FB_make_vectors(behav_path,BlockDesign,save_path,varargin)
behav_path = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/edat/MP026_062613.txt';
save_path = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/';
BlockDesign.Conditions = {'InstructionBlock','ZeroBack','OneBack','TwoBack','NULL'};
BlockDesign.Durations = [1,10,10,10,8];%in terms of number of scans
BlockDesign.Runs = 3; %number of runs
BlockDesign.TR = 3;% TR in seconds
% %Optional Input:
%   vect_mode: 
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

%get subject name according to txt file name
files = getfield(dir(behav_path),'name');
subject = files(1:(length(files)-4));
mkdir(fullfile(save_path,subject));

%read condition header information
if ~exist([behav_path(1:(end-4)),'.csv'],'file')
    perl('edat2csv_frac_back.pl',behav_path);%convert txt to csv
end
csv_path = strrep(behav_path,'.txt','.csv');%change to csv file path
cond_data = importdata(csv_path);%read csv file



cond_col = cond_data(2:end,1);%get rid of header and other columns
cond_vect = zeros(1,length(cond_col));

for m = 1:length(BlockDesign.Conditions)
    cond_vect(ismember(cond_col,BlockDesign.Conditions{m})) = m;
end
%remove any repeated numbering
cond_vect(logical([diff(cond_vect)==0,0])) = NaN;
%finally, get the order of the condition
cond_order = cond_vect(~isnan(cond_vect));
%store contrast vector
all_onsets = [];
for u = cond_order
    all_onsets = [all_onsets,u*ones(1,BlockDesign.Durations(u))];
end

%separate into runs
all_onsets = reshape(all_onsets,length(all_onsets)/BlockDesign.Runs,...
    BlockDesign.Runs);
%vectors = struct();

for r = 1:BlockDesign.Runs
%     [vectors.(['block',num2str(r)]).onsets,...
%         vectors.(['block',num2str(r)]).names,...
%         vectors.(['block',num2str(r)]).durations ] = ...
%         create_SPM_vectors(all_onsets(:,r),BlockDesign.Conditions,...
%         BlockDesign.TR);
    [onsets,names,durations] = create_SPM_vectors(all_onsets(:,r),...
        BlockDesign,vect_mode);
    block = ['block',num2str(r)];
    
    save(fullfile(save_path,subject,[block,'_vectors.mat']),'block',...
        'onsets','names','durations');
end
end

function [onsets,names,durations] = ...
    create_SPM_vectors(col_vect,BlockDesign,vect_mode)
%col_vect: condition of task occured in in order, within one run
%names: names of the conditions
%vect_mode: 
%       'discrete': each scan within each condition is vectorized,
%                   making duration of occurrence 0
%       'continuous': each block of condition is vectorized,
%                   mkaing duration of occurrence the length of the block

clear names tmp_onsets onsets durations;
names = BlockDesign.Conditions;
tmp_onsets = cell(1,length(names));
for m = 1:length(names)
    tmp_onsets{m} = (col_vect==m);
end

%convert data to SPM format, remove empty ones
names = names(cell2mat(cellfun(@(x) sum(x)~=0,tmp_onsets,...
    'UniformOutput',false)));
tmp_onsets = tmp_onsets(cell2mat(cellfun(@(x) sum(x)~=0,tmp_onsets,...
    'UniformOutput',false)));
tmp_onsets = cellfun(@double,tmp_onsets,'UniformOutput',false);

switch vect_mode
    case {'discrete'}
        onsets = cellfun(@(x) (find(x)-1)*BlockDesign.TR+1,...
            tmp_onsets,'UniformOutput',false);
        durations = num2cell(zeros(1,length(names)));
    case {'continuous'}
        onsets = cell(1,length(tmp_onsets));
        for n = 1:length(tmp_onsets)
            tmp_onsets{n}(diff([~tmp_onsets{n}(1);tmp_onsets{n}])==0)=NaN;
            onsets{n} = (find(tmp_onsets{n}>0)-1)*BlockDesign.TR+1;
        end
        durations = num2cell(BlockDesign.TR*BlockDesign.Durations(...
            ismember(BlockDesign.Conditions,names)));
end
end