function [all_vox_time_series, mean_time_series] = time_series_extraction(filtered_data, onset_index, block_index, number_of_scans_in_series);
% time_series = time_series_extraction(P. onset_index, number_of_scans_in_series)
% time_series = time series array
% filtered_data - roi data for all the voxels in the ROI - for all the images in the scanner session 
% onset_index - list of onset locations within P array
% block_index - list of volume number, mark where block starts
% number_of_scans_in_series - number of scans to be included in time series
% time series that would extend past the end of the block are droped

j = 1;
for n = 1:length(onset_index)
    for k = 1:length(onset_index(n).index),
        try
            start_idx = onset_index(n).index(k);
            end_idx = onset_index(n).index(k)+number_of_scans_in_series-1;
            if block_index{n}(end) >= end_idx,
                all_vox_time_series(j,:,:) = filtered_data(start_idx:end_idx,:)';
                mean_time_series(j,:) = mean(all_vox_time_series(j,:,:));
                mean_time_series(j,:) = mean_time_series(j,:) - mean_time_series(j,1);
                j = j + 1;
            else
                disp(['The time series in block ', num2str(n), ' and index ', num2str(onset_index(n).index(k)), ' failed']);
            end
        catch
            disp(['The time series in block ', num2str(n), ' and index ', num2str(onset_index(n).index(k)), ' failed']);
        end
    end
end