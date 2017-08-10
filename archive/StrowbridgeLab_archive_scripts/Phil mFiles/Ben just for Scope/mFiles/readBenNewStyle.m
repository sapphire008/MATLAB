function zData = readBenNewStyle(filename, infoOnly)

fid = fopen(filename, 'r');

%import IV trace info
if fid ~= -1
    % check to make sure that the file isn't zero length
    fseek(fid, 0, 'eof');        
    if ftell(fid) > 1000
        fseek(fid, 0, 'bof');
        zData.protocol.fileName = filename;
        protocolType=fread(fid, 1, 'int16') ;
        acquireVersion=fread(fid,1,'int32'); % added 12/21/08
        if (protocolType ~= 25) && (acquireVersion < 8)
            zData = [];
            return
        end
        
        fseek(fid, 0, 'bof');
        protocolType=fread(fid, 1, 'int16');
        acquireVersion=fread(fid,1,'int32');
        info.infoBytes = fread(fid,1,'int32'); %not used anymore was protocolBytes
        zData.protocol.sweepWindow = fread(fid,1,'float32'); % in msec per episode
        zData.protocol.timePerPoint = fread(fid,1,'float32'); %in microseconds per channel
        info.numPoints = fread(fid, 1, 'int32');
        zData.protocol.numPoints = info.numPoints;
        zData.protocol.cellTime = fread(fid, 1, 'float32'); % in seconds since went whole cell
        zData.protocol.drugTime = fread(fid, 1, 'float32'); % in seconds since most recent drug started
        zData.protocol.drug = fread(fid, 1, 'float32'); % an integer indicating what drug is on
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
            info.ampType(index) =  fread(fid, 1, 'float32');
        end
        for index = 1:4
            info.ampCurrent(index) =  fread(fid, 1, 'float32');             
        end        
        for index = 1:4
            info.ampVoltage(index) =  fread(fid, 1, 'float32');              
        end
        fseek(fid, 48 + 4 * 47, 'bof');
        for index = 1:4
            info.ampStimSaved(index) =  fread(fid, 1, 'float32');    
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
            zData.protocol.ttlType{index} = 1;
            zData.protocol.ttlPulseDuration{index} = info.SIUDuration;
            zData.protocol.ttlTypeName{index} = 'Unknown';
            zData.protocol.ttlEnable{index, 1} = fread(fid, 1, 'float32');
            fread(fid, 1, 'float32');
            zData.protocol.ttlStepEnable{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlIntensity{index} = inf;
            zData.protocol.ttlPulseEnable{index} = 1;
            zData.protocol.ttlStepDuration{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlStepLatency{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlArbitraryEnable{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlArbitrary{index} = '[';
            for i = 1:4
                temp = fread(fid, 1, 'float32');
                if temp > 0
                    zData.protocol.ttlArbitrary{index} = [zData.protocol.ttlArbitrary{index} sprintf('%1.0f', temp + 1) ' '];
                end
            end
            if numel(zData.protocol.ttlArbitrary{index}) == 1
                zData.protocol.ttlArbitrary{index} = '0';
            else
                zData.protocol.ttlArbitrary{index} = [zData.protocol.ttlArbitrary{index}(1:end - 1) ']'];
            end
            zData.protocol.ttlTrainEnable{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlBurstEnable{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlTrainLatency{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlTrainInterval{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlTrainNumber{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlBurstInterval{index} = fread(fid, 1, 'float32');
            zData.protocol.ttlBurstNumber{index} = fread(fid, 1, 'float32');   
        end
        
        % read in DAC information
        for index = 1:4
            fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
            zData.protocol.ampStimEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStepEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Enable{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep2Enable{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep3Enable{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStepInitialAmplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Start{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Stop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep1Amplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep2Stop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep2Amplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep3Stop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStep3Amplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampStepLastAmplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulseEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse1Start{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse1Stop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse1Amplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse2Start{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse2Stop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse2Amplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse3Start{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse3Stop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse3Amplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPulse4Start{index} = 0;
            zData.protocol.ampPulse4Stop{index} = 0;
            zData.protocol.ampPulse4Amplitude{index} = 0;
            zData.protocol.ampPulse5Start{index} = 0;
            zData.protocol.ampPulse5Stop{index} = 0;
            zData.protocol.ampPulse5Amplitude{index} = 0;            
            zData.protocol.ampPspEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampPspStart{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPspNumber{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPspTau{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPspInterval{index} = fread(fid, 1, 'float32');
            zData.protocol.ampPspPeak{index} = fread(fid, 1, 'float32') / exp(1);
            zData.protocol.ampSineEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampCosineEnable{index, 1} = 0;
            zData.protocol.ampSineStart{index} = fread(fid, 1, 'float32');
            zData.protocol.ampSineStop{index} = fread(fid, 1, 'float32');
            zData.protocol.ampSineFrequency{index} = fread(fid, 1, 'float32');
            zData.protocol.ampSineOffset{index} = fread(fid, 1, 'float32');
            zData.protocol.ampSineAmplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainEnable{index, 1} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainStart{index} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainOnDuration{index} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainOffDuration{index} = fread(fid, 1, 'float32');
            zData.protocol.ampTrainAmplitude{index} = fread(fid, 1, 'float32');
            zData.protocol.ampUseAWFfile{index} = fread(fid, 1, 'float32');
            stringLength = fread(fid, 1, 'int16');
            for i = 1:stringLength
                fread(fid, 1, 'char');
            end
            for i = 1:25
               zData.protocol.statValue(i) = 0;
               zData.protocol.statName{i} = [];
            end
            zData.protocol.ampSealTestStep{index} = 5;
            zData.protocol.ampBridgeBalanceStep{index} = 25;
            zData.protocol.ampCellLocation{index} = 1;
            zData.protocol.ampCellLocationName{index} = 'Unknown';
            zData.protocol.ampMatlabCommand{index, 1} = '';
            zData.protocol.ampMonitorRin{index, 1} = 0;
            zData.protocol.ampRandomizeFamilies{index} = 1;
            zData.protocol.ampTpEnable{index, 1} = 0;
            zData.protocol.ampTpMaxPer{index} = 0;
            zData.protocol.ampTpMaxCurrent{index} = 0;
            zData.protocol.ampTpSetPoint{index} = 0;
            zData.protocol.ampMatlabStim{index, 1} = 0;
            zData.protocol.ampRampEnable{index, 1} = 0;
            zData.protocol.ampRampLogarithmic{index} = 0;
            zData.protocol.ampRampStopAmplitude{index} = 0;
            zData.protocol.ampRampStartAmplitude{index} = 0;
            zData.protocol.ampRampStopTime{index} = 0;
            zData.protocol.ampRampStartTime{index} = 0;
            zData.protocol.ampStimulus{index} = index;
            zData.protocol.ampSaveStim{index} =info.ampStimSaved(index);
            zData.protocol.ampTelegraph{index} = 9;
            zData.protocol.ampVoltage{index} = index * 2;
            zData.protocol.ampCurrent{index} = index * 2 - 1;
            zData.protocol.ampType{index} = 1;
            if info.ampType(index) == 2
                zData.protocol.ampTypeName{index} = 'AxoPatch VC';
            else
                zData.protocol.ampTypeName{index} = 'AxoPatch CC';
            end
        end                 
        
        zData.protocol.classVersionNum = fread(fid, 1, 'float32');
        zData.protocol.acquireComment=readVBString(fid);
        zData.protocol.acquireAnalysisComment=readVBString(fid);
        zData.protocol.drugName=readVBString(fid);
        zData.protocol.exptDesc=readVBString(fid);
        zData.protocol.computerName=readVBString(fid);
        zData.protocol.savedFileName=readVBString(fid);
        zData.protocol.linkedFileName=readVBString(fid);
        zData.protocol.acquisitionDeviceName=readVBString(fid);
        zData.protocol.traceKeys=readVBString(fid);
        zData.protocol.traceInitValuesStr=readVBString(fid);
        zData.protocol.extraScalarKeys=readVBString(fid);
        zData.protocol.extraVectorKeys=readVBString(fid);
        zData.protocol.genString=readVBString(fid);
        for i = 1:4
           zData.protocol.TTLstring{i}=readVBString(fid); 
        end
        for i = 1:4
            zData.protocol.ampDesc{i}=readVBString(fid); 
        end
        
        zData.protocol.ampsCorandomize{1} = 0;
        zData.protocol.acquisitionRate{1} = 8;
        zData.protocol.source{1} = 1;
        zData.protocol.sourceName{1} = 'ITC-18 PCI default';
        for i = 1:8
            zData.protocol.channelExtGain{i} = 1;
            zData.protocol.channelRange{i} = 1;
            zData.protocol.channelType{i} = 1;
        end
        
        zData.protocol.channelNames = regexp(zData.protocol.traceKeys, '\s', 'split'); 
        info.numChannels = size(zData.protocol.channelNames, 2);
        for chanNum = 1:info.numChannels
           testStr = [zData.protocol.channelNames{chanNum} '              '];
           if strcmp(testStr(1:8), 'VoltADC1')
              zData.protocol.channelNames{chanNum} = 'VoltA';
           end
           if strcmp(testStr(1:7), 'CurADC0')
              zData.protocol.channelNames{chanNum} = 'CurA';
           end
           if strcmp(testStr(1:12), 'StimulusAmpA')
               zData.protocol.channelNames{chanNum} = 'StimulusA';
           end
           if strcmp(testStr(1:8), 'VoltADC3')
              zData.protocol.channelNames{chanNum} = 'VoltB';
           end
           if strcmp(testStr(1:7), 'CurADC2')
              zData.protocol.channelNames{chanNum} = 'CurB';
           end
            if strcmp(testStr(1:12), 'StimulusAmpB')
               zData.protocol.channelNames{chanNum} = 'StimulusB';
           end
            if strcmp(testStr(1:8), 'VoltADC5')
              zData.protocol.channelNames{chanNum} = 'VoltC';
           end
           if strcmp(testStr(1:7), 'CurADC4')
              zData.protocol.channelNames{chanNum} = 'CurC';
           end
            if strcmp(testStr(1:12), 'StimulusAmpC')
               zData.protocol.channelNames{chanNum} = 'StimulusC';
           end
            if strcmp(testStr(1:8), 'VoltADC7')
              zData.protocol.channelNames{chanNum} = 'VoltD';
           end
           if strcmp(testStr(1:7), 'CurADC6')
              zData.protocol.channelNames{chanNum} = 'CurD';
           end
            if strcmp(testStr(1:12), 'StimulusAmpD')
               zData.protocol.channelNames{chanNum} = 'StimulusD';
           end
        end
        
        info.numFakeStimChannels = 0;
        for chanNum = 1:4
            switch chanNum
                case 1
                   chanLetter = 'A'; 
                case 2
                   chanLetter = 'B'; 
                case 3
                   chanLetter = 'C'; 
                case 4
                   chanLetter = 'D'; 
            end
            count = 0;
            for i = 1:numel(zData.protocol.channelNames)
                 if strcmp(zData.protocol.channelNames{i}, ['Volt' chanLetter])
                    count = count + 10;
                    break;
                 end
            end
            for i = 1:numel(zData.protocol.channelNames)
                 if strcmp(zData.protocol.channelNames{i}, ['Cur' chanLetter])
                    count = count + 100;
                    break;
                 end
            end
            for i = 1:numel(zData.protocol.channelNames)
                 if strcmp(zData.protocol.channelNames{i}, ['Stimulus' chanLetter])
                    count = count + 1000;
                    break;
                 end
            end
            if count == 110 && (zData.protocol.ampUseAWFfile{chanNum} == 0)
                % Add fake stim since there is a Volt and Cur but no Stimulus
                fakeStim{chanNum} = benGenerateStim(zData, chanNum);
                info.numChannels = info.numChannels + 1;
                zData.protocol.channelNames{info.numChannels} = ['StimAuto' chanLetter];
                info.numFakeStimChannels = info.numFakeStimChannels + 1;
            else
                fakeStim{chanNum} = [];
            end
        end % chanNum
        
		if nargin < 2
            zData.traceData = nan(info.numPoints, info.numChannels);
            count = 1;
            for chan = 1:(info.numChannels - info.numFakeStimChannels)
                traceFactor = fread(fid, 1, 'float32');
                traceLength = fread(fid, 1, 'int32');
                traceDesc = readVBString(fid);
                zData.protocol.traceDesc{chan} = traceDesc;
                traceData = fread(fid, traceLength, 'int16');
                traceData = traceFactor .* traceData;
                zData.traceData(:, count) = traceData;
                count = count + 1;
            end
            for chan = 1:4
               if numel(fakeStim{chan}) > 0
                   zData.traceData(:, count) = fakeStim{chan};
                   count = count + 1;
               end
            end
            zData.protocol.startingValues = mean(zData.traceData(1:10,:), 1);
            for i = 1:(info.numChannels - info.numFakeStimChannels)
               if strcmp(zData.protocol.channelNames{i}, 'VoltA')
                  zData.protocol.channelNames{i} = 'Amp A, V'; 
               end
                if strcmp(zData.protocol.channelNames{i}, 'CurA')
                  zData.protocol.channelNames{i} = 'Amp A, I'; 
                end
                if strcmp(zData.protocol.channelNames{i}, 'StimulusA')
                  zData.protocol.channelNames{i} = 'Amp A, Stimulus'; 
                end
               
                if strcmp(zData.protocol.channelNames{i}, 'VoltB')
                  zData.protocol.channelNames{i} = 'Amp B, V'; 
               end
                if strcmp(zData.protocol.channelNames{i}, 'CurB')
                  zData.protocol.channelNames{i} = 'Amp B, I'; 
                end
                if strcmp(zData.protocol.channelNames{i}, 'StimulusB')
                  zData.protocol.channelNames{i} = 'Amp B, Stimulus'; 
                end
               
                if strcmp(zData.protocol.channelNames{i}, 'VoltC')
                  zData.protocol.channelNames{i} = 'Amp C, V'; 
               end
                if strcmp(zData.protocol.channelNames{i}, 'CurC')
                  zData.protocol.channelNames{i} = 'Amp C, I'; 
                end
                if strcmp(zData.protocol.channelNames{i}, 'StimulusC')
                  zData.protocol.channelNames{i} = 'Amp C, Stimulus'; 
                end
               
                if strcmp(zData.protocol.channelNames{i}, 'VoltD')
                  zData.protocol.channelNames{i} = 'Amp D, V'; 
               end
                if strcmp(zData.protocol.channelNames{i}, 'CurD')
                  zData.protocol.channelNames{i} = 'Amp D, I'; 
                end
                if strcmp(zData.protocol.channelNames{i}, 'StimulusD')
                  zData.protocol.channelNames{i} = 'Amp D, Stimulus'; 
                end
            end % for i =
        else
           
        end % numArgIn
        
		
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
        
    else
        zData = [];
    end 
end
        