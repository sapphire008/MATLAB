function [digOut DAC] = generateStim(protocolData, experimentData)
% generates a stimulus vector that is numPoints by numChannels and starts
% with any enabled TTLs and then enabled amps.  Outputs are in pa/mV

if nargin < 1
    protocolData = getappdata(0, 'currentProtocol');
end
if nargin < 2
    experimentData = getappdata(0, 'currentExperiment');
end

% check for error
if ~isfinite(protocolData.sweepWindow)
	error('Streaming episodes not currently supported')
end

% determine the total number of outputs
digitalOuts = sum(cell2mat(experimentData.ttlEnable));
if isfield(experimentData, 'ampEnable')
	analogOuts = sum(cell2mat(experimentData.ampEnable) & (cell2mat(protocolData.ampTpEnable) | cell2mat(protocolData.ampMonitorRin) | (cell2mat(protocolData.ampStimEnable) & (cell2mat(protocolData.ampStepEnable) | cell2mat(protocolData.ampPspEnable) | cell2mat(protocolData.ampSineEnable) | cell2mat(protocolData.ampCosineEnable) | cell2mat(protocolData.ampRampEnable) | cell2mat(protocolData.ampTrainEnable) | cell2mat(protocolData.ampPulseEnable) | ~cellfun('isempty', protocolData.ampMatlabStim))) | ~cellfun('isempty', protocolData.ampMatlabCommand)));
else
	analogOuts = 0;
end
digOut = zeros(protocolData.sweepWindow * 1000 / protocolData.timePerPoint, digitalOuts);
DAC = zeros(protocolData.sweepWindow * 1000 / protocolData.timePerPoint, analogOuts);
channelNum = 0;
pointsPerMsec = 1000 / protocolData.timePerPoint;

% generate vectors for ttls
if find(cell2mat(experimentData.ttlEnable))
    for ttlIndex = find(cell2mat(experimentData.ttlEnable))'
        channelNum = channelNum + 1;

        % step
        if protocolData.ttlStepEnable{ttlIndex}
            digOut(protocolData.ttlStepLatency{ttlIndex} * pointsPerMsec:(protocolData.ttlStepLatency{ttlIndex} + protocolData.ttlStepDuration{ttlIndex}) * pointsPerMsec, channelNum) = 1;
        end

        % pulses
        if protocolData.ttlPulseEnable{ttlIndex}
            pulsePoints = round(protocolData.ttlPulseDuration{ttlIndex} / protocolData.timePerPoint);           
            
            if pulsePoints < 1
                error('TTL pulse too short for acquisition rate');
            end
            % arbitrary
            if protocolData.ttlArbitraryEnable{ttlIndex}
                whichPoints = eval(protocolData.ttlArbitrary{ttlIndex}) * pointsPerMsec;
                digOut((whichPoints:whichPoints + pulsePoints) + 1, channelNum) = 1;
            end

            % train
            if protocolData.ttlTrainEnable{ttlIndex}
                for trainIndex = 0:protocolData.ttlTrainNumber{ttlIndex} - 1
                    if protocolData.ttlBurstEnable{ttlIndex}
                        % train of bursts
                        for burstIndex = 0:protocolData.ttlBurstNumber{ttlIndex} - 1
                            digOut((protocolData.ttlTrainLatency{ttlIndex} + trainIndex * protocolData.ttlTrainInterval{ttlIndex} + burstIndex * protocolData.ttlBurstInterval{ttlIndex}) * pointsPerMsec + (1:pulsePoints), channelNum) = 1;                    
                        end
                    else
                        digOut((protocolData.ttlTrainLatency{ttlIndex} + trainIndex * protocolData.ttlTrainInterval{ttlIndex}) * pointsPerMsec + (1:pulsePoints), channelNum) = 1;                    
                    end
                end
            end
        end   
    end
end
            
