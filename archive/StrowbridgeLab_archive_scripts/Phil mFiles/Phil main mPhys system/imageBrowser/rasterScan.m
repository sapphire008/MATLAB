function scanPoints = rasterScan(fileName)
% paradigm for drawing a rotated raster
% generate the linear portions (must be separate since one will be longer
% than the other) then stick on the ends (not separate since the slopes of
% the linear portions should be the same), then add together, keeping in
% mind the addition onto the last one.
% new paradigm: just divide the maximum acceleration by
% max([cos(rotation) cos(pi - rotation)]) to make sure that the axis with
% the most triangle wave characteristic is still below the maximum accel

if ~isappdata(0, 'rasterScan')
    handles = guihandles(hgload('rasterScan.fig'));

    % set its location
    if ~ispref('locations', 'rasterScan')
        setpref('locations', 'rasterScan', [100 45 93.8 16.7]);
    end
    set(handles.rasterScanFigure, 'position', getpref('locations', 'rasterScan'));

    objectives = getpref('objectives');
    set(handles.objectiveName, 'string', objectives.nominalMagnification); 
    set(handles.voltsX, 'callback', @setVoltsX);
    set(handles.voltsY, 'callback', @setVoltsY);
    set(handles.pixelsX, 'callback', @setPixelsX);
    set(handles.pixelsY, 'callback', @setPixelsY);
    set(handles.endType, 'selectionChangeFcn', @changeEnds);
    set(handles.cmdTest, 'callback', @testTriangle);
    set(handles.cmdImage, 'callback', @imageTriangle);
    set(handles.cmdFocus, 'callback', @focusTriangle);

    voltsX = str2double(get(handles.voltsX, 'string'));
    voltsY = str2double(get(handles.voltsY, 'string'));
    pixelsX = str2double(get(handles.pixelsX, 'string'));
    pixelsY = str2double(get(handles.pixelsY, 'string'));

    set(handles.endType, 'selectedObject', handles.endsAccel);
    changeEnds;
    set(handles.rasterScanFigure, 'closeRequestFcn', @closeMe, 'userData', handles);
    setappdata(0, 'rasterScan', handles.rasterScanFigure);
    if ispref('galvos', 'lag')
        set(handles.lagX, 'string', getpref('galvos', 'lag'));
        set(handles.centerX, 'string', getpref('galvos', 'centerX'));
        set(handles.centerY, 'string', getpref('galvos', 'centerY'));
    end

    onScreen(handles.rasterScanFigure);
    
    takeTwoPhotonNI;
else
    handles = get(getappdata(0, 'rasterScan'), 'userData');
end

if nargin
    % if the argument is a file name then just take the image
    if ischar(fileName)
        handles = guihandles(getappdata(0, 'rasterScan'));    
        voltsX = str2double(get(handles.voltsX, 'string'));
        voltsY = str2double(get(handles.voltsY, 'string'));
        pixelsX = str2double(get(handles.pixelsX, 'string'));
        pixelsY = str2double(get(handles.pixelsY, 'string'));    
        imageTriangle;
    else
        scanPoints = takeScan(fileName);
    end
