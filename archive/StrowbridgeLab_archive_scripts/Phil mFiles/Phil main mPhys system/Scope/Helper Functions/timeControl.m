function handles = timeControl(right, bottom)
handles.frame = uipanel(...
'units', 'characters',...
'Position',[right bottom 42 5],...
'resizefcn', [],...
'title', 'X Axis');

handles.displayText = uicontrol(...
'Parent',handles.frame,...
'Units','normalized',...
'HorizontalAlignment','center',...
'ListboxTop',0,...
'Position',[0.025 0.68 0.95 0.3],...
'String','0mV',...
'Style','text');

uicontrol(...
'Parent',handles.frame,...
'Units','normalized',...
'CData',[],...
'HorizontalAlignment','right',...
'ListboxTop',0,...
'Position',[0.025 0.4 0.1 0.3],...
'String','Min',...
'Style','text');

uicontrol(...
'Parent',handles.frame,...
'Units','normalized',...
'HorizontalAlignment','right',...
'ListboxTop',0,...
'Position',[0.525 0.4 0.1 0.3],...
'String','Max',...
'Style','text');

handles.minVal = uicontrol(...
'Parent',handles.frame,...
'Units','normalized',...
'HorizontalAlignment','right',...
'ListboxTop',0,...
'Position',[0.225 0.4 0.2 0.3],...
'String','0',...
'Style','edit',...
'enable', 'off',...
'callback', @newMin);

handles.maxVal = uicontrol(...
'Parent',handles.frame,...
'Units','normalized',...
'HorizontalAlignment','right',...
'ListboxTop',0,...
'Position',[0.6525 0.4 0.2 0.3],...
'String','1',...
'Style','edit',...
'enable', 'off',...
'callback', @newMax);

handles.autoScale = uicontrol(...
'Parent', handles.frame,...
'Units','normalized',...
'Position',[0.2 0.05 0.544444444444444 0.3],...
'String',{  'Auto' },...
'Style','checkbox',...
'value', 1,...
'callback', @autoScale);


function autoScale(varargin)
    handles = get(gcf, 'userdata');
    if get(handles.timeControl.autoScale, 'value') == 0
        set(handles.timeControl.minVal, 'enable', 'on');
        set(handles.timeControl.maxVal, 'enable', 'on');
        set(handles.axes, 'xlim', [str2double(get(handles.timeControl.minVal, 'string')) str2double(get(handles.timeControl.maxVal, 'string'))]); 
    else
        set(handles.timeControl.minVal, 'enable', 'off');
        set(handles.timeControl.maxVal, 'enable', 'off');
        set(handles.axes, 'xlim', [handles.minX handles.maxX]);         
    end
    newScale(gcf)
    
function newMax(varargin)
    handles = get(gcf, 'userdata');
    set(handles.axes, 'xlim', [min(get(handles.axes(1), 'xlim')) max([str2double(get(handles.timeControl.maxVal, 'string')) min(get(handles.axes(1), 'xlim')) + 1])]);
    newScale(gcf)
    
function newMin(varargin)
    handles = get(gcf, 'userdata');
    set(handles.axes, 'xlim', [min([str2double(get(handles.timeControl.minVal, 'string')) max(get(handles.axes(1), 'xlim')) - 1]) max(get(handles.axes(1), 'xlim'))]);    
    newScale(gcf)