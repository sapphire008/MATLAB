function plot_timeseries(timeseries_data,varargin)
% plot_timeseries(timeseries_data,...)
% Required Input:
%       timeseries_data: must be a 1xN or Nx1 vector
%
% Optional Inputs:
%       'blocks': cell array. Each cell must contain the index that
%                  corresponds to the index of timeseries_data
%
%       'time':   cell array. Plot against a vector of time instead of 1:N
%                 Must contain the same number of cells as in 'blocks'.The 
%                 vector in each cell must be same length as the length of
%                 each block.
%
%       'events': cell array. Each cell can contain one type of event. The
%                   length of the contents of each cell must be the same as
%                   timeseries_data (NOT IMPLEMENTED, DO NOT USE)
%
%       'event_time': cell array. Each cell can contain one type of event.
%                     Each cell must contain a time point that is within
%                     the time range specified in 'time';
%                     Each column within each cell corresponds to each
%                     block. For variable block length, append 0 so that
%                     all columns have equal length. If one block misses
%                     this condition, add zeros to this column.
%                     This is simply onset vectors concatenated across
%                     blocks.
%                     If use this option, one have to supply 'time'.
%
%       'event_names': cellstr, must be the same length as 'events' or
%                       'event_time'
%





flag = L_InspectVarargin(varargin,{'blocks','time','events','event_time','event_names'},...
    {1:length(timeseries_data)},{},{},{},{});

time_resolution = 1000;
%determine how many sub-plots are needed
num_subplot = 1;
if ~isempty(flag.events) 
    num_subplot = num_subplot +length(flag.events);
    event_used = 'Scans';
elseif ~isempty(flag.event_time)
    num_subplot = num_subplot +length(flag.event_time);
    event_used = 'Time';
end
%Inspect time
if isempty(flag.time)
    flag.time = cellfun(@(x) 1:length(x),flag.blocks,'un',0);
end
for b = 1:length(flag.blocks)  
    figure(b);
    if num_subplot>1
        subplot(num_subplot,1,1);
    end
    %plot timeseries
    plot(flag.time{b},timeseries_data(flag.blocks{b}));
    hold on;
    plot(flag.time{b},timeseries_data(flag.blocks{b}),'o');
    hold off;
    %plot events
    for n = 1:length(num_subplot-1)
        clear final_events;
        switch event_used
            case {'Scans'}
                final_events = flag.events{n}(flag.blocks{b});
            case {'Time'}
                final_events = flag.event_time{n}(:,b);
        end
        final_events = final_events(:);
        final_events([false;final_events(2:end)==0]) = -1;
        
        %build a spike train
        time_vect = flag.time{b}(1):(1/time_resolution):flag.time{b}(end);
        tmp_spike_train = zeros(1,length(time_vect));
        event_IND = [];
        for kk = 1:length(final_events)
            if final_events(kk) == -1
                continue
            else
                [~,IND]=min(abs(final_events(kk)-time_vect));
                event_IND = [event_IND,IND];
            end
        end
        
        tmp_spike_train(event_IND) = 1;
            
        subplot(num_subplot,1,n+1);
        plot(time_vect,tmp_spike_train);
        if ~isempty(flag.event_names)
            title(flag.event_names{n});
        end
        
    end
    
end
end


function flag=L_InspectVarargin(search_varargin_cell,keyword,default_value)
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