end

    function setVoltsX(varargin)
        if get(handles.lockRatios, 'value')
            set(handles.voltsY, 'string', sprintf('%1.2f', voltsY / voltsX * str2double(get(handles.voltsX, 'string'))));
        end
        voltsX = str2double(get(handles.voltsX, 'string'));
    end

    function setVoltsY(varargin)
        if get(handles.lockRatios, 'value')
            set(handles.voltsX, 'string', sprintf('%1.2f', voltsX / voltsY * str2double(get(handles.voltsY, 'string'))));
        end
        voltsY = str2double(get(handles.voltsY, 'string'));
    end

    function setPixelsX(varargin)
        if get(handles.lockRatios, 'value')
            set(handles.pixelsY, 'string', sprintf('%1.2f', pixelsY / pixelsX * str2double(get(handles.pixelsX, 'string'))));
        end
        pixelsX = str2double(get(handles.pixelsX, 'string'));
    end

    function setPixelsY(varargin)
        if get(handles.lockRatios, 'value')
            set(handles.pixelsX, 'string', sprintf('%1.2f', pixelsX / pixelsY * str2double(get(handles.pixelsY, 'string'))));
        end
        pixelsY = str2double(get(handles.pixelsY, 'string'));
    end

    function changeEnds(varargin)
        try
            switch get(handles.endType, 'selectedObject')
                case handles.endsPoint
                    set(handles.sineFreq, 'enable', 'off');
                    set(handles.sineAmp, 'enable', 'off');
                    set(handles.maximumAcc, 'enable', 'off');
                case handles.endsSine
                    set(handles.sineFreq, 'enable', 'on');
                    set(handles.sineAmp, 'enable', 'on');
                    set(handles.maximumAcc, 'enable', 'off');               
                case {handles.endsParabolic, handles.endsAccel}
                    set(handles.sineFreq, 'enable', 'off');
                    set(handles.sineAmp, 'enable', 'off');
                    set(handles.maximumAcc, 'enable', 'on');
            end
        catch
            % is called upon initialization and ends up here since the
            % switch is on a uicontrol object instead of its handle
        end
    end

    function testTriangle(varargin)
        [zImage scanPoints] = takeScan(1);
        figure('numbertitle', 'off', 'name', 'Position');
        subplot(2,1,1);
        plot(scanPoints(:,1), 'color', 'black', 'linewidth', 2);
        hold on
        plot(zImage.photometry(:,1), 'color', 'red');
        subplot(2,1,2);
        plot(scanPoints(:,2), 'color', 'black', 'linewidth', 2);
        hold on
        plot(zImage.photometry(:,2), 'color', 'red');
        linkaxes(get(gcf, 'children'), 'x');
        zoom xon
        
