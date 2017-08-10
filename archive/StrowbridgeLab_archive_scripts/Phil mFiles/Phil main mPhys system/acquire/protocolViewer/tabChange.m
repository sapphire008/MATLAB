function tabChange(varargin)
    if isempty(varargin)
        varargin{1} = gcbo;
    end
    info = getappdata(get(varargin{1}, 'parent'), 'tabData');
    n = find(info.tabButtons == varargin{1});
    set(info.lineHiders, 'visible', 'off');
    set(info.lineHiders(n), 'visible', 'on');
    set(info.panels, 'visible', 'off');
    set(info.panels(n), 'visible', 'on');  