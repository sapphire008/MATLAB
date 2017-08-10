function [startTimes, peakTimes, peakAmp] = eph_detect_events(inData, ts, cumulativeDerThresh, event_type, varargin)
% Find EPSP/IPSP/EPSC/IPSC events based on threshold
%
% Inputs:
%   inData: electrophysiology time series data. Either currents or voltage.
%   ts: sampling rate (seconds).
%   cumulativeDerThresh: cumulative threshold of the derivative of the 
%           event time series. Adjust to lower value to detect smaller 
%           events. E.g. use 0.6 for current-clamp EPSPs
%   event_type: upward event: EPSP (current clamp) and IPSC 
%               (voltage clamp); downward event: IPSP (current clamp) and 
%               EPSC (voltage clamp). Enter as string of the event types.
%
% Optional flags:
%   Key : Meaning [option1|option2|(Default option3)]
%   'FilterType'    : ways to filter raw time series
%           [('movingaverage')|'sgolay'|'butter'|'medfilt']
%   'FilterLength'  : moving filter window (number of data points except
%           for 'butter', which is the adjusted frequency Wn, between 0 and
%           1, where 1 is half of the sampling rate. [numeric, default set
%           for 'movingaverage'(5)]
%   'FilterOrder'   : Order of the polynomial filters, only applicable for
%           'sgolay' and 'butter'. [numeric, default set for 'sgolay' (2)]
%   'DerivFilterType':filter set for the derivative of the time series.
%           ['movingaverage'|('sgolay')|'butter'|'medfilt1']
%   'DerivFilterLength': filter length for derivative of the time series.
%           Default set for 'sgolay' (7).
%   'DerivFilterOrder': filter order for derivative of the time series.
%           Default set for 'sgolay' (2).
%   'Window'        : window to detect events within, in the format 
%           [start_seconds, end_seconds]
%   'SIUArtifact'   : timing of the SIU artifact, in the format of 
%           [start_seconds, end_seconds]
%
% Outputs:
%   startTimes: a vector of start time of the detected events in seconds
%   peakTimes: a vector of time of peak in seconds
%   amp: amplitude of the peaks in the same unit as inData

%  parmList = [PSPdown  
%  dataFilterLength = 5 % moving average filter of raw data trace
%  derFilterLength = 7 % savitsky golay filter length (uses a third order filter)
%  cumulativeDerThresh = 0.6 for c-clamp EPSPs %
%  excludeTimesMs is a vector of when SIU artifacts are
%  ts = fix(1/zData.protocol.msPerPoint); sampling rate

% parse optional inputs
flag = parse_varargin(varargin,{'FilterType','movingaverage'},{'FilterLength',5},...
    {'FilterOrder',2},{'DerivFilterType','sgolay'},{'DerivFilterLength',7},...
    {'DerivFilterOrder',2},{'Window',[]}, {'SIUArtifact',[]});

% parse event type
switch upper(event_type)
    case {'EPSP','IPSC'}
        PSEDOWN = false;% post synaptic event is not down
    case {'IPSP','EPSC'}
        PSEDOWN = true;% post synaptic event is down
        % switch sign of threshold if downward event
        cumulativeDerThresh = -1 * cumulativeDerThresh;
end

% make sure data is in column
inData = inData(:);

% Take only subset of data
if ~isempty(flag.Window)
    inData = inData((flag.Window(1)/ts+1):(flag.Window(2)/ts+1));
end

% make sure that the filter length is an odd number
flag.FilterLength = floor(flag.FilterLength/2)*2+1;
flag.DerivFilterLength = floor(flag.DerivFilterLength/2)*2+1;

% filter the trace
dataFilt = filterData(inData, flag.FilterType,flag.FilterLength, flag.FilterOrder);
% filter the derivative
dataDerFilt = filterData(diff(dataFilt), flag.DerivFilterType, flag.DerivFilterLength, flag.DerivFilterOrder);

% Detect peaks
outData = zeros(size(dataFilt));
if PSEDOWN
    % per Cohen and Miles 2000
    for index = 2:length(outData)
        if dataDerFilt(index - 1) < 0
            outData(index) = outData(index - 1) + dataDerFilt(index - 1);
        end
    end    % find where derivative of this function is changing from negative to positive
    functionDer = diff(outData);
    peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) < 0);
else
    % per Cohen and Miles 2000
    for index = 2:length(outData)
        if dataDerFilt(index - 1) > 0
            outData(index) = outData(index - 1) + dataDerFilt(index - 1);
        end
    end
    % find where derivative of this function is changing from positive to negative
    functionDer = diff(outData);
    peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) > 0);
end


