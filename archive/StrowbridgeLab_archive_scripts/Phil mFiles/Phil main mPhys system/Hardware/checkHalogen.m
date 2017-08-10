function checkHalogen(varargin)  
% checks for voltage to the halogen and kills the PMT

    overVolt = libpointer('int32Ptr',0);
    voltage = libpointer('singlePtr',0);
    if calllib('ljackuw', 'EAnalogIn', -1, 0, 9, 1, overVolt, voltage) ~=0
        error('Error in reading halogen state from lab jack.  PMT is not protected.');
    end
    if abs(get(voltage, 'value')) > 0.5
        % kill the high voltage
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkHighVoltage1'), 'value', 0);
        set(findobj(getappdata(0, 'rasterScan'), 'tag', 'chkHighVoltage2'), 'value', 0);
        updateLabJack;
    end