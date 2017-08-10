function outText = displayNewScope(fileName)
if ~nargin
    outText = 'New Scope';
    return
end

    whatKids = get(0, 'children');
    if isappdata(0, 'scopes')
        whatKids = [whatKids; getappdata(0, 'scopes')];
    end    
    figHandle = fix(rand * 255 + 1);
    while ismember(figHandle, whatKids)
        figHandle = fix(rand * 255 + 1);
    end
    setappdata(0, 'scopes', [getappdata(0, 'scopes'); figHandle]);
    
    if ~isempty(fileName)
    	clickTable(fileName);
    end