%         figure('numberTitle', 'off', 'name', 'velocity');
%         line(diff(scanPoints(:,1)), diff(outData(:,1)));
    end

    function imageTriangle(varargin)        
        zImage = takeScan(0); 
        if ~isempty(zImage);
            zImage.info.Filename = 'Local Raster Scan';
            zImage.info.ProgramNumber = 3;
            zImage.info.ProgramMode = 0;
            zImage.info.DataOffset = 0;
            zImage.info.MiscInfo = '';
            zImage.info.ImageSource = '';
            zImage.info.PixelMicrons = 0;
            zImage.info.MillisecondPerFrame = 0;
            zImage.info.Objective = '';
            zImage.info.AdditionalMagnification = '';
            zImage.info.AdditionalInformation = '';
            zImage.info.origin = [0 0 0];
            zImage.info.Width = pixelsX;
            zImage.info.Height = pixelsY;
            zImage.info.NumImages = 1;
            zImage.info.NumChannels = 1;
            zImage.info.BitDepth = 14;
            zImage.info.Comment = ['Center = ' sprintf('%1.3f', str2double(get(handles.centerX, 'string'))) ' x ' sprintf('%1.3f', str2double(get(handles.centerY, 'string'))) ' mV'];
            zImage.info.SizeOnSource = ['Size = ' sprintf('%1.3f', voltsX) ' by ' sprintf('%1.3f', voltsY) ' mV'];
            zImage.info.SourceProcessing = 'Zoom = 1 Rotation = 0';
            zImage.info.delta = repmat(micronsPerPixel(sscanf(zImage.info.Objective, '%*s %gx/%*g'), voltsX, zImage.info.Width), 3, 1);

            if exist('fileName', 'var')
                write2PRaster(zImage, fileName);
            end

            imageBrowser(zImage);
        end
    end

    function focusTriangle(varargin)
        if strcmp(get(handles.cmdFocus, 'string'), 'Stop')
            set(handles.cmdFocus, 'string', 'Focus');
        else
            set(handles.cmdFocus, 'string', 'Stop');
            takeScan(0);
        end        
    end

    function closeMe(varargin)
        unloadlibrary('ljackuw');
        clear takeTwoPhotonNI;
        setpref('galvos', 'lag', get(handles.lagX, 'string'));
        setpref('galvos', 'centerX', get(handles.centerX, 'string'));
        setpref('galvos', 'centerY', get(handles.centerY, 'string'));
        setpref('locations', 'rasterScan', get(gcf, 'position'));		
        rmappdata(0, 'rasterHandles');
        rmappdata(0, 'rasterScan');
        delete(gcf);
    end

    function [zImage scanPoints] = takeScan(returnPosition)
        voltsX = str2double(get(handles.voltsX, 'string'));     
        voltsY = str2double(get(handles.voltsY, 'string'));   
        centerX = str2double(get(handles.centerX, 'string'));
        centerY = str2double(get(handles.centerY, 'string'));
        pixelUs = str2double(get(handles.pixelUs, 'string'));        
        lagX = str2double(get(handles.lagX, 'string'));
        sineFreq = str2double(get(handles.sineFreq, 'string'));
        sineAmp = str2double(get(handles.sineAmp, 'string'));
        maximumAcc = str2double(get(handles.maximumAcc, 'string'));
        rotationRadians = str2double(get(handles.rotation, 'string')) / 180 * pi;
        numFrames = str2double(get(handles.numFrames, 'string'));  
        if isstruct(returnPosition)
            changeFields = fieldnames(returnPosition);
            for i = changeFields'
                eval([i{1} ' = returnPosition.(i{1});']);
            end
        end
        
        % do some scaling
        sineFreq = sineFreq * 1000; % convert to Hz
        maximumAcc = maximumAcc * pixelUs * pixelUs / 1000; % transform to Volts / pixel / pixel
        
        switch get(handles.endType, 'selectedObject')
            case handles.endsPoint
                rowPair = [centerX + voltsX / 2:-voltsX / (pixelsX - 1):centerX - voltsX / 2 centerX - voltsX / 2:voltsX / (pixelsX - 1):centerX + voltsX / 2]';
                scanPoints = repmat(rowPair, fix(pixelsY / 2), 2);
                turnLength = 0;
            case handles.endsSine
                lineSlope = voltsX / (pixelsX); % line slope in volts/time point

                % generate the linear portion of the signal
                 linearPortion = centerX - voltsX / 2:voltsX / (pixelsX - 1):centerX + voltsX / 2;

                % find time (in points) at which a sine wave first achieves this slope
                % ((2 * pi) / (pixelUs / (sineFreq / 1000000))) * cos((2 * pi) / (pixelUs / (sineFreq / 1000000)) * t) == lineSlope
                t = acos(lineSlope / ((2 * pi) / (pixelUs / (sineFreq / 1000000)))) / ((2 * pi) / (pixelUs / (sineFreq / 1000000)));

                % time at which the sine wave achieves the negative of this slope is just
                % pi radians - this value, so generate the sine arc over this interval
                endPortion = sineAmp .* sin((2 * pi) / (pixelUs / (sineFreq / 1000000)) * (t:(pixelUs / (sineFreq / 1000000)) / 2- t)) - 1;
                endPortion = endPortion - endPortion(1);
                turnLength = numel(endPortion) - 2;
                
                rowPair = [endPortion(2:end - 1) + linearPortion(end) linearPortion(end:-1:1) linearPortion(1) - endPortion(2:end - 1) linearPortion ]';

                % repeat it
                scanPoints = repmat(rowPair, fix(pixelsY / 2), 2);
            case handles.endsParabolic
                lineSlope = voltsX / (pixelsX); % line slope in volts/time point

                % generate the linear portion of the signal
                 linearPortion = centerX - voltsX / 2:voltsX / (pixelsX - 1):centerX + voltsX / 2;

                % time at which the parabola achieves slope is found with
                % the derivative and then the end portion is generated
                endPoint = lineSlope / (2 * maximumAcc);
                endPortion = -maximumAcc .* (-endPoint:endPoint).^2;
                endPortion = endPortion - endPortion(1);
                turnLength = numel(endPortion) - 2;       

                rowPair = [endPortion(2:end - 1) + linearPortion(end) linearPortion(end:-1:1) linearPortion(1) - endPortion(2:end - 1) linearPortion]';

                % repeat it
                scanPoints = repmat(rowPair, fix(pixelsY / 2), 2);            
            case handles.endsAccel
                lineSlope = voltsX / (pixelsX);% / pixelUs; % line slope in volts/time point
                turnLength = fix(2 * lineSlope / maximumAcc) + 1;
                
                % generate the acceleration data
                accelData = [-maximumAcc .* ones(turnLength, 1); zeros(pixelsX, 1); maximumAcc .* ones(turnLength, 1); zeros(pixelsX, 1)];
                
                % generate the velocity data
                velocityData = cumsum(accelData);
                velocityData = velocityData - mean(velocityData);
