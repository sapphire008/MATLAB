function events = detectExtracellular(inData, timePerPoint)
    if ~nargin
        events = 'Extracellular Units';
    else
        events = MTEO(inData, round(1/timePerPoint), -1.5)';   
    end