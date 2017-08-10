function updateLaserIntensity(varargin)

    driveVoltage = 2 - 2 * str2double(get(findobj(getappdata(0, 'rasterScan'), 'tag', 'txtLaserIntensity'), 'string')) / 100;                
    if calllib('ljackuw', 'EAnalogOut', 0, 0, get(findobj(getappdata(0, 'rasterScan'), 'tag', 'pmtGain1'),'value') * 0.9, driveVoltage) ~=0
        error('Error sending PMT gain settting to lab jack');
    end
