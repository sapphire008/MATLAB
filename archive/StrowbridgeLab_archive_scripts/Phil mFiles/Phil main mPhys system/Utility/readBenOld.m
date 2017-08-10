% reads in a Ben file given its name (and directory if necessary)
% [data, info] = readBen(filename)
% [data info] = readBen
% info = readBen(filename, 'infoOnly');
function zData = readBen(filename, infoOnly)

% read header to determine number of traces, etc
fid = fopen(filename, 'r');

%import IV trace info
if fid ~= -1
    % check to make sure that the file isn't zero length
    fseek(fid, 0, 'eof');    
    endOfFile = ftell(fid);
    if endOfFile > 1000
        zData.protocol.fileName = filename;
        fseek(fid, 6, 'bof');
        zData.protocol.timePerPoint = fread(fid,1,'float32'); %in microseconds per channel
        info.infoBytes = fread(fid,1,'int32'); %size of header
        zData.protocol.sweepWindow = fread(fid,1,'float32'); % in msec per episode
        info.numPoints = fread(fid, 1, 'int32');
        
        fseek(fid, 190, 'bof');
        zData.protocol.ttlEnable{1} = fread(fid, 1, 'int16');
        
        fseek(fid, 212, 'bof');
        zData.protocol.ttlEnable{2} = fread(fid, 1, 'int16');
        
        fseek(fid, 222, 'bof');
        zData.protocol.ttlEnable{3} = fread(fid, 1, 'int16');
        
        zData.protocol.cellTime = 0; % in seconds since went whole cell
        zData.protocol.drugTime = 0; % in seconds since most recent drug started
        
        fseek(fid, 394, 'bof');
        zData.protocol.drug = fread(fid, 1, 'float32'); % an integer indicating what drug is on

        % read in amp information
        zData.protocol.ampEnable =  {1, 0, 0, 0};
        
        for index = 1:4
            info.ampType(index) =  1;
        end
        for index = 1:4
            info.ampCurrent(index) =  2;             
        end        
        for index = 1:4
            info.ampVoltage(index) =  1;              
        end
        for index = 1:4
            info.ampStimSaved(index) =  0;    
        end
        
        % read in TTL information
        for index = 1:4
            zData.protocol.ttlType{index} = 1;
            zData.protocol.ttlPulseDuration{index} = 200;
            zData.protocol.ttlTypeName{index} = 'Unknown';
            zData.protocol.ttlStepEnable{index} = 0;
            zData.protocol.ttlIntensity{index} = 0;
            zData.protocol.ttlPulseEnable{index} = 1;
            zData.protocol.ttlStepDuration{index} = 0;
            zData.protocol.ttlStepLatency{index} = 0;
            zData.protocol.ttlArbitraryEnable{index} = 0;
            zData.protocol.ttlArbitrary{index} = 0;
            zData.protocol.ttlTrainEnable{index} = 0;
            zData.protocol.ttlBurstEnable{index} = 0;
            zData.protocol.ttlTrainLatency{index} = 0;
            zData.protocol.ttlTrainInterval{index} = 0;
            zData.protocol.ttlTrainNumber{index} = 0;
            zData.protocol.ttlBurstInterval{index} = 0;
            zData.protocol.ttlBurstNumber{index} = 0;   
        end
        
        % read in DAC information
        for index = 1:4
            zData.protocol.ampStimEnable{index} = 0;
            zData.protocol.ampStepEnable{index} = 0;
            zData.protocol.ampStep1Enable{index} = 0;
            zData.protocol.ampStep2Enable{index} = 0;
            zData.protocol.ampStep3Enable{index} = 0;
            zData.protocol.ampStepInitialAmplitude{index} = 0;
            zData.protocol.ampStep1Start{index} = 0;
            zData.protocol.ampStep1Stop{index} = 0;
            zData.protocol.ampStep1Amplitude{index} = 0;
            zData.protocol.ampStep2Stop{index} = 0;
            zData.protocol.ampStep2Amplitude{index} = 0;
            zData.protocol.ampStep3Stop{index} = 0;
            zData.protocol.ampStep3Amplitude{index} = 0;
            zData.protocol.ampStepLastAmplitude{index} = 0;
            zData.protocol.ampPulseEnable{index} = 0;
            zData.protocol.ampPulse1Start{index} = 0;
            zData.protocol.ampPulse1Stop{index} = 0;
            zData.protocol.ampPulse1Amplitude{index} = 0;
            zData.protocol.ampPulse2Start{index} = 0;
            zData.protocol.ampPulse2Stop{index} = 0;
            zData.protocol.ampPulse2Amplitude{index} = 0;
            zData.protocol.ampPulse3Start{index} = 0;
            zData.protocol.ampPulse3Stop{index} = 0;
            zData.protocol.ampPulse3Amplitude{index} = 0;
            zData.protocol.ampPulse4Start{index} = 0;
            zData.protocol.ampPulse4Stop{index} = 0;
            zData.protocol.ampPulse4Amplitude{index} = 0;
            zData.protocol.ampPulse5Start{index} = 0;
            zData.protocol.ampPulse5Stop{index} = 0;
            zData.protocol.ampPulse5Amplitude{index} = 0;            
            zData.protocol.ampPspEnable{index} = 0;
            zData.protocol.ampPspStart{index} = 0;
            zData.protocol.ampPspNumber{index} = 0;
            zData.protocol.ampPspTau{index} = 0;
            zData.protocol.ampPspInterval{index} = 0;
            zData.protocol.ampPspPeak{index} = 0 / exp(1);
            zData.protocol.ampSineEnable{index} = 0;
            zData.protocol.ampCosineEnable{index} = 0;
            zData.protocol.ampSineStart{index} = 0;
            zData.protocol.ampSineStop{index} = 0;
            zData.protocol.ampSineFrequency{index} = 0;
            zData.protocol.ampSineOffset{index} = 0;
            zData.protocol.ampSineAmplitude{index} = 0;
            zData.protocol.ampTrainEnable{index} = 0;
            zData.protocol.ampTrainStart{index} = 0;
            zData.protocol.ampTrainOnDuration{index} = 0;
            zData.protocol.ampTrainOffDuration{index} = 0;
            zData.protocol.ampTrainAmplitude{index} = 0;

            zData.protocol.ampSealTestStep{index} = 5;
            zData.protocol.ampBridgeBalanceStep{index} = 25;
            zData.protocol.ampCellLocation{index} = 1;
            zData.protocol.ampCellLocationName{index} = 'Unknown';
            zData.protocol.ampMatlabCommand{index} = '';
            zData.protocol.ampMonitorRin{index} = 0;
            zData.protocol.ampRandomizeFamilies{index} = 1;
            zData.protocol.ampTpEnable{index} = 0;
            zData.protocol.ampTpMaxPer{index} = 0;
            zData.protocol.ampTpMaxCurrent{index} = 0;
            zData.protocol.ampTpSetPoint{index} = 0;
            zData.protocol.ampMatlabStim{index} = 0;
            zData.protocol.ampRampEnable{index} = 0;
            zData.protocol.ampRampLogarithmic = 0;
            zData.protocol.ampRampStopAmplitude = 0;
            zData.protocol.ampRampStartAmplitude = 0;
            zData.protocol.ampRampStopTime = 0;
            zData.protocol.ampRampStartTime = 0;
            zData.protocol.ampStimulus{index} = index;
            zData.protocol.ampSaveStim{index} = 0;
            zData.protocol.ampTelegraph{index} = 9;
            zData.protocol.ampVoltage{index} = index * 2;
            zData.protocol.ampCurrent{index} = index * 2 - 1;
            zData.protocol.ampType{index} = 1;
