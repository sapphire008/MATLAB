function [dataVals resultData] = featureVsPotential(cell, stim, pspType, timeWindow, feature)
persistent newRoot
persistent numChars

% open all of the files and calculate the all-points histogram mean in the
% given window and plot this vs the psp amplitude
features = {'Amplitude', 'Rise time', 'Latency', 'Decay Tau', 'Time in Cell', 'Drug', 'Spike Time'};

if nargin < 1
    cell = 1;
end
if nargin < 2
    stim = 3;
end
if nargin < 3
    pspType = 1;
end
if nargin < 4
    timeWindow = [-110 -10];    
    params = inputdlg({'Cell:', 'Stimulus Number:', 'PSPs Down (0 or 1)', 'Time Window (ms)'},'',1, {num2str(cell), num2str(stim), num2str(pspType), mat2str(timeWindow)});
    if isempty(params)
        return
    end
    cell = str2double(params{1});
    stim = str2num(params{2});
    pspType = str2double(params{3});
    timeWindow = str2num(params{4});
end

if nargin < 5
    [feature, okTrue] = listdlg('PromptString','Select a feature:',...
                'SelectionMode','single',...
                'ListSize', [100 95],...
                'ListString',features);    
    if ~okTrue
        return
    end
elseif ischar(feature)
    feature = find(cellfun(@(x) ~isempty(x), strfind(features, feature)), 1, 'first');
    if isempty(feature)
        error('Invalid feature');
    end
end

PSPdata = get(gcf, 'userData');
PSPdata = PSPdata{4};
tempData = [];
for i = 1:numel(stim)
    tempData = [tempData squeeze(PSPdata(cell, stim(i), :, :))];
end
if pspType == 0
    resultData = tempData(:, tempData(3,:) > 0)';
else
    resultData = tempData(:, tempData(3,:) < 0)';
end
traceIndex = 1;
cellName = get(gcf, 'name');
dataVals = zeros(size(resultData, 1), 1);

% open the files and add their plots
for i = 1:size(resultData, 1)
    if ~isempty(numChars)
        zData = readTrace([newRoot cellName(11 + numChars:end) '.S' num2str(resultData(i,1)) '.E' num2str(resultData(i,2)) '.dat']);
    else
        zData = readTrace([cellName(11:end) '.S' num2str(resultData(i,1)) '.E' num2str(resultData(i,2)) '.dat']);
    end
    if isempty(zData)
        options.Resize = 'on';
        outputArgs = inputdlg({'Please truncate to old metaroot', 'Please enter new root'}, 'File not found', 2, {cellName(11:end), 'Y:\Larimer\Data\2005\Multidata'}, options);
        numChars = numel(outputArgs{1});
        newRoot = outputArgs{2};
        zData = readTrace([newRoot cellName(11 + numChars:end) '.S' num2str(resultData(i,1)) '.E' num2str(resultData(i,2)) '.dat']);            
    end        
    if i == 1
        timeWindow = timeWindow(1) / (zData.protocol.timePerPoint / 1000):timeWindow(2) / (zData.protocol.timePerPoint / 1000);
    end

    if ~isnan(resultData(i,9))
    	dataVals(traceIndex) = calcMean(zData.traceData(resultData(i,9) + timeWindow, whichChannel(zData.protocol, cell)));
    else
        if round(resultData(i,5)*1000/zData.protocol.timePerPoint) > timeWindow(1)
            dataVals(traceIndex) = calcMean(zData.traceData(round(resultData(i,5)*1000/zData.protocol.timePerPoint) + timeWindow, whichChannel(zData.protocol, cell)));
        else
            dataVals(traceIndex) = nan;
        end
    end

    traceIndex = traceIndex + 1;
end

% could filter data with this:
% dataVals = dataVals(resultData(:,3) > -1);
% resultData = resultData(resultData(:,3) > -1, :);
if nargout == 0
    % plot the data
    figure('numbertitle', 'off', 'name', [features{feature} ' vs Membrane Potential'])
    line(dataVals, resultData(:, feature + 2), 'linestyle', 'none', 'marker', '.', 'color', [0 0 0]);
else
    resultData = resultData(:, feature + 2);
end