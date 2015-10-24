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