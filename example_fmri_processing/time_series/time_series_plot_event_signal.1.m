function  [TS,EVENT,OPT] = time_series_plot_event_signal(TS,EVENT,varargin)
% plot time series over specified event
% time_series_plot_event_signal(TS, EVENT, 'opt1',value1,...)
% Inputs:
%   TS: structure that contains the following fields:
%           .signal: time series KxN vector, with K different time series
%                    plotted in the same graph. Can handle up to 35 plots
%           .time: 1xN vector that labels time in second. More explicitly
%                  time intervals
%           .sample_rate: sampling rate of the time series (Hz), assuming
%                         evenly spaced sampling. Can be used in place
%                         of .time
%   EVENT: structure that contains the following fields:
%           .onsets: onset time in seconds
%           .durations: duration of the event in seconds
%           .names: name of the event
%           .labels: event labels used in plot. Default will use event
%                    names from EVENT.names
%       All fields are cellarray of equal length.
%       If event is a 1xM array of structures, each element of the array
%       will be treated as a block/run, so that each block will be 
%       concatenated after one another after separated into events. 
%       In this case, EVENT may also contain additional fields to specify 
%       block properties:
%           .block: block/run name
%   OPT: plot options, with the following possibilities
%       'xlabel': x axis label. Default 'Time (s)'
%       'ylabel': y axis label. Default 'Signal'
%       'title': title of the plot. Default 'Time Series'
%       'legend': legend of the time series. Default
%                 {'Series1','Series2'...}
%       'ignore_onset:[true|false], if true, separating events only by the
%                     offset. Default false
%       'ignore_offset': [true|false], if true, separating events only by 
%                      the onsets. Default false

% TS.signal = randn(2,114);
% TS.sample_rate = 1/3;
% EVENT.onsets = onsets;
% EVENT.names = names;
% EVENT.durations = durations;

% parse input
if ~isfield(TS,'time')
    if isfield(TS,'sample_rate')
        % use sample_rate to make up time
        TS.time = linspace(0,(length(TS.signal)-1)/TS.sample_rate,length(TS.signal));
    else
        error('Please specify either .time or .sample_rate in the input TS structure\n');
    end
end

% parse optional inputs
OPT = ParseOptionalInputs(varargin,{'xlabel','ylabel','title','legend',...
    'ignore_onset','ignore_offset','fill'},...
    {'Time (s)','Signal','Time Series',...
    cellfun(@(x) ['Series',num2str(x)],num2cell(1:size(TS.signal,1)),'un',0),...
    false,false,[]});
% restructure EVENT so that it is easier for plotting
EVENT = cell2mat(arrayfun(@(x) restruct_event(TS,x),EVENT,'un',0));
% plot the time series
Plot_TS(TS,EVENT,OPT);
end

%% Sub-routines

%plot the time series with EVENTS
function Plot_TS(TS, EVENT,OPT)
% list of available colors
Color_vect = 'brmcgyk';
% list of available lines
Line_vect = '-o+*.';
[X,Y] = meshgrid(1:length(Line_vect),1:length(Color_vect));
% plot
for n = 1:size(TS.signal)
    % do the plotting. The last argument will determine which color and
    % marker to use in current plot
    plot(TS.time,TS.signal(n,:),Color_vect(Y(n)));
    plot(TS.time,TS.signal(n,:),[Color_vect(Y(n)),Line_vect(X(n))]);
    hold on;
