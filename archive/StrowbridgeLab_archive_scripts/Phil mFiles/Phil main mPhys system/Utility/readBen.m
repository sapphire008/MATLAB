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
    if ftell(fid) > 1000
        fseek(fid, 0, 'bof');
        zData.protocol.fileName = filename;
        if ~(fread(fid, 1, 'int16') == 25)
            if nargin < 2
                zData = readBenOld(filename);
            else
                zData = readBenOld(filename, infoOnly);
            end
            return
        end
        fseek(fid, 6, 'bof');
        info.infoBytes = fread(fid,1,'int32'); %size of header
        zData.protocol.sweepWindow = fread(fid,1,'float32'); % in msec per episode
        zData.protocol.timePerPoint = fread(fid,1,'float32'); %in microseconds per channel
        info.numPoints = fread(fid, 1, 'int32');
        zData.protocol.cellTime = fread(fid, 1, 'float32'); % in seconds since went whole cell
        zData.protocol.drugTime = fread(fid, 1, 'float32'); % in seconds since most recent drug started
        zData.protocol.drug = sprintf('%0.0f', fread(fid, 1, 'float32')); % an integer indicating what drug is on
        info.numChannels = 0;
        fseek(fid, 48 + 4 * 3, 'bof');
        for index = 1:8
            info.chanType(index) = fread(fid, 1, 'float32');
            if info.chanType(index) > 6 && info.chanType(index) < 13
                info.numChannels = info.numChannels + 1;
            end
        end
        for index = 1:8
            info.chanGain(index) = fread(fid, 1, 'float32');
        end
        for index = 1:8
            info.chanExtGain(index) = fread(fid, 1, 'float32');
        end
        
        % read in amp information
        for index = 1:4
            zData.protocol.ampEnable{index, 1} =  fread(fid, 1, 'float32');
        end
        for index = 1:4
            info.ampType(index, 1) =  fread(fid, 1, 'float32');
        end
        for index = 1:4
            info.ampCurrent(index, 1) =  fread(fid, 1, 'float32');             
        end        
        for index = 1:4
            info.ampVoltage(index, 1) =  fread(fid, 1, 'float32');              
        end
        fseek(fid, 48 + 4 * 47, 'bof');
        for index = 1:4
            info.ampStimSaved(index, 1) =  fread(fid, 1, 'float32');    
        end
        
        % read in other general info
        info.AuxTTLEnable = fread(fid, 1, 'float32');
        info.extTrig = fread(fid, 1, 'float32');
        info.SIUDuration = fread(fid, 1, 'float32');
        info.episodicMode = fread(fid, 1, 'float32');
        info.programCode = fread(fid, 1, 'float32');
        
        % read in TTL information
        for index = 1:4
            fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
            zData.protocol.ttlType{index, 1} = 1;
            zData.protocol.ttlPulseDuration{index, 1} = info.SIUDuration;
            zData.protocol.ttlTypeName{1, index} = 'Unknown';
            zData.protocol.ttlEnable{index, 1} = fread(fid, 1, 'float32');
            fread(fid, 1, 'float32');
            zData.protocol.ttlStepEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlIntensity{index, 1} = inf;
            zData.protocol.ttlPulseEnable{index, 1} = 1;
            zData.protocol.ttlStepDuration{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlStepLatency{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlArbitraryEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlArbitrary{index, 1} = '[';
            for i = 1:4
                temp = fread(fid, 1, 'float32');
                if temp > 0
                    zData.protocol.ttlArbitrary{index, 1} = [zData.protocol.ttlArbitrary{index, 1} sprintf('%1.0f', temp) ' '];
                end
            end
            if numel(zData.protocol.ttlArbitrary{index, 1}) == 1
                zData.protocol.ttlArbitrary{index, 1} = '0';
            else
                zData.protocol.ttlArbitrary{index, 1} = [zData.protocol.ttlArbitrary{index, 1}(1:end - 1) ']'];
            end
            zData.protocol.ttlTrainEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlBurstEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlTrainLatency{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlTrainInterval{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlTrainNumber{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlBurstInterval{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ttlBurstNumber{index, 1} = fread(fid, 1, 'float32');   
        end
        
        % turn off the useless hidden ttl
        zData.protocol.ttlEnable{1, 1} = 0;
        
        % read in DAC information
        for index = 1:4
            fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
            zData.protocol.ampStimEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStepEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Enable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep2Enable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep3Enable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStepInitialAmplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Start{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Stop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Amplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep2Stop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep2Amplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep3Stop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep3Amplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStepLastAmplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulseEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse1Start{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse1Stop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse1Amplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse2Start{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse2Stop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse2Amplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse3Start{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse3Stop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse3Amplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse4Start{index, 1} = 0;
            zData.protocol.ampPulse4Stop{index, 1} = 0;
            zData.protocol.ampPulse4Amplitude{index, 1} = 0;
            zData.protocol.ampPulse5Start{index, 1} = 0;
            zData.protocol.ampPulse5Stop{index, 1} = 0;
            zData.protocol.ampPulse5Amplitude{index, 1} = 0;            
            zData.protocol.ampPspEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPspStart{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPspNumber{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPspTau{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPspInterval{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPspPeak{index, 1} = fread(fid, 1, 'float32') / exp(1);
            zData.protocol.ampSineEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampCosineEnable{index, 1} = 0;
            zData.protocol.ampSineStart{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampSineStop{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampSineFrequency{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampSineOffset{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampSineAmplitude{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainStart{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainOnDuration{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainOffDuration{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainAmplitude{index, 1} = fread(fid, 1, 'float32');
            fread(fid, 1, 'float32');
            stringLength = fread(fid, 1, 'int16');
            for i = 1:stringLength
                fread(fid, 1, 'char');
            end
            zData.protocol.ampSealTestStep{index, 1} = 5;
            zData.protocol.ampBridgeBalanceStep{index, 1} = 25;
            zData.protocol.ampCellLocation{index, 1} = 1;
            zData.protocol.ampCellLocationName{1, index} = 'Unknown';
            zData.protocol.ampMatlabCommand{index, 1} = '';
            zData.protocol.ampMonitorRin{index, 1} = 0;
            zData.protocol.ampRandomizeFamilies{index, 1} = 1;
            zData.protocol.ampTpEnable{index, 1} = 0;
            zData.protocol.ampTpMaxPer{index, 1} = 0;
            zData.protocol.ampTpMaxCurrent{index, 1} = 0;
            zData.protocol.ampTpSetPoint{index, 1} = 0;
            zData.protocol.ampMatlabStim{index, 1} = '';
            zData.protocol.ampRampEnable{index, 1} = 0;
            zData.protocol.ampRampLogarithmic{index, 1} = 0;
            zData.protocol.ampRampStopAmplitude{index, 1} = 0;
            zData.protocol.ampRampStartAmplitude{index, 1} = 0;
            zData.protocol.ampRampStopTime{index, 1} = 0;
            zData.protocol.ampRampStartTime{index, 1} = 0;
            zData.protocol.ampStimulus{index, 1} = index;
            zData.protocol.ampSaveStim{index, 1} = info.ampStimSaved(index);
            zData.protocol.ampTelegraph{index, 1} = 9;
            zData.protocol.ampVoltage{index, 1} = index * 2;
            zData.protocol.ampCurrent{index, 1} = index * 2 - 1;
            zData.protocol.ampType{index, 1} = 1;
            if info.ampType(index) == 2
                zData.protocol.ampTypeName{1, index} = 'AxoPatch VC';
            else
                zData.protocol.ampTypeName{1, index} = 'AxoPatch CC';
            end
        end                 
        
        zData.protocol.ampsCorandomize{1} = 0;
        zData.protocol.acquisitionRate{1} = 8;
        zData.protocol.source{1} = 1;
        zData.protocol.sourceName{1} = 'ITC-18 PCI';
        gainVals = [1 3 4 5 6 7];
%         chanTypes = {'Disabled', 'Voltage 10x Vm', 'Current AxoPath', 'Current AxoClamp', 'Voltage 1x Vm', 'MultiClamp Scaled', 'MultiClamp Raw', 'Field 100x', 'Field 1000x', 'Field 10 000x', 'Photodiode', 'Poly2 lambda', 'Frame Clock', 'Voltage 50x Vm'};
        for i = 1:8
            zData.protocol.channelExtGain{index, i} = gainVals(info.chanExtGain(i) + 1);
            zData.protocol.channelRange{index, i} = info.chanExtGain(i) + 1;
            zData.protocol.channelType{index, i} = 1;
        end
        
        % set this to index into the array structure properly
        chanNum = 1;
		channelsUsed = [];
        zData.protocol.channelNames = {};
        for index = 1:4
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

            if info.ampStimSaved(index) > 0
				info.ampStimSaved(index) = chanNum;
                zData.protocol.channelNames{chanNum} = ['Amp ' char(64 + index) ', Stimulus'];
				chanNum = chanNum + 1;
            end
			% ******************************************
			% what about field channels, where are they?
			% ******************************************
        end
        
        % read data section
        % move file pointer to beginning of data
		if nargin < 2
            fseek(fid,info.infoBytes-1,'bof');  
            zData.traceData = fread(fid, [info.numPoints + 1, inf], 'float32');
            info.numChannels = size(zData.traceData, 2);
            
            % two channels are always recorded for any amp that is on.
            % Therefore to make which channels are on align when one of the
            % channels was disabled we must find and remove the dud channel
            % (which is a misscaled copy of the enabled channel for that
            % amplifier
            if nnz(info.ampStimSaved) + nnz(info.chanType) ~= info.numChannels
% 				toKeep = [];
% 				for i = 1:4
%                     if zData.protocol.ampEnable{i}
%                         if info.chanType(info.ampVoltage(i) + 1) ~= 0
%                             toKeep = [toKeep sum([zData.protocol.ampEnable{1:i}]) * 2]; % since it looks like the two channels written are always voltage then current
%                         elseif info.chanType(info.ampCurrent(i) + 1) ~= 0
%                             toKeep = [toKeep sum([zData.protocol.ampEnable{1:i}]) * 2 + 1];
%                         end                    
%                     end
%                 end
%                 toKeep = unique(toKeep);
% 				zData.traceData = zData.traceData(toKeep - 1,:);
% 				temp = info.ampVoltage;
% 				info.ampVoltage = info.ampCurrent;
% 				info.ampCurrent = temp;
            end
            zData.protocol.startingValues = mean(zData.traceData(1:10,:), 1);
            zData.traceData(end,:) = [];
        else
            fseek(fid, 0, 'eof');
            lastByte = ftell(fid);
            j = 1;
            for i = info.infoBytes-1:(info.numPoints + 1) * 4:lastByte - 1
                fseek(fid, i,'bof');  
                zData.protocol.startingValues(j) = mean(fread(fid, 10, 'float32'));
                j = j + 1;
            end
            if isempty(i)
                % only the protocol is in the file
                zData.protocol.startingValues = []; 
            end
		end
        
        for i = 1:nnz(info.chanType) - numel(zData.protocol.channelNames)
            zData.protocol.channelNames{end + 1} = ['Field' sprintf('%0.0f', i) ', V'];
        end
        if isfield(zData, 'traceData') && size(zData.traceData, 2) > numel(zData.protocol.channelNames)
            for j = 1:size(zData.traceData, 2) - numel(zData.protocol.channelNames)
                zData.protocol.channelNames{end + 1} = ['Field ' sprintf('%0.0f', i + j) ', V'];
            end
        end
		info.numChannels = chanNum - 1;
		
        % close file
        fclose(fid);
        
        % add extra fields about experiment
        zData.protocol.bath = 'Unknown';
        zData.protocol.cellName = 'Unknown';
        zData.protocol.dataFolder = 'Unknown';
        zData.protocol.episodeTime = 0;
        zData.protocol.imageDuration = 0;
        zData.protocol.imageScan = 'scanAllRoi';
        zData.protocol.internal = 'Unknown';
        zData.protocol.matlabCommand = '';
        zData.protocol.nextEpisode = '';
        zData.protocol.photometryHeader = [];
        zData.protocol.repeatInterval = 0;
        zData.protocol.repeatNumber = 0;
        zData.protocol.scanWhichRoi = '0';
        zData.protocol.takeImages = 0;
        
        % reorder the fields to match the new protocol
        zData.protocol = orderfields(zData.protocol, [99 113 112 121 74:77 26 78:81 8 10 12:14 120 3 100:102 2 103:105 82:84 63 85 40 69 86 62 56 27 92:98 15 16 19 17 9 55:-1:41 73:-1:70 68:-1:64 61:-1:57 87:91 39:-1:28 18 20 23 22 21 25 24 1 107 106 5 111 4 116 119 115 118 109 6 108 114 7 11 110 117]);
        
        if nargin == 2
            zData = zData.protocol;
        end        
    else
        zData = []; % tell calling subroutine that the file was zero length
    end
else
    zData = []; % tell calling subroutine that no file was found
end