function outText = autoNotch(inData, timePerPoint, startTime, axisHandle)
% generate a notch filter for a data set
if nargin < 1
    outText = 'NotchFilter';
    return
end
    samplingRate = 1000/timePerPoint;

    % show the Fourier transform
    resolution = length(inData);
    Y = fft(inData, resolution);
    Pyy = Y.* conj(Y) / resolution;
    Pyy = Pyy(2:int32(resolution / 2 + 1));

    f = samplingRate * (1:round(resolution / 2)) / resolution;
    zScore = Pyy ./ oneSidedDeviation(Pyy);
    handles = newScope({zScore}, f, 'Frequency (kHz)');
    set(handles.axes(1), 'ylim', [0 3]);
    set(handles.channelControl(1).scaleType, 'value', 2);
    set(handles.channelControl(1).maxVal, 'enable', 'on', 'string', '3');
    set(handles.channelControl(1).minVal, 'enable', 'on', 'string', '0');
    set(handles.figure, 'name', 'Close figure when done picking peaks')
    set(handles.figure, 'closerequestfcn', @closeFigure);

    % pick putative noise peaks
    events.type = 'Noise Peaks';
    events.traceName = 'FFT';
    events.data = f(zScore(2:end - 1) > 1 & zScore(1:end - 2) < 1 & zScore(3:end) < 2);
    setappdata(handles.axes(1), 'events', events);
    showEvents(handles.axes(1));

    % wait for the user
    uiwait(handles.figure);

    % make frequency values more precise
%     figure, plot(inData);
%     hold on;
%     lineHandle = line(1:length(inData),1:length(inData), 'color', 'r');
    for i = 1:numel(events.data)
        events(1).data(i) = fminsearch(@sinAmp, events(1).data(i), optimset('MaxFunEvals', 300, 'Display', 'none', 'TolFun', 0, 'Tolx', 0));
    end        

    % create a call to comb filter to use
    outText = ['data = combFilter(data, [' num2str(events(1).data, '%1.4f ') '], ' num2str(samplingRate) ');'];
    handles = get(get(axisHandle, 'parent'), 'userData');
    commandBox = handles.channelControl([handles.channelControl.resultText] == get(gca, 'userData')).commandText;
    set(commandBox, 'string', outText);
    callData.Key = 'return';
    commandCallback = get(commandBox, 'keypressfcn');
    commandCallback(commandBox, callData);

    function sse = sinAmp(params)
        sineData = 2 * mean(-sin(2 * pi * params / samplingRate * (1:length(inData))) .* (inData - mean(inData)));
        cosineData = 2 * mean(cos(2 * pi * params / samplingRate * (1:length(inData))) .* (inData - mean(inData)));
        
        sse = -sqrt(sineData.*sineData + cosineData.*cosineData);
%         set(lineHandle, 'yData', -sqrt(sineData.*sineData + cosineData.*cosineData) * cos(atan2(sineData, cosineData) + 2*pi*events(1).data(i) / samplingRate * (1:length(inData))') + mean(inData));
%         pause
    end

    function closeFigure(varargin)
        events = getappdata(handles.axes(1), 'events');        
        scopeHandles = getappdata(0, 'scopes');
        if length(scopeHandles) > 1
            whichScope = find(scopeHandles == varargin{1});
            if ~isempty(whichScope)
                setappdata(0, 'scopes', scopeHandles([1:whichScope - 1 whichScope + 1:end]));
            end
        else
            if any(scopeHandles == varargin{1})
                rmappdata(0, 'scopes');
            end
        end
        delete(varargin{1})
    end
end