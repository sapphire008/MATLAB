function stimTimes = findStims(protocol, isIndex)     
% stimTimes is a cell array of n x 2 matrices where column one is the
% start, and column two is the stop time for stimuli

if nargin < 2
    isIndex = 0;
end

for ttlIndex = 1:numel(protocol.ttlEnable)
    stimTimes{ttlIndex} = [];
    if protocol.ttlEnable{ttlIndex}
        if protocol.ttlStepEnable{ttlIndex}
            stimTimes{ttlIndex}(end + 1, 1) = protocol.ttlStepLatency{ttlIndex};
            stimTimes{ttlIndex}(end, 2) = protocol.ttlStepLatency{ttlIndex} + protocol.ttlStepDuration{ttlIndex};
        end

        if protocol.ttlPulseEnable{ttlIndex}
            if protocol.ttlArbitraryEnable{ttlIndex}
                tempTimes = str2num(protocol.ttlArbitrary{ttlIndex});
                stimTimes{ttlIndex}(end + (1:numel(tempTimes)), 1) = tempTimes;
                stimTimes{ttlIndex}(end - numel(tempTimes) + 1:end, 2) = stimTimes{ttlIndex}(end - numel(tempTimes) + 1:end, 1) + protocol.ttlPulseDuration{ttlIndex}/1000;
            end

            if protocol.ttlTrainEnable{ttlIndex}
                for j = 1:protocol.ttlTrainNumber{ttlIndex}
                    if protocol.ttlBurstEnable{ttlIndex}
                        stimTimes{ttlIndex}(end + (1:protocol.ttlBurstNumber{ttlIndex}),1) = (protocol.ttlTrainLatency{ttlIndex} + (j - 1) * protocol.ttlTrainInterval{ttlIndex} + (0:protocol.ttlBurstNumber{ttlIndex} - 1) * protocol.ttlBurstInterval{ttlIndex});
                        stimTimes{ttlIndex}(end - protocol.ttlBurstNumber{ttlIndex} + 1:end, 2) = stimTimes{ttlIndex}(end - protocol.ttlBurstNumber{ttlIndex} + 1:end, 1) + protocol.ttlPulseDuration{ttlIndex}/1000;
                    else
                        stimTimes{ttlIndex}(end + 1, 1) = protocol.ttlTrainLatency{ttlIndex} + (j - 1) * protocol.ttlTrainInterval{ttlIndex};
                        stimTimes{ttlIndex}(end, 2) = stimTimes{ttlIndex}(end, 1) + protocol.ttlPulseDuration{ttlIndex}/1000;
                    end
                end
            end
        end
    end

    if ~isIndex
        % output in matrix indices instead of msec
        stimTimes{ttlIndex} = stimTimes{ttlIndex} .* 1000 ./ protocol.timePerPoint;
    end    
end