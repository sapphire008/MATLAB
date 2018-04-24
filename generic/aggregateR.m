function aggregated_dataframe = aggregateR(dataframe,aggregate_by,func_handle,aggregate_only, varargin)
% mimicking R function aggregate.
% aggregated_dataframe = aggregateR(dataframe,aggregate_by,func_handle,aggregate_only, ...)
% Inputs:
%   dataframe: cell array of data. Assuming first row is the column header
%   aggregate_by: cell array of column header names to aggregate by
%   func_handle: function handle. Default @mean
%   aggregate_only: aggregate only the selected columns. Will only return
%                   these columns in the output. Default aggregate all the
%                   columns in dataframe that are not specified
%                   aggregate_by.
% Additional inputs at the end for additional arguments of func_handle
% Output:
%   aggregated_dataframe: summarized cell array
%
% Example:
% load('/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/unseparated_timeseries/baselined/dataframe.mat');
% aggregate_by = {'Groups','ROIs','Blocks'};
% func_handle = @mean;
% aggregate_only = cellfun(@(x) ['TR',num2str(x)],num2cell(1:114),'un',0);

% separate data from column header
col_header = dataframe(1,:);
dataframe = dataframe(2:end,:);
% Check if all col_headers are strings
if ~all(cellfun(@ischar, col_header))
    error('Not all column headers are strings. Make sure all column headers are strings');
end
% Check if column header has NaN in them
if any(cell2mat(cellfun(@(x) all(isnan(x)), col_header, 'un',0)))
   error('Some column header has NaN');
end
% parse aggregation factor column number
factor_col = cellfun(@(x) find(ismember(col_header,x),1),aggregate_by, 'un',0);
if any(cellfun(@isempty, factor_col))
    error('Check spelling of aggregate_by argument');
end
agby_col = cellfun(@(x) find(ismember(col_header,x),1),aggregate_by);

if any(agby_col == 0)
    error('The following column header(s) are not found%s',char(col_header(agby_col(agby_col ==0))));
end
%parse function
if nargin<3 || isempty(func_handle)
    func_handle = @mean;
end
%parse aggregation data column number
if nargin<4 || isempty(aggregate_only)
    data_col = 1:length(col_header);
    data_col(agby_col) = [];
    % use the first entry as a reference. Remove also the column that is
    % potentially a string
    data_col(cellfun(@ischar,dataframe(1,:))) = [];
else
    data_col = cellfun(@(x) find(ismember(col_header,x),1),aggregate_only, 'un',0);
    if any(cellfun(@isempty, data_col))
        error('Check spelling of aggregate_only argument')
    else
        data_col = cell2mat(data_col);
    end
end
%parse each factors specified
%F relabels the factos into numbers
F = zeros(size(dataframe,1),length(aggregate_by));
%NAMES, index unique names of each factor found
NAMES = cell(1,length(aggregate_by));
for agby = 1:length(aggregate_by)
    current_factor = dataframe(:,agby_col(agby));
    if isnumeric(current_factor{1})
        current_factor = cell2mat(current_factor);
    end
    [NAMES{agby},~,F(:,agby)] = unique(current_factor);
end
% find each unique combinations of factors
[C,~,IC] = unique(F,'rows', 'stable');%C will index the final result
%start the output dataframe
aggregated_dataframe = cell(size(C,1)+1,length(agby_col)+length(data_col));
aggregated_dataframe(1,:) = col_header([agby_col,data_col]);
for a = 1:size(C,1)%row
    for b = 1:size(C,2)%column
        if iscell(NAMES{b})
            aggregated_dataframe{a+1,b} = NAMES{b}{C(a,b)};
        else
            aggregated_dataframe{a+1,b} = NAMES{b}(C(a,b)); 
        end
    end
    for k = 1:length(data_col)
        tmp_dataframe = dataframe(find(IC==a),data_col(k));
        if ~iscellstr(tmp_dataframe)
            tmp_dataframe = cell2mat(tmp_dataframe);
        end
        aggregated_dataframe{a+1,(b+k)} = func_handle(tmp_dataframe, varargin{:});
    end
end
end