%             if info.ampType(index) == 2
%                 zData.protocol.ampTypeName{index} = 'AxoPatch VC';
%             else
                zData.protocol.ampTypeName{index} = 'AxoPatch CC';
%             end
        end                 
        
        zData.protocol.ampsCorandomize{1} = 0;
        zData.protocol.acquisitionRate = 8;
        zData.protocol.source = 1;
        zData.protocol.sourceName = 'ITC-18 PCI';
        for i = 1:8
            zData.protocol.channelExternalGain{index} = 1;
            zData.protocol.channelRange{index} = 1;
            zData.protocol.channelType{index} = 1;
        end
        
        % read data section
        % move file pointer to beginning of data
		if nargin < 2
            fseek(fid,info.infoBytes-1,'bof');  
            zData.traceData = fread(fid, [round((endOfFile - info.infoBytes) / (info.numPoints + 1) / 4), inf], 'float32')';
            zData.protocol.startingValues = mean(zData.traceData(1:10, :), 2);
            zData.traceData(end,:) = [];
        else
            zData.protocol.startingValues = [];
		end
        
        % set this to index into the array structure properly
        chanNum = 1;
		channelsUsed = [];
        zData.protocol.channelNames = {};
        for index = 1:4
            if zData.protocol.ampEnable{index} ~= 0 %&& info.chanType(info.ampCurrent(index) + 1) ~=0 % channel is not disabled
