function overlayPSPs(inData, timeWindow, startTimes, timePerPoint)
% display the PSPs for a given trace overlayed
    
    if nargin < 4
        timePerPoint = 200; %uSec
    end
    
    if nargin < 3
        PSPdata = detectPSPs(inData);
        startTimes = PSPdata(:,3);
    end

    if nargin < 2
        timeWindow = [-10 100];
    end
    
    if ~iscell(startTimes)
        startTimes = {startTimes};
    end
    
    howMany = 0;
    for epiIndex = 1:numel(startTimes)
    	startTimes{epiIndex} = startTimes{epiIndex}(startTimes{epiIndex} > - timeWindow(1) * 1000 / timePerPoint + 1 & startTimes{epiIndex} < length(inData) / 1000 * timePerPoint - timeWindow(2));
        howMany = howMany + numel(startTimes{epiIndex});
    end
    
    timeWindow = timeWindow(1) / (timePerPoint / 1000):timeWindow(2) / (timePerPoint / 1000);    
    dataVals = zeros(howMany, size(timeWindow, 2));
    whichPSP = 1;
    for epiIndex = 1:numel(startTimes)
        for i = 1:size(startTimes{epiIndex}, 1)
             dataVals(whichPSP, :) = inData(epiIndex, round(startTimes{epiIndex}(i) * 1000 / timePerPoint) + timeWindow);
             whichPSP = whichPSP + 1;
        end
    end

    newScope(dataVals', ((0:size(dataVals, 2) - 1) + timeWindow(1)) * timePerPoint / 1000);