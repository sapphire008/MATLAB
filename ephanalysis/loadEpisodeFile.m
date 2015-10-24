function zData = loadEpisodeFile(filename, infoOnly, useMatrix)
% Main read program for new Synapse4
%
% Inputs:
%   filename: full path to the .dat file
%   infoOnly (optional): only read protocol info of the data, excluding raw
%           traces; default is false.
%   useMatrix (optional): By default, the function sepearte traces by data
%           stream names, e.g. VoltA, CurB. If true, read in the format as
%           a matrix where each column corresponds to a different trace /
%           datastream; default is false
%
% Output:
%   zData: data structure that contains protocol and data traces (either in
%          the format of matrix stored in a field 'traceData', or
%          separated data streams stored in fields of tracenames, e.g.
%          'VoltA','CurB').
%
% Last revised 11 Feb 2015

if nargin < 2, infoOnly = false; end
if nargin < 3, useMatrix = false; end

fid = fopen(filename, 'r');

%import IV trace info
if fid == -1
    zData = []; %tell calling subroutine that no file was found
    warning('Cannot open file %s\n', filename);
    return;
end

% check to make sure that the file isn't zero length
fseek(fid, 0, 'eof');
if ftell(fid) <= 1000
    zData = []; %tell calling subroutine that the file was zero length
    warning('%s has zero length \n', filename);
    return;
end

% Check software versions
fseek(fid, 0, 'bof');
protocolType=fread(fid, 1, 'int16') ;
acquireVersion=fread(fid,1,'int32'); % added 12/21/08
fclose(fid); % clean up before open again in subroutines

% Read in the data
if ~(protocolType == 25)
    zData = readOldData(filename, infoOnly);
elseif (protocolType == 25) && (acquireVersion >= 8)
    [zData, info] = readData(filename, infoOnly, useMatrix);
else
    error('Unrecognized acquisiiton format of file %s \n', filename);
end
end

%% For new style data
function [zData, info] = readData(filename, infoOnly, useMatrix)
% Main read program for new Synapse4
%
% Last revised 11 Feb 2015

% Define constant variables
channelDict = struct(...
    'VoltADC1','VoltA','VoltADC3','VoltB','VoltADC5','VoltC','VoltADC7','VoltD',...
    'CurADC0','CurA','CurADC2','CurB','CurADC4','CurC','CurADC6', 'CurD',...
    'StimulusAmpA', 'StimulusA','StimulusAmpB','StimulusB','StimulusAmpC','StimulusC','StimulusAmpD','StimulusD',...
    'StimulusAmpA9','StimulusA');
info.numChannels = 4; % A, B, C, and D

% open file, assuming the file is good, as checked in the main function
fid = fopen(filename, 'r');
fseek(fid, 6, 'bof'); % set to file position to 6 relative to the beginning of the file
info.infoBytes = fread(fid,1,'int32'); %size of header
zData.protocol.sweepWindow = fread(fid,1,'float32'); % in msec per episode
zData.protocol.msPerPoint = fread(fid,1,'float32') / 1000; %in microseconds per channel
info.numPoints = fread(fid, 1, 'int32');
zData.protocol.WCtime = fread(fid, 1, 'float32'); % in seconds since went whole cell
zData.protocol.drugTime = fread(fid, 1, 'float32'); % in seconds since most recent drug started
zData.protocol.drug = fread(fid, 1, 'float32'); % an integer indicating what drug is on

% new from BWS on 12/21/08
fread(fid,1,'int32'); % simulated data
fseek(fid, 48 , 'bof');
zData.protocol.genData = fread(fid, 56, 'float32'); %[need expansion]

% read in TTL information
for index = 1:info.numChannels
    fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
    zData.protocol.ttlData{index} = fread(fid, 17, 'float32'); %[need expansion]
end
%ftell(fid)

% read in DAC information
for index = 1:info.numChannels
    fseek(fid, 10, 'cof'); % 10 is for VB user-defined type stuff
    zData.protocol.dacData{index} = fread(fid, 42, 'float32'); %[need expansion]
    zData.protocol.dacName{index} = readVBString(fid);
end

% Get other parameters
%ftell(fid)
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
for i = 1:info.numChannels
    zData.protocol.TTLstring{i}=readVBString(fid);
end
for i = 1:info.numChannels
    zData.protocol.ampDesc{i}=readVBString(fid);
end

% Get Channel info
zData.protocol.channelNames = strtrim(regexprep(regexp(zData.protocol.traceKeys, '\s', 'split'),'/\d',''));
zData.protocol.channelNames = cellfun(@(x) channelDict.(char(x)), zData.protocol.channelNames,'un',0);
zData.protocol.numTraces = numel(zData.protocol.channelNames);

% Organize the fields
zData.protocol = orderfields(zData.protocol);

% stop here if infoOnly
if infoOnly, return; end
for chan = 1:zData.protocol.numTraces
    traceFactor = fread(fid, 1, 'float32');
    traceLength = fread(fid, 1, 'int32');
    traceDesc = readVBString(fid);
    zData.protocol.traceDesc{chan} = traceDesc;
    traceData = fread(fid, traceLength, 'int16');
    traceData = traceFactor .* traceData(:);
    if useMatrix
        zData.traceData(:,chan) = traceData;
    else
        zData.(zData.protocol.channelNames{chan}) = traceData;
    end
end
fclose(fid);
%fclose('all');
end

%% for old style data
function readOldData(filename, infoOnly)
% old way to get data
% get protocols
if nargin<2, infoOnly = false; end
zData.protocol.fileName = filename;
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

for i=1:25
    zData.protocol.statBox(i) = fread(fid, 1, 'int32');
end
for i=1:25
    zData.protocol.statValue(i) = fread(fid, 1, 'float32');
end
for i=1:25
    zData.protocol.statName{i} = readVBString(fid);
end
zData.protocol.acquireComment = readVBString(fid);
zData.protocol.acquireAnalysisComment = readVBString(fid);
zData.protocol.savedFileName = readVBString(fid);
numChannels = 0;
for k = 1:20
    curKey = readVBString(fid);
    zData.protocol.oldKeys{k} = curKey;
    if size(curKey, 2) > 1
        zData.protocol.newKeys{k} = convertOldToNewKey(curKey);
        numChannels = numChannels + 1;
    else
        zData.protocol.newKeys{k} = '';
    end
end
zData.protocol.numTraces = numChannels;

% read data section
% move file pointer to beginning of data
if infoOnly, fclose(fid); return; end
fseek(fid,info.infoBytes-1,'bof');
traceData = fread(fid, [info.numPoints + 2, inf], 'float32');
info.numChannels = size(traceData, 2);
if numChannels ~= info.numChannels
    msgbox ('Problem in non matching number of channels in readBenLive');
end
for k = 1:numChannels
    tempCmd = ['tempTrace = traceData(:, ' num2str(k) ');' ];
    eval(tempCmd);
    tempCmd = ['zData.' zData.protocol.newKeys{k} ' = tempTrace(1:end-1);' ];
    eval(tempCmd);
    %  assignin('caller', ['zData.' zData.protocol.newKeys{k}], traceData(:, k));
end
fclose(fid);
end
%% other subroutines
function stringOut = readVBString(fid)
% this function takes a handle to an open file and reads a VB encoded
% string.  It assumes the file position is correct
stringLength = fread(fid, 1, 'int16');
if stringLength==0
    stringOut='';
else
    stringOut =(fread(fid, stringLength, '*char'))'; % last prime is to transpose string
end
end
