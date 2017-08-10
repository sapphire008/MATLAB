function events = detectWCAPs(inData, timePerPoint)
    if ~nargin
        events = 'Action Potentials';
    else
        events = detectSpikes(inData);    
    end