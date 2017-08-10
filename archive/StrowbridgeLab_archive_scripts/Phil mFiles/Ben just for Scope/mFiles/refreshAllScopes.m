function refreshAllScopes

    zData = evalin('base', 'zData');
        for i = getappdata(0, 'scopes')'
            if ishandle(i) && isappdata(i, 'extraPrintText')
                rmappdata(i, 'extraPrintText');
            end            
            newScope(zData.traceData, zData.protocol, i);
            set(i, 'name', zData.protocol(1).fileName);
        end