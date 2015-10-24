function plot_time_series(R,varargin)
% Required input:
%       R, a matrix of time series, taken column-wise
%
% Optional inputs:
%       'time'      : a vector of time values, to replace 1:size(R,1)
%
%       'color'     : cellstr of colors, input as 'r' for red, 'b' for
%                     blue, 'k' for black, etc. Thelength must be the same
%                     as the number of columns that R has
%
%       'legend'   : a cellstr of names for each time series, and its
%                     length must be the same length as the number
%                     of columns
%
%        'axis'     : size of the axis, [xmin xmax ymin ymax], see AXIS
%        'xlim'     : x-axis limit, [min max], see PLOT
%        'ylim'     : y-axis limit, [min max], see PLOT
%
%       'axis_label': cellstr of axis labels, {'Xlabel','Ylabel'}
%
%       'plot_titles': a cellstr of plot identifiers, including
%                    subjects, runs, tasks, conditions, etc.
%                    This will server as the title of
%                    the subject. However, if it is a single string,
%                    instead of a cellstr of identifiers,
%                    the function will use the string directly.

hold on;
flag = L_InspectVarargin(varargin,...
    {'time','color','legend','axis','xlim','ylim','axis_label','plot_titles'},...
    {[1:size(R,1)],{'r','g','b','k','c','m','y'},[],[],[],[],{'X','Y'},[]});
for c = 1:size(R,2)
    %plot
    plot(flag.time,R(:,c),char(flag.color{c}));

    %plot title
    title_string = '';
    if iscellstr(flag.plot_titles)
        
        for n = 1:length(flag.plot_titles)
            title_string = [title_string,flag.plot_titles{n},'_'];
        end
        title_string(end) = '';
    elseif ischar(flag.plot_titles)
        title_string = flag.plot_titles;
    else
        error('plot_titles type must be eithe cellstr or char');
    end
    title(strrep(title_string,'_','\_'));
    
    %axis label
    xlabel(flag.axis_label{1});
    ylabel(flag.axis_label{2});
    
    
    %axis scales
    if ~isempty(flag.axis)
        axis(flag.axis);
    end
    if ~isempty(flag.xlim)
        xlim(flag.xlim);
    end
    if ~isempty(flag.ylim)
        ylim(flag.ylim);
    end
    
end
%legend
clear h;
h=legend(flag.legend,'location','SouthEast');
set(h,'fontsize',4);

hold off;
    
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

