dataRoot = 'W:\Larimer\';

eData = {...
    '2005\August\August 1 2005\Cell D.01Aug05.S1.E9.dat'...
    '2005\August\August 3 2005\Cell D.03Aug05.S1.E23.dat',... 
    '2005\August\August 3 2005\Cell C.03Aug05.S1.E26.dat',... 
    '2005\August\August 4 2005\Cell B.04Aug05.S1.E4.dat',...     
    '2005\August\August 4 2005\Cell A.04Aug05.S1.E7.dat',...     
    '2005\August\August 5 2005\Cell D.05Aug05.S1.E7.dat',...   
    '2005\August\August 5 2005\Cell C.05Aug05.S1.E10.dat',...                    
    '2006\September\September 28 2006\Cell E.28Sep06.S1.E10.dat',...       
    '2006\September\September 28 2006\Cell D.28Sep06.S1.E8.dat',...        
    '2006\September\September 28 2006\Cell B.28Sep06.S1.E5.dat',...     
    '2006\October\October 3 2006\Cell F.03Oct06.S1.E12.dat',...                                
    };
    
iData = {...
    '2005\August\August 1 2005\Cell D.01Aug05.S1.E10.dat',...
    '2005\August\August 3 2005\Cell D.03Aug05.S1.E24.dat',...
    '2005\August\August 3 2005\Cell C.03Aug05.S1.E25.dat',...
    '2005\August\August 4 2005\Cell B.04Aug05.S1.E5.dat',...    
    '2005\August\August 4 2005\Cell A.04Aug05.S1.E6.dat',...    
    '2005\August\August 5 2005\Cell D.05Aug05.S1.E6.dat',...      
    '2005\August\August 5 2005\Cell C.05Aug05.S1.E8.dat',...     
    '2006\September\September 28 2006\Cell E.28Sep06.S1.E11.dat',...        
    '2006\September\September 28 2006\Cell D.28Sep06.S1.E9.dat',...            
    '2006\September\September 28 2006\Cell B.28Sep06.S1.E6.dat',...       
    '2006\October\October 3 2006\Cell F.03Oct06.S1.E11.dat',...  
    };
    
eEvents = {};
xData = 1:59999;
for i = eData
    zData = readBen([dataRoot i{1}]);
    stimTimes = findStims(zData.protocol);
    tempEvents = detectPSPs(zData.traceData(stimTimes{2}(1,1) + (xData-10000), whichChannel(zData.protocol, 1, 'I')), 1, 'minAmp', -2000, 'maxAmp', -15, 'minTau', 10, 'maxTau', 1000, 'minYOffset', -Inf, 'maxYOffset', Inf, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 11, 'derFilterLength', 7, 'debugging', 0, 'dataStart', 0.2, 'forceDisplay',  0, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0);
    eEvents{end + 1} = tempEvents(:,3);
end

iEvents = {};
xData = 1:59999;
for i = iData
    zData = readBen([dataRoot i{1}]);
    stimTimes = findStims(zData.protocol);
    tempEvents = detectPSPs(zData.traceData(stimTimes{2}(1,1) + (xData-10000), whichChannel(zData.protocol, 1, 'I')), 0, 'minAmp', 5, 'maxAmp', 2000, 'minTau', 40, 'maxTau', 4000, 'minYOffset', -Inf, 'maxYOffset', Inf, 'minDecay', 5, 'maxDecay', 500, 'derThresh', 1, 'closestEPSPs', 5, 'errThresh', 0.08, 'dataFilterType', 1, 'derFilterType', 3, 'dataFilterLength', 11, 'derFilterLength', 7, 'debugging', 0, 'dataStart', 0.05, 'forceDisplay',  0, 'alphaFit', 0, 'decayFit', 0, 'riseFit', 0);
    iEvents{end + 1} = tempEvents(:,3);
end

metaEvents = [];
for i = 1:numel(iEvents)
    metaEvents = [metaEvents; iEvents{i}];
end

events = iEvents;
figure
bins = 0:1000:45000;
counts = zeros(numel(bins), numel(events));
for i = 1:numel(events)
    counts(:,i) = counts(:,i) + histc(events{i}, bins);
end
line(bins / 5 + 1000, mean(counts, 2), 'color', 'k');
line(bins / 5 + 1000, mean(counts, 2) + std(counts, 1, 2), 'color', 'r');
line(bins / 5 + 1000, mean(counts, 2) - std(counts, 1, 2), 'color', 'r');
    
events = metaEvents';
xStep = 1;
filterLength = 2500;

yData = zeros(size(xData));
% this is simply a boxcar filter, but implemented using the
% filter command it took 100x longer
changeData = ones(1, 2 * numel(events));
changeData(end/2 + 1:end) = -1;
whereData = [round((events) / xStep - filterLength / 2) round((events) / xStep) + filterLength / 2 + 1];
[whereData indices] = sort(whereData);           
lastSum = sum(whereData <= 0);
yData(1:whereData(lastSum + 1)) = lastSum / (filterLength * xStep / 1000);
for j = lastSum + 1:min([find(whereData < length(yData), 1, 'last') - 1 size(whereData, 2) - 1]);
    lastSum = lastSum + changeData(indices(j));
    yData(whereData(j):whereData(j + 1)) = lastSum / (filterLength * xStep / 1000);
end

figure, plot((xData(1:end - filterLength)-10000)/5, yData(1:end - filterLength)/ numel(eData));