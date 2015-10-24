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