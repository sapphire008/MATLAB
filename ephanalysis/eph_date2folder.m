function path = eph_date2folder(yy, mm, dd)
% convert year, month, day to folder structure of data set
if yy<1000
    yy = yy + 2000; % good for this century
end
mm_name_dict = {'January','February', 'March', 'April', 'May',...
    'June', 'July', 'August','September','October',...
    'November', 'December'};
mm_order_dict = cellfun(@(x, n) sprintf('%02.f.%s',n,x), ...
    mm_name_dict, num2cell(1:12),'un',0);
mm_short_dict = cellfun(@(x) x(1:3), mm_name_dict, 'un',0);


path = sprintf('%d/%s/%s', yy, ...
    mm_order_dict{mm}, ...
    sprintf('Data %d %s %d', dd, mm_short_dict{mm},yy));
end
