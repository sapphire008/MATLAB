function addBonusText(text, figHandle)
% this adds text to the top line of the Scope window
% figHandle is optional, if not supplied text added to all scope windows


if nargin < 1 || ~ischar(text)
    error('First arguement must be a character array');
end
if nargin < 2
    figHandle = getappdata(0, 'scopes');
end

if strcmp(text, '')
    setappdata(figHandle, 'extraPrintText', '');
else
    setappdata(figHandle, 'extraPrintText', [getappdata(figHandle(1), 'extraPrintText') text]);
end