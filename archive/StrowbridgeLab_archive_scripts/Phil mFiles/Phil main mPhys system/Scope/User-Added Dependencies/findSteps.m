function [stepData stimLength channels] = findSteps(protocol, ampNum)
% function stepData = findSteps(protocol, ampNum)
% stepData is of the form [stepNumber, [changeTime changeAmplitude]]
% or if no ampNum is passed then [ampNumber, stepNumber, [changeTime changeAmplitude]]

if nargin < 2
    % look at all amps
    stepData = [];
    stimLength = [];
    channels = [];
    for i = find(cellfun(@(x) strcmp(x(end - 1:end), 'CC'), protocol.ampTypeName))
        stimData = findSteps(protocol, i);
        
        if ~isempty(stimData)
            % find the positive deflections
            tempStims = stimData(stimData(:, 2) > 0, 1)';
            if numel(tempStims) > 1
                stepData(end + 1:end + 2, 1) = tempStims(1:2);
                dataChannel = whichChannel(protocol, i);
                if isempty(dataChannel)
                        stepData = [];
                        stimLength = [];
                        channels = [];
                        return
                end
                channels(end + 1) = dataChannel;

                if isempty(stimLength)
                    stimLength = diff(stimData(find(stimData(:, 2) > 0, 1, 'first') + (0:1), 1));
                    stimLength = stimLength(1);
                else
                    if stimLength ~= diff(stimData(find(stimData(:, 2) > 0, 1, 'first') + (0:1), 1))
                        stepData = [];
                        stimLength = [];
                        channels = [];
                        return
                    end
                end        
            end
        end
    end
    return
end

changeTimes = [];
intensityChanges = [];
if protocol.ampMonitorRin{ampNum}
    changeTimes = [changeTimes 10 100];
    if strcmp(protocol.ampTypeName{ampNum}(end - 1:end), 'CC')
        intensityChanges = [intensityChanges protocol.ampBridgeBalanceStep{ampNum} -protocol.ampBridgeBalanceStep{ampNum}];
    else
        intensityChanges = [intensityChanges protocol.ampSealTestStep{ampNum} -protocol.ampSealTestStep{ampNum}];        
    end
end
if protocol.ampEnable{ampNum} && protocol.ampStimEnable{ampNum}
    if protocol.ampStepEnable{ampNum}
        amplitudes = protocol.ampStepInitialAmplitude{ampNum};
        if protocol.ampStep1Enable{ampNum}
            changeTimes = [changeTimes protocol.ampStep1Start{ampNum} protocol.ampStep1Stop{ampNum}];
            amplitudes = [amplitudes protocol.ampStep1Amplitude{ampNum}];
        end
        if protocol.ampStep2Enable{ampNum}
            changeTimes = [changeTimes protocol.ampStep2Stop{ampNum}];
            amplitudes = [amplitudes protocol.ampStep2Amplitude{ampNum}];
        end
        if protocol.ampStep3Enable{ampNum}
            changeTimes = [changeTimes protocol.ampStep3Stop{ampNum}];
            amplitudes = [amplitudes protocol.ampStep3Amplitude{ampNum}];
        end                
        amplitudes = [amplitudes protocol.ampStepLastAmplitude{ampNum}];
        if numel(amplitudes) > 2 % otherwise we haven't added any info
            intensityChanges = [intensityChanges diff(amplitudes)];
        end
    end % if stepEnable
    
