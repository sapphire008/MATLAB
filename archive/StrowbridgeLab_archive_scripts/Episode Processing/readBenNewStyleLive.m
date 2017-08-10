function zData = readBenNewStyleLive(filename, infoOnly)
% main read program for new Synapse4 
% last revised 12 May 2012

fid = fopen(filename, 'r');

%import IV trace info
if fid ~= -1
    % check to make sure that the file isn't zero length
    fseek(fid, 6, 'bof');
    info.infoBytes = fread(fid,1,'int32'); %size of header
    zData.protocol.sweepWindow = fread(fid,1,'float32'); % in msec per episode
    zData.protocol.msPerPoint = fread(fid,1,'float32') / 1000; %in microseconds per channel
    info.numPoints = fread(fid, 1, 'int32');
    zData.protocol.WCtime = fread(fid, 1, 'float32'); % in seconds since went whole cell
    zData.protocol.drugTime = fread(fid, 1, 'float32'); % in seconds since most recent drug started
    zData.protocol.drug = fread(fid, 1, 'float32'); % an integer indicating what drug is on
    info.numChannels = 0;
    
    % new from BWS on 12/21/08
    a1=fread(fid,1,'int32'); % simulated data
    fseek(fid, 48 , 'bof');
    zData.protocol.genData = fread(fid, 56, 'float32');
    
    % read in TTL information
    for index = 1:4
        fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
        zData.protocol.ttlData{index} = fread(fid, 17, 'float32');
    end
    
    % read in DAC information
    for index = 1:4
        fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
        zData.protocol.dacData{index} = fread(fid, 42, 'float32');
        zData.protocol.dacName{index} = readVBString(fid);
    end
    
    zData.protocol.classVersionNum = fread(fid, 1, 'float32');
    zData.protocol.acquireComment=readVBString(fid);
    zData.protocol.acquireAnalysisComment=readVBString(fid);
    zData.protocol.drugName=readVBString(fid);
    zData.protocol.exptDesc=readVBString(fid);
    zData.protocol.computerName=readVBString(fid);
    zData.protocol.savedFileName=readVBString(fid);
    zData.protocol.fileName = zData.protocol.savedFileName;
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
%         if count == 110 )
%             % Add fake stim since there is a Volt and Cur but no Stimulus
%             fakeStim{chanNum} = benGenerateStim(zData, chanNum);
%             info.numChannels = info.numChannels + 1;
%             zData.protocol.channelNames{info.numChannels} = ['StimAuto' chanLetter];
%             info.numFakeStimChannels = info.numFakeStimChannels + 1;
%         else
%             fakeStim{chanNum} = [];
%         end   
    end % chanNum
    zData.protocol.numTraces = info.numChannels;
    
    
    if nargin < 2
        count = 1;
        for chan = 1:(info.numChannels - info.numFakeStimChannels)
            traceFactor = fread(fid, 1, 'float32');
            traceLength = fread(fid, 1, 'int32');
            traceDesc = readVBString(fid);
            zData.protocol.traceDesc{chan} = traceDesc;
            traceData = fread(fid, traceLength, 'int16');
            traceData = traceFactor .* traceData;
            tempCmd = ['zData.' zData.protocol.channelNames{count} ' = traceData;'];
            eval(tempCmd);
            count = count + 1;
        end
%         for chan = 1:4
%             if numel(fakeStim{chan}) > 0
%                 tempCmd = ['zData.fakeStim' num2str(chan-1) ' = fakeStim{chan};'];
%                 eval(tempCmd);
%             end
%         end
    end % nargin
    
end
        