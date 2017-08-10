function updateLabJack(varargin)

if get(findobj('tag', 'chkHighVoltage1'),'value')
    set(findobj('tag', 'chkCooling1'), 'value', 1);
    set(findobj('tag', 'chkFan1'), 'value', 1);
end
if get(findobj('tag', 'chkHighVoltage2'),'value')
    set(findobj('tag', 'chkCooling2'), 'value', 1);
    set(findobj('tag', 'chkFan2'), 'value', 1);
end    

currentState = 0;
currentState = currentState +  1 * get(findobj('tag', 'chkCooling1'),'value'); % peltier 1
currentState = currentState +  2 * get(findobj('tag', 'chkHighVoltage1'),'value'); % peltier 1
currentState = currentState +  4 * get(findobj('tag', 'chkFan1'),'value'); % fan 1
currentState = currentState +  8 * get(findobj('tag', 'chkCooling2'),'value'); % peltier 2
currentState = currentState + 16 * get(findobj('tag', 'chkHighVoltage2'),'value'); % peltier 1
currentState = currentState + 32 * get(findobj('tag', 'chkFan2'),'value'); % fan 2

realState = libpointer('int32Ptr', currentState);
if calllib('ljackuw', 'DigitalIO', 0, 0, 255, 0, realState, 0, 1, 0) ~= 0
    error('Error in labjack digital controls.  Power off PMT immediately.')
end
realState = get(realState, 'value');

if bitget(realState, 8)
    set(findobj('tag', 'pmtStatus1'), 'highLightColor', [0 0 0]);
else
    set(findobj('tag', 'pmtStatus1'), 'highLightColor', [1 1 1]);
end
if get(findobj('tag', 'chkCooling1'),'value') && bitget(realState, 9)
    set(findobj('tag', 'chkCooling1'),'value', 'foregroundColor', [0 0 0]);
else
    set(findobj('tag', 'chkCooling1'),'value', 'foregroundColor', [1 0 0]);
end
if bitget(realState, 10)
    set(findobj('tag', 'pmtStatus1'), 'foregroundColor', [1 0 0]);
else
    set(findobj('tag', 'pmtStatus1'), 'foregroundColor', [0 0 0]);
end

if bitget(realState, 11)
    set(findobj('tag', 'pmtStatus2'), 'highLightColor', [0 0 0]);
else
    set(findobj('tag', 'pmtStatus2'), 'highLightColor', [1 1 1]);
end
if get(findobj('tag', 'chkCooling2'),'value') && bitget(realState, 12)
    set(findobj('tag', 'chkCooling2'),'value', 'foregroundColor', [0 0 0]);
else
    set(findobj('tag', 'chkCooling2'),'value', 'foregroundColor', [1 0 0]);
end
if bitget(realState, 13)
    set(findobj('tag', 'pmtStatus2'), 'foregroundColor', [1 0 0]);
else
    set(findobj('tag', 'pmtStatus2'), 'foregroundColor', [0 0 0]);
end