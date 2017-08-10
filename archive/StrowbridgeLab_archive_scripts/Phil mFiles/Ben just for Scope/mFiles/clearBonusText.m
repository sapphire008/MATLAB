function clearBonusText(figHandle)
% this clears text to the top line of the Scope window
% figHandle is optional, if not supplied text added to all scope windows


if nargin < 1
    figHandle = getappdata(0, 'scopes');
end

setappdata(figHandle, 'extraPrintText', '');