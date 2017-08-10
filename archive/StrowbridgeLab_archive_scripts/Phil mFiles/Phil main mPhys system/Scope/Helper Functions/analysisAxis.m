function axisHandle = analysisAxis(plotName, axisHandle)
    % called by other functions to add an analysis axis
    handles = get(gcf, 'userData');
    
    if nargin < 2
        whichAxis = find(handles.axes == gca);
    else
        whichAxis = find(handles.axes == axisHandle);
    end
    
    if isfield(handles.analysisAxis{whichAxis}, plotName)
        delete(handles.analysisAxis{whichAxis}.(plotName));
        handles.analysisAxis{whichAxis} = rmfield(handles.analysisAxis{whichAxis}, plotName);
    end        
    
    set(handles.axes(whichAxis), 'color', 'none');
    handles.analysisAxis{whichAxis}.(plotName) = axes('Units', get(handles.axes(whichAxis), 'units'),...
        'position', get(handles.axes(whichAxis), 'position'),...
        'parent', get(handles.axes(whichAxis), 'parent'),...
        'yaxislocation', 'right',...
        'color', [1 1 1],...
        'xgrid', 'off', 'ygrid', 'off',...
        'xtick', [],...
        'box', 'off');
    
    % make sure that the original trace is on top
    children = get(gcf, 'children');
    tempAxis = find(children == handles.axes(whichAxis));
    tempChild = children(tempAxis);
    children(tempAxis) = children(children == handles.analysisAxis{whichAxis}.(plotName));
    children(find(children == handles.analysisAxis{whichAxis}.(plotName), 1, 'first')) = tempChild;
    set(gcf, 'children', children); 
    
    % lock the axes together
    linkaxes([handles.axes(whichAxis) struct2array(handles.analysisAxis{whichAxis})], 'x');
    tempFields = fieldnames(handles.analysisAxis{whichAxis});
    if numel(tempFields) > 2
%         linkaxes([handles.analysisAxis{whichAxis}.(tempFields{end - 1}) handles.analysisAxis{whichAxis}.(plotName)], 'y');
        set(handles.analysisAxis{whichAxis}.(plotName), 'color', 'none');
    end    
    
    set(gcf, 'userData', handles, 'currentAxes', handles.axes(whichAxis));
    
    axisHandle = handles.analysisAxis{whichAxis}.(plotName);