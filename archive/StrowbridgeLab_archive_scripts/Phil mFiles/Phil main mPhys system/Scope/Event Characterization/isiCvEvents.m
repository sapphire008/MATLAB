function outText = isiCvEvents(varargin)
if ~nargin
    outText = 'CV of ISI';
else
    events = getappdata(gca, 'events');

    outValue = isiCv(events(varargin{5}).data');
    set(get(gca, 'userdata'), 'string', num2str(outValue));      
end