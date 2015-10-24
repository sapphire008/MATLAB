function filtered_data = filter_roi_data(raw_data,block_index,Ns)
% filtered_data = filter_roi_data(raw_data,block_index)
% filterd data - data after high pass filtering
% raw_data - raw time series data,
% block_index - maps data points to run blocks
% Ns =  the number of volumes in the time window

if ~exist('Ns'), Wn = .02; 
else Wn = 1/Ns; end  % default t is 100 seconds

    
[b,a] = butter(3,Wn,'high');

for n = 1:length(block_index)
    for k = 1:size(raw_data,2),
        filtered_data(block_index{n},k) = filtfilt(b,a,raw_data(block_index{n},k));       
    end

    % Add dc_offset back in per block
    %dc_offset=mean(mean(raw_data(block_index{n},:)));
    %filtered_data(block_index{n},k)=filtered_data(block_index{n},:)+dc_offset;
end

% Add dc_offset back in for entire set
dc_offset=mean(mean(raw_data));
filtered_data=filtered_data+dc_offset;

