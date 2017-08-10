function averageOnly(PSPtype)

kids = get(gca, 'children');
for i = 1:length(kids)
    if get(kids(i), 'linewidth') == 0.5
        delete(kids(i));
    end
end

if nargin > 0
    kids = get(gca, 'children');
    if strcmp(PSPtype, 'up') || PSPtype == 0
        if all(get(kids(1), 'color') == [1 0 0]) && numel(kids) > 1
            delete(kids(2));
        else
            delete(kids(1));
        end
    else
        if all(get(kids(1), 'color') == [1 0 0])
            delete(kids(1));
        elseif numel(kids) > 1
            delete(kids(2));
        end        
    end
end