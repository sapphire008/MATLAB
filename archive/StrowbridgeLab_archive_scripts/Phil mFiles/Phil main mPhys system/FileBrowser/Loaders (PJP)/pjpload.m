function [header data]=pjpload(fn, infoOnly)
% ** function [header tempHeader]=pjpload(fn)
% for reading data files as presented by Pascal 7/21/2010

tempHeader = load(fn);
tempNames = fieldnames(tempHeader);
tempHeader = tempHeader.(tempNames{1});

try
    header.fileName = fn;
    header.shortFileName = fn(find(fn == filesep, 1, 'last') + 1:end - 4);
    for chIndex = 1:numel(tempHeader.ADCscale)
        header.channelNames{chIndex} = tempHeader.ADCscale(chIndex).ChannelName;
    end
    % this should maybe be: header.channelNames = tempHeader.name;
    header.timePerPoint = 1e6 / tempHeader.ADCrate;
    header.cellTime = tempHeader.abstime / 1000; % assuming this is in ms since midnight
    header.ampEnable{1} = 1;

    header.photometryHeader = [];
    if infoOnly
        header.startingValues = nan(size(header.channelNames));
        header.sweepWindow = nan;
    else
        % this can be replaced by commands to read from seq files
        data = double(tempHeader.adc);
        header.startingValues = mean(data(1:5, :), 1);
        header.sweepWindow = length(data) / tempHeader.ADCrate * 1000;
    end
catch
    % the file does not appear to be of the format we had hoped, so return
    header = [];
    data = [];
end
