function spikes = detectSpikesMs(inData, spikeHeight, whereCall, MsPerPoint)
% spikes = detectSpikes(inData, spikeHeight, whereCall)
% whereCall determines what is returned for spike locations
% whereCall = 1 => AP threshold
% whereCall = 2 => time midpoint of peak and threshold
% whereCall = 3 => height midpoint of peak and threshold (default)
% whereCall = 4 => peak
% whereCall = 5 => sloppy peak
% spikeHeight not specified => 25 mV above baseline
% the results are filtered such that spikes with a frequency of greater
% than one per every 10 samples will be rejected

warning off MATLAB:divideByZero

% outputs times of spikes by looking for a derivative change in a spot
% where inData > all points histogram mean + spikeHeight then finding the maximum of the second
% derivative in the period immediately before the spike, looking for the
% first time that the second derivative has a peak in that period that is
% at least 25% of that height, and then searching backward from that peak
% to the first time that the second derivative is less than 10% of that
% maximum peak

if nargin < 3
    whereCall = 4;
end

if nargin < 2
    spikeHeight = 25;
end

if size(inData, 1) > size(inData, 2)
    inData = inData';
end

if mean(inData) > spikeHeight || length(inData) < 5
    spikes = [];
    return
end

spikeHeight = max([-10 calcMean(inData) + spikeHeight]);

dataDerivative = diff(inData);
dataSecDerivative = [dataDerivative(2) - dataDerivative(1) diff(dataDerivative)];
spikes = find(inData(2:length(inData)-1) > spikeHeight & (dataDerivative(2:size(dataDerivative, 2)) ./ dataDerivative(1:size(dataDerivative, 2) -1) < 0 | dataDerivative(2:size(dataDerivative, 2)) == 0) & dataDerivative(1:size(dataDerivative, 2) - 1) > 0) + 1;

if whereCall == 5
    spikes = spikes([1 diff(spikes) > 20] == 1);
end

% remove any that are too close together
if ~isempty(spikes)
    spikes = spikes([diff(spikes) > 10 1] & [1 diff(spikes) > 10]);
end

% try to find the point at which threshold was crossed
for index = 1:length(spikes)
    whereStart = min([spikes(index) - 2 25]); % how far back from the peak to start looking for the threshold
	if index > 1
       whereStart = min([whereStart spikes(index) - spikes(index - 1)]); 
       if ~isnan(spikes(index - 1))
           if inData(spikes(index)) - min(inData(spikes(index - 1):spikes(index))) < 10
               spikes(index) = NaN;
               continue;
           elseif inData(spikes(index)) - min(inData(spikes(index) - 25:spikes(index))) < 10
               spikes(index) = NaN;
               continue;
           end
       end
	end
	
    try
    % find a spot that is an extreme of the second derivative AND is a maximum of the second derivative AND this point is greater than 25% of the maximum of the second derivative in the window	
	% look only in the window from the whereStart points before the peak of the AP to the peak
        wherePeak = find(...
            (diff(dataSecDerivative(spikes(index) - whereStart:spikes(index) - 1))./diff(dataSecDerivative(spikes(index) - whereStart + 1:spikes(index))) < 0 | dataSecDerivative(spikes(index) - whereStart + 1:spikes(index) - 1) == 0) &...
            diff(dataSecDerivative(spikes(index) - whereStart:spikes(index) - 1)) >= 0 &...
            dataSecDerivative(spikes(index) - whereStart + 1:spikes(index) - 1) > .25 * max(dataSecDerivative(spikes(index) - whereStart:spikes(index) - 1)), 1, 'last');
    catch
        spikes(index) = NaN;
        continue            
    end
	if length(wherePeak) < 1
        spikes(index) = NaN;
        continue        
	end
% 	figure
% 	plot(inData(spikes(index) - whereStart:spikes(index) - 1), 'color', [0 0 0]);
% 	hold on
% 	plot(1.5:1:whereStart + .5, dataDerivative(spikes(index) - whereStart:spikes(index) - 1), 'color', [1 0 0]);
% 	plot(dataSecDerivative(spikes(index) - whereStart:spikes(index) - 1), 'color', [0 0 1]);
% 	plot(wherePeak, 0, 'linestyle', 'none', 'marker', '+', 'color', [0 1 0]);
% 	plot(wherePeak - max([0 find(dataSecDerivative(spikes(index) - whereStart - 1 + wherePeak:-1:spikes(index) - whereStart - 1) < .1 * max(dataSecDerivative(spikes(index) - whereStart:spikes(index) - 1)) , 1, 'first')]) + 1, 0, 'linestyle', 'none', 'marker', '+', 'color', [1 0 1]);
% 	legend('Data', 'Data''', 'Data''''', 'wherePeak', 'threshLoc')
	
	% find where the peak in the second derivative was first more than 10% of the maximum second derivative in the window
	firstCross = find(dataSecDerivative(spikes(index) - whereStart - 1 + wherePeak:-1:spikes(index) - whereStart - 1) < .1 * max(dataSecDerivative(spikes(index) - whereStart:spikes(index) - 1)) , 1, 'first');
	if isempty(firstCross)
		% second derivative is bumpy (many local maxima and minima)
		firstCross = wherePeak;
% 		warning(['Threshold detection failed for spike ' num2str(index)]);
	end
	threshLoc = spikes(index) - whereStart + wherePeak - firstCross + 1;
    if isempty(threshLoc) || inData(spikes(index)) - inData(threshLoc) < spikeHeight
        spikes(index) = NaN;
        continue  
    end
    switch whereCall
        case 1
            spikes(index) = threshLoc;
        case 2
            spikes(index) = round((spikes(index) + threshLoc) / 2);               
        case 3
            [junk loc] = max(1 ./ ((inData(spikes(index)) + inData(threshLoc)) / 2 - inData(threshLoc:spikes(index))));
            spikes(index) = threshLoc + loc - 1;
        case 4
            spikes(index) = spikes(index);
    end
end
spikes = MsPerPoint .* spikes(~isnan(spikes));