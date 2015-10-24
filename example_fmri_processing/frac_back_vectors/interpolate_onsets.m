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
            disp('used case 1,with step = 1');
        else %more than one step away from the previous onset
            %find the nearest onset of current block
            tmp = m-intersect(available_IND,current_numeric_IND);
            %only look in indices before the current NaN
            nearest_onset_steps = min(tmp(tmp>0));
            onsets_time_vect(m,r) = ...
                onsets_time_vect(m-nearest_onset_steps,r)+...
                dur(cond_ind(m-nearest_onset_steps));
            disp('used case 2, with step>1');
        end
    end
end
end