% for each such value greater than derThresh find where the function last
% began to deviate from 0 and call that an event start
numStarts = 0;
whereStarts = ones(length(peaks), 1); % pre-allocate space for speed
wherePeaks = whereStarts;
% new baseline detection routine 26 July 2013 BWS
%       whereStarts(:) = nan;
%       wherePeaks(:) = nan;
%       for index = 1:length(peaks)
%          if abs(outData(peaks(index))) > cumulativeDerThresh
%              numStarts = numStarts + 1;
%              wherePeaks(numStarts) = peaks(index);
%              for revIndex = index:-1:2
%                 if outData(revIndex) == 0
%                    break;
%                 end
%              end
%              whereStarts(numStarts) = revIndex;
%          end
%       end
%       whereStarts = whereStarts(~isnan(whereStarts));
%       wherePeaks = wherePeaks(~isnan(wherePeaks));

for index = 1:length(peaks)
    if abs(outData(peaks(index))) > cumulativeDerThresh
        numStarts = numStarts + 1;
        whereStarts(numStarts) = peaks(index);
        while outData(whereStarts(numStarts)) ~= 0
            whereStarts(numStarts) = whereStarts(numStarts) - 1;
        end
        wherePeaks(numStarts) = peaks(index);
    end
end
wherePeaks = wherePeaks(whereStarts>3);
whereStarts = whereStarts(whereStarts>3);
if ~isempty(flag.Window)
    correctionTime = flag.Window(1) * ts;
else
    correctionTime = 0;
end
startTimes = ((whereStarts + 1) .* ts) + correctionTime;
peakTimes = ((wherePeaks - 1) .* ts) + correctionTime;
%       startTimes = (whereStarts .* zData.protocol.msPerPoint) + correctionTime;
%       peakTimes = (wherePeaks .* zData.protocol.msPerPoint) + correctionTime;
if numel(excludeTimesMs) > 0
    for i = 1:numel(excludeTimesMs)
        tempArray = abs(startTimes - (excludeTimesMs(i) + 0.6)) > 1;
        startTimes = startTimes(tempArray);
        peakTimes = peakTimes(tempArray);
    end
end

% new part from 2 Feb 2015 BWS
% Find peak amplitude
peakAmp = startTimes .* 0;
for ii = 1:numel(startTimes)
    startIndex = fix(pointsPerMs * (startTimes(ii) - 1)); % start 1 ms before
    if startIndex < 1, startIndex = 1; end
    peakIndex = fix(pointsPerMs * peakTimes(ii)) + 1;
    if peakIndex > numel(inData), peakIndex = numel(inData); end
    startDither = (0:1)';
    peakDither = (-1:0)';
    peakAmp(ii) = mean(inData(peakIndex + peakDither)) - mean(inData(startIndex + startDither));
end
end

%% Filters
function dataFilt = filterData(data, FilterType,FilterLength, FilterOrder)
switch FilterType
    case 'sgolay'
        dataFilt = sgolayfilt(data, FilterOrder, FilterLength);
    case 'movingaverage'
        dataFilt = movingAverage(data, FilterLength);
    case 'medfilt'
        dataFilt = medfilt1(data, FilterLength);
    case 'butter'
        dataFilt = butterworthFilter(data, FilterOrder, FilterLength);       
    otherwise
        error('Unrecognized filter type');
end
end

%% Butterworth filter
function dataFilt = butterworthFilter(data, N, Wn)
% N: filter order
% Wn: normalized frequency, where Wn = 1 is 1/2 of the sampling frequency
[B,A] = butter(N, Wn);
data_mean = mean(data);
dataFilt = [data-data_mean, zeros(1,2^nextpow2(numel(data))-numel(data))];% pad zeros to data
dataFilt = filtfilt(B,A,dataFilt);%filter data
dataFilt = dataFilt(1:numel(data))+data_mean; %recover data
end

%% moving average filter
function outData = movingAverage(inData, windowSize)
% use a boxcar filter of length windowSize points on inData
% filteredData = movingAverage(rawData, windowSize);
% defaults:
%   windowSize = 10 points

if nargin < 2
    windowSize = 10;
end

if size(inData, 1) > size(inData, 2)
    longSide = 1;
    flatData = ones(windowSize, 1);
else
    longSide = 2;
    flatData = ones(1, windowSize);
end

cheatShift = int32(windowSize / 2);
outData = filter(flatData./(windowSize),1,cat(longSide, flatData.*inData(1), inData, flatData.*inData(end)));
outData = outData(windowSize + cheatShift:length(inData) + windowSize + cheatShift - 1);
end

%% varargin input
function flag = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as doublet cellstrs, {'opt1','default1'}.
flag = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
    else
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end