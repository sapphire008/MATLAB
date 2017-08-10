function [sorted_names, index, components] = eph_sort_cell_by_date(names)
% splitting: ID, date, series, episode
components = regexp(names(:), '\.', 'split');
% convert the specified datestr to datenum
for n = 1:length(components)
    components(n,1:length(components{n})) = components{n};
    components{n,2} = convertDate2Num(components{n,2}, true);
end
% Sort rows
if size(components, 2)>=4
    [~, index] = sortrows(components, [2, 1, 3, 4]);
else
    [~, index] = sortrows(components, [2, 1]);
end
sorted_names = names(index);
if nargout>2
    components(:,2) = cellfun(@(x) datestr(x, 'ddmmmyy'), components(:,2), 'un',0);
end
end

function dmy = convertDate2Num(date, month_shorthand)
dmy = regexp(date, '(\d)*([a-z_A-Z])*(\d)*', 'tokens');
dmy = dmy{1};
Month_dict = {'January','February','March','April','May','June','July','August',...
    'September','October','November','December'};
if month_shorthand
    Month_dict = cellfun(@(x) x(1:3), Month_dict, 'un',0);
end
dmy{1} = str2num(dmy{1});
dmy{2} = find(ismember( Month_dict, dmy{2}));
dmy{3} = str2num(dmy{3});
dmy = datenum(dmy{3}, dmy{2}, dmy{1});
end