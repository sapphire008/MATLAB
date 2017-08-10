function events = detectCellAttached(inData, timePerPoint)
    if ~nargin
        events = 'Cell-Attached Spikes';
    else
        events = MTEO(inData, round(1/timePerPoint), -10)';    
    end