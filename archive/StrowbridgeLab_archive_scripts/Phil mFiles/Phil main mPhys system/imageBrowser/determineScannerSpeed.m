%% this code is to generate a test

pixelUs = 5; % us
sweepWindow = 5; % ms
counter = 1;
outData = nan(8, 1);
xo = 0;
yo = 0;
A = 1;
B = 0;
dx = 0;
dy = 0;
wy = 0;
lineHandle = line('lineWidth', 2, 'parent', findobj('tag', 'imageAxis'), 'xData', 1, 'yData', 1, 'color', [1 0 0]);
for i = 4010:10:10000
    wx = 2 * pi * i * pixelUs / 1000000;
    totalStim = zeros(1000/pixelUs*sweepWindow, 2);
    totalStim(:,2) = xo + A .* sin(wx .* (1:1000/pixelUs*sweepWindow) + dx);
    
    totalStim = lissajousScan(getappdata(getappdata(0, 'imageDisplay'), 'ROI'), pixelUs);
    totalStim = totalStim(:, [2 1]);
    tempData = takeTwoPhotonImage([], totalStim, [], pixelUs, 1);
    info = getappdata(getappdata(0, 'imageBrowser'), 'info');
    voltSize = sscanf(info.SizeOnSource, 'Size = %g by %g mV'); 
    centerLoc = sscanf(info.Comment, 'Center = %g x %g mV');
    set(lineHandle, 'xData', (tempData(1,:) - centerLoc(1)) ./ voltSize(1) .* info.Width + info.Width / 2, 'yData', (tempData(2,:) - centerLoc(2)) ./ voltSize(2) .* info.Height);
    
    % at 4us pixels the location signal from point 45:end is equal to the drive signal.
    % at 2us pixels the location signal from point 89:end is equal to the drive signal.    
    % at 1us pixels the location signal from point 172:end is equal to the drive signal.
    
%     phaseData = phaseVsTime(tempData(2,end/2:end), i, 500000);
%     phaseData = phaseData(~isnan(phaseData));
%     outData(counter) = mean(phaseData(end/2:end));
%     outData(counter) = max(tempData(1, end/2:end));
%     counter = counter + 1;
%     pause(.5);
end