%                 set(handles.pixelUs, 'string', sprintf('%1.4f', pixelUs * max(velocityData) / lineSlope));
                
                % generate the position data
                rowPair = cumsum(velocityData);
                rowPair = rowPair - mean(rowPair) + centerX;
                voltsX = rowPair(turnLength) - rowPair(turnLength + pixelsX);
%                 set(handles.voltsX, 'string', sprintf('%1.4f', voltsX));                
                
                % repeat it
                scanPoints = repmat(rowPair, fix(pixelsY / 2), 2);
        end
        
        % generate the slow axis data
        for i = 0:pixelsY - 1
%             scanPoints(i * (pixelsX + turnLength) + (1:turnLength + pixelsX), 2) = centerY - voltsY / 2 + (pixelsY - i) * voltsY / pixelsY; % step scan bottom to top
            scanPoints(i * (pixelsX + turnLength) + (1:turnLength + pixelsX), 2) = centerY - voltsY / 2 + (i + 1) * voltsY / pixelsY; % step scan top to bottom            
%             scanPoints((i - 1) * (pixelsX + turnLength) + turnLength + (1:pixelsX), 2) = (centerY - voltsY / 2 + (i - 1) * voltsY / pixelsY:voltsY / (pixelsX * pixelsY - 1):centerY - voltsY / 2 + i * voltsY / pixelsY); % broken ramp scan
        end          
        
        % rotate the points
        scanPoints = (scanPoints - repmat([centerX centerY], size(scanPoints, 1), 1)) * [cos(-rotationRadians) -sin(-rotationRadians); sin(-rotationRadians) cos(-rotationRadians)] + repmat([centerX centerY], size(scanPoints, 1), 1);
        
        if ~strcmp(get(findobj('tag', 'cmdFocus'), 'string'), 'Stop')
            zImage = takeTwoPhotonNI([], repmat(scanPoints, numFrames, 1), [], pixelUs, returnPosition); 
        else
            zImage.info.Filename = 'Local Raster Scan';
            zImage.info.Width = pixelsX;
            zImage.info.Height = pixelsY;
            zImage.info.NumImages = 1;
            zImage.info.NumChannels = 1;
            zImage.info.BitDepth = 14;
            zImage.info.Comment = ['Center = ' sprintf('%1.3f', str2double(get(handles.centerX, 'string'))) ' x ' sprintf('%1.3f', str2double(get(handles.centerY, 'string'))) ' mV'];
            zImage.info.SizeOnSource = ['Size = ' sprintf('%1.3f', voltsX) ' by ' sprintf('%1.3f', voltsY) ' mV'];
            zImage.info.SourceProcessing = 'Zoom = 1 Rotation = 0';
            objectives = get(findobj('tag', 'objectiveName'), 'string');
            zImage.info.delta = repmat(micronsPerPixel(sscanf(objectives{get(findobj('tag', 'objectiveName'), 'value')}, '%*s %gx/%*g'), voltsX, zImage.info.Width), 3, 1);
            
            zImage = takeTwoPhotonNI([], scanPoints, [], pixelUs, returnPosition, 0, struct('lagX', lagX, 'pixelsY', pixelsY, 'turnLength', turnLength, 'header', zImage.info));             
        end
        
        if isempty(zImage)
            return % aborted for some reason
        end
        
        if returnPosition
            zImage.photometry(:,1) = circshift(zImage.photometry(:,1), [-round(lagX) 0]);
        else
            % correct for lags
%                 zImage.stack = reshape(zImage.photometry(:,1), [], pixelsY);                
            zImage.stack = reshape(circshift(zImage.photometry(:,1), [-round(lagX) 0]), [], pixelsY);

            % trim off the turn arounds
            zImage.stack = zImage.stack(turnLength + 1:end, :);

            % flip the return lines of the x dimension
            zImage.stack(:, 1:2:end) = zImage.stack(end:-1:1, 1:2:end);  
        end
    end
end