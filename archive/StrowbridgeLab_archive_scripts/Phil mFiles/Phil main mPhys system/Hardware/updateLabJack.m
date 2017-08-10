function updateLabJack(varargin)

    halogenMonitor = timerfind('name', 'halogenMonitor');
    if ~isempty(halogenMonitor)
        stop(halogenMonitor);
        delete(halogenMonitor);
    end
        
    if get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkHighVoltage1'),'value')
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling1'), 'value', 1);
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkFan1'), 'value', 1);
        
        % start a timer to monitor the halogen intensity to protect the PMT
        start(timer('name', 'halogenMonitor', 'TimerFcn','checkHalogen', 'Period', 0.1, 'executionMode', 'fixedDelay', 'busyMode', 'drop'));
    end
    if get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkHighVoltage2'),'value')
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling2'), 'value', 1);
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkFan2'), 'value', 1);
        if isempty(timerfind('name', 'halogenMonitor'))
            start(timer('name', 'halogenMonitor', 'TimerFcn','checkHalogen', 'Period', 0.1, 'executionMode', 'fixedDelay', 'busyMode', 'drop'));
        end
    end    

    currentState = 0;
    currentState = currentState +  1 * get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling1'),'value'); % peltier 1
    currentState = currentState +  2 * get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkHighVoltage1'),'value'); % peltier 1
    currentState = currentState +  4 * ~get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkFan1'),'value'); % fan 1
    currentState = currentState +  8 * get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling2'),'value'); % peltier 2
    currentState = currentState + 16 * get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkHighVoltage2'),'value'); % peltier 1
    currentState = currentState + 32 * ~get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkFan2'),'value'); % fan 2

    realState = libpointer('int32Ptr', currentState);
    if calllib('ljackuw', 'DigitalIO', 0, 0, 255, 0, realState, 0, 1, 0) ~= 0
        error('Error in labjack digital controls.  Power off PMT immediately.')
    end
    realState = uint32(get(realState, 'value'));

    if bitget(realState, 8)
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus1'), 'highLightColor', [0 0 0]);
    else
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus1'), 'highLightColor', [1 1 1]);
    end
    if get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling1'),'value') && bitget(realState, 9)
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling1'), 'foregroundColor', [0 0 0]);
    else
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling1'), 'foregroundColor', [1 0 0]);
    end
    if bitget(realState, 10)
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus1'), 'foregroundColor', [1 0 0]);
    else
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus1'), 'foregroundColor', [0 0 0]);
    end

    if bitget(realState, 11)
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus2'), 'highLightColor', [0 0 0]);
    else
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus2'), 'highLightColor', [1 1 1]);
    end
    if get(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling2'),'value') && bitget(realState, 12)
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling2'), 'foregroundColor', [0 0 0]);
    else
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkCooling2'), 'foregroundColor', [1 0 0]);
    end
    if bitget(realState, 13)
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus2'), 'foregroundColor', [1 0 0]);
    else
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtStatus2'), 'foregroundColor', [0 0 0]);
    end