% 				if ~ismember(info.ampCurrent(index), channelsUsed)
					channelsUsed = [channelsUsed info.ampCurrent(index)];					
					info.ampCurrent(index) = chanNum;
                    zData.protocol.channelNames{chanNum} = ['Amp ' char(64 + index) ', I'];
					chanNum = chanNum + 1;
%                 else
%                     zData.protocol.channelNames{find(channelsUsed == info.ampCurrent(index))} = ['Amp ' char(64 + index) ', I'];
% 					info.ampCurrent(index) = find(channelsUsed == info.ampCurrent(index));
% 				end
			else
				info.ampCurrent(index) = 0;
            end
            
			if zData.protocol.ampEnable{index} ~= 0 %&& info.chanType(info.ampVoltage(index) + 1) ~=0 % channel is not disabled
% 				if ~ismember(info.ampVoltage(index), channelsUsed)
					channelsUsed = [channelsUsed info.ampVoltage(index)];
					info.ampVoltage(index) = chanNum;
                    zData.protocol.channelNames{chanNum} = ['Amp ' char(64 + index) ', V'];
					chanNum = chanNum + 1;
%                 else
%                     zData.protocol.channelNames{find(channelsUsed == info.ampVoltage(index))} = ['Amp ' char(64 + index) ', V'];
% 					info.ampVoltage(index) = find(channelsUsed == info.ampVoltage(index));
% 				end
			else
				info.ampVoltage(index) = 0;
			end            

            if info.ampStimSaved(index) > 0
				info.ampStimSaved(index) = chanNum;
                zData.protocol.channelNames{chanNum} = ['Amp ' char(64 + index) ', Stimulus'];
				chanNum = chanNum + 1;
            end
			% ******************************************
			% what about field channels, where are they?
			% ******************************************
        end
%         for i = 1:nnz(info.chanType) - numel(zData.protocol.channelNames)
%             zData.protocol.channelNames{end + 1} = 'Field V';
%         end
        if isfield(zData, 'traceData') && size(zData.traceData, 2) > numel(zData.protocol.channelNames)
            for j = 1:size(zData.traceData, 2) - numel(zData.protocol.channelNames)
                zData.protocol.channelNames{end + 1} = 'Field V';
            end
        end
		info.numChannels = chanNum - 1;
        
		
        % close file
        fclose(fid);
        
        if nargin == 2
            zData = zData.protocol;
        end        
    else
        zData = []; %tell calling subroutine that the file was zero length
    end
else
    zData = []; %tell calling subroutine that no file was found
end