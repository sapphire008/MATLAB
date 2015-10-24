function cellname = eph_date2cell(cellname, yy, mm, dd)
% convert year, month, day to cell name structure of data set
mm_short_dict = {'Jan','Feb','Mar','04.','May','Jun','Jul','Aug','Sep',...
    'Oct','Nov','Dec'};
cellname = sprintf('%s.%02.f%s%d', cellname, dd, mm_short_dict{mm}, mod(yy,100));
end