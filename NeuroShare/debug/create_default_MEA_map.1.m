%% create MEA map based on the info read from the data
function [channelnames, MEA_map_coord, MEA_map, MEA_map_name] = ...
    create_default_MEA_map(channelnames)
% % Given channel names, return the following types of MEA maps
%   MEA_map: with 1's indicating channel is recorded (has data) and NaN's
%            indicating channel is not recorded (data not available)
%   MEA_map_name: cell array with channel names filled instead of NaN's and
%            1's.
%   MEA_map_coord: translated coordinate of channelnames, assuming letters
%            means columns and numbers following the letters means rows;
%            e.g. A7 means first column, 7th row. MEA_map_coord(:,1) is the
%            first channel coordinate, [row; col] format.

% get channel names based on the label, assuming the last group of strings
% (after a set of spaces) are the named label
try
    channelnames = cellfun(@(x) x{end}, regexp(channelnames,' ','split'),'un',0);
    % split letter and numbers (column and row labels)
    [~,~,col_nums] =  unique(cellfun(@(x) x{1}, regexp(channelnames,'([A-Z])','tokens')));
    row_nums = cellfun(@(x) str2double(x{1}{1}), regexp(channelnames,'(\d*)','tokens'));
    MEA_map = zeros(max(row_nums),max(col_nums));
    MEA_map(sub2ind(size(MEA_map),row_nums, col_nums(:)')) = 1;
    MEA_map_name = cell(size(MEA_map));
    MEA_map_name(sub2ind(size(MEA_map),row_nums, col_nums(:)')) = channelnames;
    MEA_map_coord = [row_nums;col_nums(:)'];
catch
    disp('Channel Map Information Not Available');
    channelnames = [];
    MEA_map_coord = [];
    MEA_map = [];
    MEA_map_name = [];
end
end