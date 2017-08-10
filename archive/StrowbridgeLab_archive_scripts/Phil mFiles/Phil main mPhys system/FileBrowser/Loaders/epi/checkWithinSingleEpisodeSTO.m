function outText = checkWithinSingleEpisodeSTO(fileNames)

    if ~nargin
        outText = 'Event-Triggered Overlay';
        return
    end
       
    eventTriggeredAverage(fileNames, [], [], [], 1);