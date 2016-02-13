function cellname = eph_date2cell(cellname, varargin)
if length(varargin)==3
    yy = varargin{1};
    mm = varargin{2};
    dd = varargin{3};
elseif length(varargin) == 1 && ischar(varargin{1})
    x = regexp(varargin{1},'/','split');
    yy = str2num(x{3}); 
    mm = str2num(x{1}); 
    dd = str2num(x{2});
else 
    error('Unrecognized date format. Either enter yy, mm, dd or ''mm/dd/yy''');
end
% convert year, month, day to cell name structure of data set
mm_short_dict = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep',...
    'Oct','Nov','Dec'};

cellname = sprintf('%s.%02.f%s%d', cellname, dd, mm_short_dict{mm}, mod(yy,100));
end