function changeTimePerPoint

% called after the acquisition rate (in kHz) is changed

handles = guihandles(gcf);

choices = get(handles.acquisitionRate, 'string');
if get(handles.acquisitionRate, 'value') ~= numel(choices)
    set(handles.timePerPoint, 'string', num2str(1000 / str2double(choices(get(handles.acquisitionRate, 'value')))));
end