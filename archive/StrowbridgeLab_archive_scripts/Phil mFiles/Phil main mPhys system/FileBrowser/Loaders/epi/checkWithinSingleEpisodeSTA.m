function outText = checkWithinSingleEpisodeSTA(fileNames)

    if ~nargin
        outText = 'Event-Triggered Average';
        return
    end

    eventTriggeredAverage(fileNames, [], [], [], 0);