end
% divide the plot into intervals based on onsets and end
if ~OPT.ignore_onset
    line_x_mat = [EVENT.onsets(:)';EVENT.onsets(:)'];
    line_y_mat = repmat(get(gca,'YLim')',1,length(EVENT.onsets));
    line(line_x_mat, line_y_mat,'Color','k');
end
if ~OPT.ignore_offset
    line_x_mat = [EVENT.offsets(:)';EVENT.offsets(:)'];
    line_y_mat = repmat(get(gca,'YLim')',1,length(EVENT.offsets));
    line(line_x_mat, line_y_mat,'Color','k','LineStyle',':');
end
% label each event
text_x_mat = (EVENT.onsets(:)'+EVENT.offsets(:)')/2;
text_y_mat = 0.95*repmat(max(get(gca,'YLim')),1,length(EVENT.onsets));
if isfield(EVENT,'labels') && ~isempty(EVENT.labels)
    text(text_x_mat,text_y_mat,EVENT.labels);
else
    text(text_x_mat,text_y_mat,EVENT.names);
end

hold off;
% mark and clean up the plot
xlabel(OPT.xlabel);
ylabel(OPT.ylabel);
title(OPT.title);
if size(TS.signal,1)>1
    legend(OPT.legend{:});
end
set(gca,'XLim',[min(TS.time),max(TS.time)]);
end

% reconstructing EVENT structure to allow plotting
function [EVENT,numEvents] = restruct_event(TS,EVENT)
% calculate how many events in total
numEvents = sum(cellfun(@(x) length(x), EVENT.onsets));
% for each onset time, find the nearest time in TS.time
EVENT.onsets = cellfun(@(x) adjust_time(x,TS.time),EVENT.onsets,'un',0);%should be row vector
% calculate event end time
EVENT.offsets = cellfun(@(x,y) adjust_time(x+y,TS.time),EVENT.onsets,EVENT.durations,'un',0);%should be row vector
% Duplicate names so that each onset corresponds to a name
EVENT.names = cellfun(@(x,y) repmat(x,length(y),1),EVENT.names,EVENT.onsets,'un',0);
% parse event labels
label_flag = isfield(EVENT,'labels') & ~isempty(EVENT.labels);
if label_flag
    EVENT.labels = cellfun(@(x,y) repmat(x,length(y),1),EVENT.labels,EVENT.onsets,'un',0);
end
    
% Unwrap all fields
EVENT.onsets = cell2mat(EVENT.onsets);%onsets
EVENT.offsets = cell2mat(EVENT.offsets);%offsets
EVENT.names = cellstr(char(EVENT.names));%names
if label_flag
    EVENT.labels = cellstr(char(EVENT.labels)); %labels
end
% sorting by onsets
[EVENT.onsets,I] = sort(EVENT.onsets(:),1,'ascend');
EVENT.offsets = EVENT.offsets(I);
EVENT.offsets = EVENT.offsets(:);
EVENT.names = EVENT.names(I);
EVENT.names = EVENT.names(:);
if label_flag
    EVENT.labels = EVENT.labels(I);
    EVENT.labels = EVENT.labels(:);
end
end

% adjust onsets to the nearest given TIME
function [ADJ_ONSETS,I] = adjust_time(ONSETS,TIME)
%given that each row of X and Y are observations
%DIST = X'*X+Y'Y-2*X*Y'
% pair-wise distance
D = bsxfun(@plus,dot(ONSETS(:),ONSETS(:),2),dot(TIME(:),TIME(:),2)')-2*(ONSETS(:)*TIME(:)');
[~,I] = min(D,[],2);
I = I(:)';%row vector
TIME = TIME(:)';%row vector
ADJ_ONSETS = TIME(I);
end

% inspecting optional inputs
function flag=ParseOptionalInputs(search_varargin_cell,keyword,default_value)
% flag = InspectVarargin(search_varargin_cell,keyword, default_value)
%Inspect whether there is a keyword input in varargin, else return default.
%if search for multiple keywords, input both keyword and default_value as a
%cell array of the same length
%if length(keyword)>1, return flag as a structure
%else, return the value of flag without forming a structure
if length(keyword)~=length(default_value)%flag imbalanced input
    error('keyword and default_value must be the same length');
end

%convert everything into cell array if single input
if ~iscell(keyword)
    keyword={keyword};
end
if ~iscell(default_value)
    default_value={default_value};
end

flag=struct();%place holding
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),search_varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=search_varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_value{n};
    end
end

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end

end