% generate vectors for amps
if analogOuts > 0
	channelNum = 0;
	ampStrings = '';%getpref('amplifiers', 'amplifiers');
	for ampIndex = find(cell2mat(experimentData.ampEnable) & (cell2mat(protocolData.ampTpEnable) | cell2mat(protocolData.ampMonitorRin) | (cell2mat(protocolData.ampStimEnable) & (cell2mat(protocolData.ampStepEnable) | cell2mat(protocolData.ampPspEnable) | cell2mat(protocolData.ampSineEnable) | cell2mat(protocolData.ampCosineEnable) | cell2mat(protocolData.ampRampEnable) | cell2mat(protocolData.ampTrainEnable) | cell2mat(protocolData.ampPulseEnable) | ~cellfun('isempty', protocolData.ampMatlabStim))) | ~cellfun('isempty', protocolData.ampMatlabCommand)))'
		channelNum = channelNum + 1;

		% monitor Rin
		if protocolData.ampMonitorRin{ampIndex}
			if strcmp(ampStrings{protocolData.ampType{ampIndex}}(end - 1:end), 'CC')
				DAC(10 * pointsPerMsec:100*pointsPerMsec, channelNum) = protocolData.ampBridgeBalanceStep{ampIndex};
			else
				DAC(10 * pointsPerMsec:70*pointsPerMsec, channelNum) = protocolData.ampSealTestStep{ampIndex};			
			end
		end

		% stimulus
        if protocolData.ampStimEnable{ampIndex}
			% Step
			if protocolData.ampStepEnable{ampIndex}
				changeTimes = 1/pointsPerMsec;
				amplitudes = protocolData.ampStepInitialAmplitude{ampIndex};
				if protocolData.ampStep1Enable{ampIndex}
					changeTimes = [changeTimes protocolData.ampStep1Start{ampIndex} protocolData.ampStep1Stop{ampIndex}];
					amplitudes = [amplitudes protocolData.ampStep1Amplitude{ampIndex}];
				end
				if protocolData.ampStep2Enable{ampIndex}
					changeTimes = [changeTimes protocolData.ampStep2Stop{ampIndex}];
					amplitudes = [amplitudes protocolData.ampStep2Amplitude{ampIndex}];
				end
				if protocolData.ampStep3Enable{ampIndex}
					changeTimes = [changeTimes protocolData.ampStep3Stop{ampIndex}];
					amplitudes = [amplitudes protocolData.ampStep3Amplitude{ampIndex}];
				end                
				changeTimes = [changeTimes protocolData.sweepWindow + 1/pointsPerMsec];
				amplitudes = [amplitudes protocolData.ampStepLastAmplitude{ampIndex}];

				for i = 1:numel(changeTimes) - 1
					DAC(changeTimes(i) * pointsPerMsec:changeTimes(i + 1) * pointsPerMsec - 1, channelNum) = DAC(changeTimes(i) * pointsPerMsec:changeTimes(i + 1) * pointsPerMsec - 1, channelNum) + amplitudes(i);
				end
			end

			% PSP
			if protocolData.ampPspEnable{ampIndex}
				functionToZero = 10 * protocolData.ampPspTau{ampIndex}; % time for the function to decay back to zero
				singlePSP = (protocolData.ampPspPeak{ampIndex} .* exp(1) .* (0:protocolData.timePerPoint / 1000:functionToZero) / protocolData.ampPspTau{ampIndex} .* exp(-(0:protocolData.timePerPoint / 1000:functionToZero) / protocolData.ampPspTau{ampIndex}))';   

				for i = 0:protocolData.ampPspNumber{ampIndex} - 1
					dataStart = protocolData.ampPspStart{ampIndex} + i * protocolData.ampPspInterval{ampIndex} ;
					if dataStart + functionToZero  > protocolData.sweepWindow
						dataEnd = protocolData.sweepWindow;
					else
						dataEnd = dataStart + functionToZero;
					end
					DAC(dataStart * pointsPerMsec:dataEnd * pointsPerMsec, channelNum)  = DAC(dataStart * pointsPerMsec:dataEnd * pointsPerMsec, channelNum) + singlePSP(1:(dataEnd - dataStart) * pointsPerMsec + 1);
				end            
			end

			% Sine / Cosine
            if protocolData.ampSineEnable{ampIndex}
				DAC(protocolData.ampSineStart{ampIndex} * pointsPerMsec:protocolData.ampSineStop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampSineStart{ampIndex} * pointsPerMsec:protocolData.ampSineStop{ampIndex} * pointsPerMsec, channelNum) + (protocolData.ampSineOffset{ampIndex} + protocolData.ampSineAmplitude{ampIndex} .* sin((2*pi) * protocolData.ampSineFrequency{ampIndex} / (1000 * pointsPerMsec) * (0:(protocolData.ampSineStop{ampIndex} - protocolData.ampSineStart{ampIndex}) * pointsPerMsec)))';
            end
            try
                if protocolData.ampCosineEnable{ampIndex}
                    DAC(protocolData.ampSineStart{ampIndex} * pointsPerMsec:protocolData.ampSineStop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampSineStart{ampIndex} * pointsPerMsec:protocolData.ampSineStop{ampIndex} * pointsPerMsec, channelNum) + (protocolData.ampSineOffset{ampIndex} + protocolData.ampSineAmplitude{ampIndex} .* cos((2*pi) * protocolData.ampSineFrequency{ampIndex} / (1000 * pointsPerMsec) * (0:(protocolData.ampSineStop{ampIndex} - protocolData.ampSineStart{ampIndex}) * pointsPerMsec)))';
                end
            catch
                % must have been a pre-cosine protocol
            end

			% Ramp
			if protocolData.ampRampEnable{ampIndex}
				if protocolData.ampRampLogarithmic{ampIndex}
					DAC(protocolData.ampRampStartTime{ampIndex} * pointsPerMsec:protocolData.ampRampStopTime{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampRampStartTime{ampIndex} * pointsPerMsec:protocolData.ampRampStopTime{ampIndex} * pointsPerMsec, channelNum) + (logspace(log(protocolData.ampRampStartAmplitude{ampIndex})/log(10), log(protocolData.ampRampStopAmplitude{ampIndex})/log(10), (protocolData.ampRampStopTime{ampIndex} - protocolData.ampRampStartTime{ampIndex}) * pointsPerMsec + 1))';
				else
					DAC(protocolData.ampRampStartTime{ampIndex} * pointsPerMsec:protocolData.ampRampStopTime{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampRampStartTime{ampIndex} * pointsPerMsec:protocolData.ampRampStopTime{ampIndex} * pointsPerMsec, channelNum) + (linspace(protocolData.ampRampStartAmplitude{ampIndex}, protocolData.ampRampStopAmplitude{ampIndex}, (protocolData.ampRampStopTime{ampIndex} - protocolData.ampRampStartTime{ampIndex}) * pointsPerMsec + 1))';
				end
			end

			% Train
			if protocolData.ampTrainEnable{ampIndex}
				i = protocolData.ampTrainStart{ampIndex};
				while i <= protocolData.sweepWindow
					DAC(i * pointsPerMsec:(i + protocolData.ampTrainOnDuration{ampIndex}) * pointsPerMsec, channelNum) = DAC(i * pointsPerMsec:(i + protocolData.ampTrainOnDuration{ampIndex}) * pointsPerMsec, channelNum) + protocolData.ampTrainAmplitude{ampIndex};
					i = i + protocolData.ampTrainOnDuration{ampIndex} + protocolData.ampTrainOffDuration{ampIndex};
				end
			end

			% Pulse
			if protocolData.ampPulseEnable{ampIndex}
				if ~isempty(protocolData.ampPulse1Start{ampIndex}) && ~isempty(protocolData.ampPulse1Stop{ampIndex}) && ~isempty(protocolData.ampPulse1Amplitude{ampIndex})
					DAC(protocolData.ampPulse1Start{ampIndex} * pointsPerMsec:protocolData.ampPulse1Stop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampPulse1Start{ampIndex} * pointsPerMsec:protocolData.ampPulse1Stop{ampIndex} * pointsPerMsec, channelNum) + protocolData.ampPulse1Amplitude{ampIndex};
				end
				if ~isempty(protocolData.ampPulse2Start{ampIndex}) && ~isempty(protocolData.ampPulse2Stop{ampIndex}) && ~isempty(protocolData.ampPulse2Amplitude{ampIndex})
					DAC(protocolData.ampPulse2Start{ampIndex} * pointsPerMsec:protocolData.ampPulse2Stop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampPulse2Start{ampIndex} * pointsPerMsec:protocolData.ampPulse2Stop{ampIndex} * pointsPerMsec, channelNum) + protocolData.ampPulse2Amplitude{ampIndex};
				end
				if ~isempty(protocolData.ampPulse3Start{ampIndex}) && ~isempty(protocolData.ampPulse3Stop{ampIndex}) && ~isempty(protocolData.ampPulse3Amplitude{ampIndex})
					DAC(protocolData.ampPulse3Start{ampIndex} * pointsPerMsec:protocolData.ampPulse3Stop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampPulse3Start{ampIndex} * pointsPerMsec:protocolData.ampPulse3Stop{ampIndex} * pointsPerMsec, channelNum) + protocolData.ampPulse3Amplitude{ampIndex};
				end
				if ~isempty(protocolData.ampPulse4Start{ampIndex}) && ~isempty(protocolData.ampPulse4Stop{ampIndex}) && ~isempty(protocolData.ampPulse4Amplitude{ampIndex})
					DAC(protocolData.ampPulse4Start{ampIndex} * pointsPerMsec:protocolData.ampPulse4Stop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampPulse4Start{ampIndex} * pointsPerMsec:protocolData.ampPulse4Stop{ampIndex} * pointsPerMsec, channelNum) + protocolData.ampPulse4Amplitude{ampIndex};
				end
				if ~isempty(protocolData.ampPulse5Start{ampIndex}) && ~isempty(protocolData.ampPulse5Stop{ampIndex}) && ~isempty(protocolData.ampPulse5Amplitude{ampIndex})
					DAC(protocolData.ampPulse5Start{ampIndex} * pointsPerMsec:protocolData.ampPulse5Stop{ampIndex} * pointsPerMsec, channelNum) = DAC(protocolData.ampPulse5Start{ampIndex} * pointsPerMsec:protocolData.ampPulse5Stop{ampIndex} * pointsPerMsec, channelNum) + protocolData.ampPulse5Amplitude{ampIndex};
				end
			end

			% Matlab
			if ~isempty(protocolData.ampMatlabStim{ampIndex})
				try
                    if iscell(protocolData.ampMatlabStim{ampIndex})
                        outData = eval(protocolData.ampMatlabStim{ampIndex}{1});
                    else
                        outData = eval(protocolData.ampMatlabStim{ampIndex});
                    end
					if length(outData) > length(DAC)
						DAC(1:length(DAC), channelNum) = DAC(1:length(DAC), channelNum) + outData(1:length(DAC));
						DAC(end + 1:end + length(outData) - length(DAC), channelNum) = outData(length(DAC) + 1:end);
					else
						DAC(1:length(outData), channelNum) = DAC(1:length(outData), channelNum) + outData;
					end
				catch
% 					warning(['Error with matlab command on amp ' char(64 + ampIndex)]);
				end
			end
        end
        callStack = dbstack;
        if ~isempty(strfind(protocolData.ampTypeName{ampIndex}, 'Pockel')) && ~strcmp(callStack(2).name, 'stimulus')
%             this is a pockel cell command and must be between 0 and 1
%             volts and needs to be scaled for the pockel cell sigmoidal
%             response
            DAC(:, channelNum) = convertPock(DAC(:, channelNum));
        end
	end % ampIndex
end % analogOuts > 0

% make sure none of the stimuli have exceeded the time limit
if size(digOut, 1) > protocolData.sweepWindow * 1000 / protocolData.timePerPoint || size(DAC, 1) > protocolData.sweepWindow * 1000 / protocolData.timePerPoint
	switch questdlg('Stimulus is longer than window being recorded.', 'Stim Error', 'Truncate to Sweep', 'Extend Sweep', 'Cancel', 'Cancel')
		case 'Truncate to Sweep'
			digOut(protocolData.sweepWindow * 1000 / protocolData.timePerPoint + 1:end, :) = [];
			DAC(protocolData.sweepWindow * 1000 / protocolData.timePerPoint + 1:end, :) = [];
		case 'Extend Sweep'
			set(0, 'showHidden', 'on');
			set(findobj('tag', 'sweepWindow'), 'string', num2str(max([size(digOut, 1) size(DAC, 1)]) * protocolData.timePerPoint / 1000 + 1000))
			set(0, 'showHidden', 'callback');
			saveProtocol;
		otherwise
			error('Error generating stimulus.')
	end
end