%     if protocol.ampPspEnable{ampNum}
%         changeTimes = [changeTimes protocol.ampPspStart{ampNum}:protocol.ampPspInterval{ampNum}:protocol.sweepWindow];
%         intensityChanges = [intensityChanges protocol.ampPspPeak{ampNum} .* ones(1, (protocol.sweepWindow - protocol.ampPspStart{ampNum}) / protocol.ampPspInterval{ampNum} + 1)];
%         changeTimes = [changeTimes (protocol.ampPspStart{ampNum}:protocol.ampPspInterval{ampNum}:protocol.sweepWindow) + protocol.ampPspTau{ampNum}];
%         intensityChanges = [intensityChanges -protocol.ampPspPeak{ampNum} .* ones(1, (protocol.sweepWindow - protocol.ampPspStart{ampNum}) / protocol.ampPspInterval{ampNum} + 1)];
%     end

    if protocol.ampTrainEnable{ampNum}
        changeTimes = [changeTimes protocol.ampTrainStart{ampNum}:protocol.ampTrainOnDuration{ampNum} + protocol.ampTrainOffDuration{ampNum}:protocol.sweepWindow];
        intensityChanges = [intensityChanges protocol.ampTrainAmplitude{ampNum} .* ones(1, (protocol.sweepWindow - protocol.ampTrainStart{ampNum}) / (protocol.ampTrainOnDuration{ampNum} + protocol.ampTrainOffDuration{ampNum}) + 1)];
        changeTimes = [changeTimes protocol.ampTrainStart{ampNum} + protocol.ampTrainOnDuration{ampNum}:protocol.ampTrainOnDuration{ampNum} + protocol.ampTrainOffDuration{ampNum}:protocol.sweepWindow];
        intensityChanges = [intensityChanges -protocol.ampTrainAmplitude{ampNum} .* ones(1, (protocol.sweepWindow - protocol.ampTrainStart{ampNum} - protocol.ampTrainOnDuration{ampNum}) / (protocol.ampTrainOnDuration{ampNum} + protocol.ampTrainOffDuration{ampNum}) + 1)];						
    end

    if protocol.ampPulseEnable{ampNum}
        if protocol.ampPulse1Stop{ampNum} > protocol.ampPulse1Start{ampNum}
            changeTimes = [changeTimes protocol.ampPulse1Start{ampNum}];
            intensityChanges = [intensityChanges protocol.ampPulse1Amplitude{ampNum}];
            changeTimes = [changeTimes protocol.ampPulse1Stop{ampNum}];
            intensityChanges = [intensityChanges -protocol.ampPulse1Amplitude{ampNum}];
        end
        if protocol.ampPulse2Stop{ampNum} > protocol.ampPulse2Start{ampNum}
            changeTimes = [changeTimes protocol.ampPulse2Start{ampNum}];
            intensityChanges = [intensityChanges protocol.ampPulse2Amplitude{ampNum}];
            changeTimes = [changeTimes protocol.ampPulse2Stop{ampNum}];
            intensityChanges = [intensityChanges -protocol.ampPulse2Amplitude{ampNum}];
        end
        if protocol.ampPulse3Stop{ampNum} > protocol.ampPulse3Start{ampNum}
            changeTimes = [changeTimes protocol.ampPulse3Start{ampNum}];
            intensityChanges = [intensityChanges protocol.ampPulse3Amplitude{ampNum}];
            changeTimes = [changeTimes protocol.ampPulse3Stop{ampNum}];
            intensityChanges = [intensityChanges -protocol.ampPulse3Amplitude{ampNum}];
        end
        if protocol.ampPulse4Stop{ampNum} > protocol.ampPulse4Start{ampNum}
            changeTimes = [changeTimes protocol.ampPulse4Start{ampNum}];
            intensityChanges = [intensityChanges protocol.ampPulse4Amplitude{ampNum}];
            changeTimes = [changeTimes protocol.ampPulse4Stop{ampNum}];
            intensityChanges = [intensityChanges -protocol.ampPulse4Amplitude{ampNum}];
        end
        if protocol.ampPulse5Stop{ampNum} > protocol.ampPulse5Start{ampNum}
            changeTimes = [changeTimes protocol.ampPulse5Start{ampNum}];
            intensityChanges = [intensityChanges protocol.ampPulse5Amplitude{ampNum}];
            changeTimes = [changeTimes protocol.ampPulse5Stop{ampNum}];
            intensityChanges = [intensityChanges -protocol.ampPulse5Amplitude{ampNum}];
        end
    end % if pulseEnable
end
if ~isempty(changeTimes)
    stepData = sortrows([changeTimes' intensityChanges']);
    i = 1;
    while i < size(stepData, 1)
        if stepData(i + 1, 1) == stepData(i, 1)
            stepData(i, 2) = stepData(i, 2) + stepData(i + 1, 2);
            stepData(i + 1, :) = [];
        end
        i = i + 1;
    end    
else
    stepData = [];
end % if ampEnable