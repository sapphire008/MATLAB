function outText = checkWithinSingleEpisodeCVA(fileNames)

    if ~nargin
        outText = 'Event-Triggered Covariance Analysis';
        return
    end
       
    eventTriggeredAverage(fileNames, [], [], [], -1);