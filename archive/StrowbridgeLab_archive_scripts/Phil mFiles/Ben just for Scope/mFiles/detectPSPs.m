% use this function to detect the PSPs in your data using a PSP finding algorithm
% params = detectPSPs(data, PSPsDown, windows, windowSize, parameter pairs)
% or params = detectPSPs(data, PSPsDown, windows, windowSize)
% or params = detectPSPs(data, PSPsDown)
% if either pairs of parameter names and values xor a parameters structure is passed they must be the last arguement

% The algorithm used is based on that of Cohen and Miles 2000
% Briefly, the data are filtered and the derivative is taken.
% A function is generated based on the rule that a point is equal to the
% sum of the derivative at that point and the previous point only if the
% derivative is greater than (for upward PSPs) zero otherwise the function
% is zero at that point.
% This is then thresholded and sent for fitting by alpha functions and one
% variable is returned:
% Params(1,:) = amplitude of psp
% Params(2,:) = rise time
% Params(3,:) = x-offset of alpha function
% Params(4,:) = decay time

% To untangle multiple stacked PSPs as after a stim the readjustment of
% minYOffset/maxYOffset and also an iterative mechanism to break down giant

function [params decayFits] = detectPSPs(data, varargin)

warning off MATLAB:divideByZero
warning off all % to avoid a lot of errors with the best fitting

%%%
% Parse through the inputs
%%%

    % pick the orientation that we like
    if nargin > 0
        if size(data, 1) > size(data, 2)
            data = data';
        end
    else
        error('Must specify data on which to operate');
    end

    % if more than one data set then reject
    if size(data, 1) > 1
        error('Input must be a 1 x N vector')
    end

    % look for the structure of input parameters
    hasParameters = 0;
    for i = 1:nargin - 1
        if isstruct(varargin{i})
            hasParameters = i;
            parameters = varargin{i};
            break
        end
    end

    % find the first pair of input properties
    firstChar = nargin + 1;
    if ~hasParameters
        for i = 1:nargin - 1
            if ischar(varargin{i})
                firstChar = i + 1;
                break
            end
        end
    end

    switch firstChar - 1 - (hasParameters > 0)
        case 0
            windows = 1; % so that we include the whole time
            windowSize = length(data);
            % determine whether events are up or down
            if median(data) > mean(data)
                % events are down
                PSPsDown = 1;
            else
                % events are up
                PSPsDown = 0;
            end
        case 1
            windows = 1; % so that we include the whole time
            windowSize = length(data);
            % determine whether events are up or down
            if median(data) > mean(data)
                % events are down
                PSPsDown = 1;
            else
                % events are up
                PSPsDown = 0;
            end
        case 2
            PSPsDown = varargin{1};
            windows = 1; % so that we include the whole time
            windowSize = length(data);
        case 3
            % determine whether events are up or down
            if median(data) > mean(data)
                % events are down
                PSPsDown = 1;
            else
                % events are up
                PSPsDown = 0;
            end
            windows = varargin{1};
            windowSize = varargin{2};        
        case 4
            if ismember(varargin{1}, [0 1])
                PSPsDown = varargin{1};
                windows = varargin{2};
                windowSize = varargin{3};
            else
                % determine whether events are up or down
                if median(data) > mean(data)
                    % events are down
                    PSPsDown = 1;
                else
                    % events are up
                    PSPsDown = 0;
                end
                windows = varargin{1};
                windowSize = varargin{2};  
                parameters = varargin{3};            
            end
        case 5
            PSPsDown = varargin{1};
            windows = varargin{2};
            windowSize = varargin{3};
            parameters = varargin{4};
    end

    if ~hasParameters 
        if PSPsDown
            parameters = struct('minAmp', (-5000),... % minimum allowable amplitude for alpha functions (in units of samples)
                'maxAmp', (-5),... % maximum allowable amplitude
                'minTau', (5),... % minimum allowable tau for alpha functions (in units of samples)
                'maxTau', (100),... %maximum allowable tau
                'minYOffset', (-100),... % minimum allowable yOffset for alpha functions (in units of mV)
                'maxYOffset', (-30),... % maximum allowable yOffset
                'minDecay', (5),... % minimum allowable decay tau
                'maxDecay', (500),... % maximum allowable decay tau
                'derThresh', (1),... % threshold used to determine if the change of derivative is great enough to separate out two alpha functions
                'closestEPSPs', (5),... % second EPSP is not recognized if it is closer than this value to the previous one (in units of samples)
                'errThresh', (0.08),... % threshold for standard error above which a fit with multiple alphas is attempted
                'dataFilterType', 1,... % 0 = none 1 = windowFilter, 2 = medianFilter, 3 = savitsky-golay
                'derFilterType', 3,... % 0 = none 1 = windowFilter, 2 = medianFilter, 3 = savitsky-golay
                'dataFilterLength', 5,... % length of data filter
                'derFilterLength', 7,... % length of derivative filter
                'debugging', (0),... % if set to 1 then debugging figures appear
                'outputAxis', 0,... % axis to which any output will be written
                'dataStart', 1,... % index of first data point
                'forceDisplay', 0,... % forces a graphical output even if other outputs are taken
                'fitAlpha', 0,... % alpha function fit to the first part of the response
                'fitDecay', 0,... % exponential fit to the decay
                'fitRise', 0); % exponential fit to the rise
        else
            parameters = struct('minAmp', (5),... % minimum allowable amplitude for alpha functions (in units of samples)
                'maxAmp', (5000),... % maximum allowable amplitude
                'minTau', (5),... % minimum allowable tau for alpha functions (in units of samples)
                'maxTau', (100),... %maximum allowable tau
                'minYOffset', (-100),... % minimum allowable yOffset for alpha functions (in units of mV)
                'maxYOffset', (-30),... % maximum allowable yOffset
                'minDecay', (5),... % minimum allowable decay tau
                'maxDecay', (500),... % maximum allowable decay tau            
                'derThresh', (1),... % threshold used to determine if the change of derivative is great enough to separate out two alpha functions
                'closestEPSPs', (5),... % second EPSP is not recognized if it is closer than this value to the previous one (in units of samples)
                'errThresh', (0.004),... % threshold for standard error above which a fit with multiple alphas is attempted
                'dataFilterType', 1,... % 0 = none 1 = windowFilter, 2 = medianFilter, 3 = savitsky-golay
                'derFilterType', 3,... % 0 = none 1 = windowFilter, 2 = medianFilter, 3 = savitsky-golay
                'dataFilterLength', 5,... % length of data filter
                'derFilterLength', 7,... % length of derivative filter
                'debugging', (0),... % if set to 1 then debugging figures appear
                'outputAxis', 0,... % axis to which any output will be written
                'dataStart', 1,... % index of first data point
                'forceDisplay', 0,... % forces a graphical output even if other outputs are taken
                'fitAlpha', 0,... % alpha function fit to the first part of the response
                'fitDecay', 0,... % exponential fit to the decay
                'fitRise', 0); % exponential fit to the rise
        end
    end

    if firstChar < nargin
        if ~mod(nargin - firstChar, 2)
            disp('Inappropriate input');
            return
        else
            % specific parameters where passed so figure out which they were
            strArray = fieldnames(parameters);
            for paramIndex = firstChar - 1:2:numel(varargin)
                whichParam = strfind(strArray, varargin{paramIndex});
                if find(cell2mat(whichParam))
                    parameters.(varargin{paramIndex}) = varargin{paramIndex + 1};
                else
                    error([varargin{paramIndex} ' is not a valid parameter'])
                end
            end
        end
    end

    if nargin > 0 && isa(data, 'char') || nargin == 0
        if nargin == 0
            zData = readTrace;
        else
            zData = readTrace(data);
        end

        [selection,okTrue] = listdlg('PromptString','Select a channel:',...
                    'SelectionMode','single',...
                    'ListSize', [200 80],...
                    'ListString',zData.protocol.channelNames);
        if okTrue
            data = zData.traceData(:, selection)';
        else
            disp('Must select input data');
            params = -1;
            return
        end
    end

% make sure that the filter length is odd
if parameters.dataFilterLength / 2 == fix(parameters.dataFilterLength / 2)
    parameters.dataFilterLength = parameters.dataFilterLength + 1;
end

if parameters.derFilterLength / 2 == fix(parameters.derFilterLength / 2)
    parameters.derFilterLength = parameters.derFilterLength + 1;
end

% reset the error threshold to reflect the noise in the signal
sortedData = sort(data);
if PSPsDown
    dataMean = mean(sortedData(size(data, 2) * .7:size(data, 2) * .9)); % mean of top 10-30% of data
    dataDev = std(sortedData(size(data, 2) * .6:size(data, 2) * .8)); % standard deviation of top 20-40% of data
    % or noise = data - dataFilt; dataDev = std(noise(1:1000));
    % dataDev = std(highPass(data)) * 3;
else
    dataMean = mean(sortedData(size(data, 2) * .1:size(data, 2) * .3)); % mean of bottom 10-30% of data
    dataDev = std(sortedData(size(data, 2) * .2:size(data, 2) * .4)); % standard deviation of bottom 20-40% of data
    %dataDev = std(highPass(data)) * 3;
end
parameters.errThresh = parameters.errThresh / dataDev;

% determine if data is current or voltage clamp
if nargin < 5 && ~hasParameters
    if max(data) > 50 || min(data) < -100
        % this must be voltage clamp
        parameters.minYOffset = dataMean - 200 * dataDev;
        parameters.maxYOffset = dataMean + 200 * dataDev;
    else
        % probably current clamp
        parameters.derThresh = .3;
        parameters.minAmp = 0.2;
        parameters.maxAmp = 50;
        parameters.minYOffset = dataMean - 3;
        parameters.maxYOffset = dataMean + 3;
    end
end

% if the person mixed up the max and min values then switch them
if (PSPsDown && (parameters.minAmp > 0 || parameters.maxAmp > 0)) || (~PSPsDown && (parameters.minAmp < 0 || parameters.maxAmp < 0))
    tempAmp = min(sign(-PSPsDown + 0.5) * abs([parameters.minAmp parameters.maxAmp]));
    parameters.maxAmp = max(sign(-PSPsDown + 0.5) * abs([parameters.minAmp parameters.maxAmp]));
    parameters.minAmp = tempAmp;
end

% filter the raw data
switch parameters.dataFilterType
    case 0 % no filtering
        dataFilt = data;
    case 1 % window filtering
        dataFilt = movingAverage(data, parameters.dataFilterLength);
    case 2 % median filtering
        dataFilt = medfilt1(data, parameters.dataFilterLength);
    case 3 % savitsky-golay
        dataFilt = sgolayfilt(data, 2, parameters.dataFilterLength);
end

% filter the derivative
tempDiff = diff(dataFilt);
switch parameters.derFilterType
    case 0 % no filtering
        dataDerFilt = tempDiff;
    case 1 % window filtering
        dataDerFilt = movingAverage(tempDiff, parameters.derFilterLength);
    case 2 % median filtering
        dataDerFilt = medfilt1(tempDiff, parameters.derFilterLength);
    case 3 % savitsky-golay
        dataDerFilt = sgolayfilt(tempDiff, 2, parameters.derFilterLength);
end
clear tempDiff;

% filter as per Cohen and Miles 2000
outData = zeros(size(dataFilt));
if PSPsDown
    for index = 2:length(dataFilt)
        if dataDerFilt(index - 1) < 0
            outData(index) = outData(index - 1) + dataDerFilt(index - 1);
        end
    end
else
    for index = 2:length(dataFilt)
        if dataDerFilt(index - 1) > 0
            outData(index) = outData(index - 1) + dataDerFilt(index - 1);
        end
    end    
end

if PSPsDown
    % find where derivative of this function is changing from negative to positive
    functionDer = diff(outData);
    peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) < 0);
else
    % find where derivative of this function is changing from positive to negative
    functionDer = diff(outData);
    peaks = find((functionDer(2:length(functionDer)) ./ functionDer(1:length(functionDer) -1) < 0 | functionDer(2:length(functionDer)) == 0) & functionDer(1:length(functionDer) - 1) > 0);
end

% for each such value greater than derThresh find where the function last
% began to deviate from 0 and call that an event start
numStarts = 0;
whereStarts = ones(length(peaks), 1);
wherePeaks = whereStarts;
for index = 1:length(peaks)
    if abs(outData(peaks(index))) > parameters.derThresh
        numStarts = numStarts + 1;
        whereStarts(numStarts) = peaks(index);
        while outData(whereStarts(numStarts)) ~= 0
            whereStarts(numStarts) = whereStarts(numStarts) - 1;
        end
        wherePeaks(numStarts) = peaks(index);
    end
end
whereStarts(numStarts + 1) = length(outData);
whereStarts(numStarts + 2:end) = [];
wherePeaks(numStarts + 1:end) = [];

if parameters.debugging
    figure
    plot(dataFilt);
    line(1:length(outData), outData + mean(dataFilt), 'Color', [1 0 0]);
    line(1:length(functionDer), functionDer + mean(dataFilt), 'Color', [0 1 0]);
    line(wherePeaks, dataFilt(wherePeaks), 'Color', [1 0 1], 'linestyle', 'none', 'marker', '+');
    line(whereStarts, dataFilt(whereStarts), 'Color', [0 0 0], 'linestyle', 'none', 'marker', '+');
    if PSPsDown
        line([1 length(dataFilt)], -[parameters.derThresh parameters.derThresh] + mean(dataFilt), 'Color', [1 0 0], 'linestyle', ':');
    else
        line([1 length(dataFilt)], [parameters.derThresh parameters.derThresh] + mean(dataFilt), 'Color', [1 0 0], 'linestyle', ':');        
    end
    fitLine = line([0 1], [dataMean dataMean], 'Color', [0 0 0]);
    decayLine = line([0 1], [dataMean dataMean], 'Color', [1 0 1]);
    riseStart = line([0 1], [dataMean dataMean], 'linestyle', 'none', 'marker', 'x', 'Color', [0.5430 0.2695 0.0742]);
    fitProps = annotation('textbox',[.8 .1 .1 .1], 'backgroundcolor', [1 1 1]);
    legend('Data', 'Up-Only Function', 'Derivative of U-O Fn', 'Event Peaks', 'Events Starts', 'Threshold for choosing', 'Fit line', 'Decay Fit', 'Rise Line');
end

% set a counter for events
numEvents = 0;
% create output array for alpha best fit parameters
params = zeros(1,4);

for indexEPSP = 1:length(whereStarts) - 1
    if whereStarts(indexEPSP + 1) - whereStarts(indexEPSP) < parameters.closestEPSPs
        continue % skip this iteration if the next fitting spot is really close
    end
    
    if any(~(whereStarts(indexEPSP)  < windows  - windowSize | whereStarts(indexEPSP)  > windows +  2 * windowSize)) % skip this iteration if the found event is outside of the given windows + a buffer of windowSize on each side in case the location is imprecise
        % must get tau within +/- 50% of the true value or the fitting
        % algorithm does not converge (norm of step goes below boundary
        % condition)
        tauGuess = max(wherePeaks(indexEPSP) - whereStarts(indexEPSP), parameters.minTau);
        ampGuess = dataFilt(wherePeaks(indexEPSP)) - dataFilt(whereStarts(indexEPSP));
        whereStop = whereStarts(indexEPSP + 1) - whereStarts(indexEPSP);
        if whereStop > 4 * tauGuess
            whereStop = 2 * tauGuess;
        end
        
        if parameters.alphaFit
            [bestParams, residuals] = nlinfit(whereStarts(indexEPSP):whereStarts(indexEPSP) + whereStop, dataFilt(whereStarts(indexEPSP):whereStarts(indexEPSP) + whereStop), @alpha, [ampGuess, tauGuess, whereStarts(indexEPSP), dataFilt(whereStarts(indexEPSP))], statset('MaxIter', 1000, 'FunValCheck', 'off'));
            %calculate standard error
            bestStdErr = sqrt(residuals' * residuals) / (length(residuals) - 2) / abs(bestParams(1));

            %show the fit line
            if parameters.debugging
                set(fitLine, 'Xdata', whereStarts(indexEPSP):whereStarts(indexEPSP) + whereStop, 'Ydata', alpha(bestParams, whereStarts(indexEPSP):whereStarts(indexEPSP) + whereStop));
                xBounds = get(gca, 'Xlim');
                if xBounds(2) < whereStarts(indexEPSP) + whereStop
                   set(gca, 'Xlim', [whereStarts(indexEPSP) - 50 whereStarts(indexEPSP) + 250]);
                end
            end      
        else
            bestParams = [0 parameters.minTau + 1 whereStarts(indexEPSP) dataFilt(whereStarts(indexEPSP))];
            if PSPsDown
                bestParams(1) = min(dataFilt(whereStarts(indexEPSP):whereStarts(indexEPSP) + whereStop));
            else
                bestParams(1) = max(dataFilt(whereStarts(indexEPSP):whereStarts(indexEPSP) + whereStop));                
            end
            bestParams(1:2) = bestParams(1:2) - [dataFilt(whereStarts(indexEPSP)) 0];
            bestStdErr = 0;
        end
        
        if ~(parameters.minAmp < bestParams(1)  && parameters.maxAmp * 2.7183 > bestParams(1)  &&... % is the amplitude ok?
                    parameters.minTau < bestParams(2)  && parameters.maxTau > bestParams(2)  &&... % is the tau ok?
                    whereStarts(indexEPSP + 1) - bestParams(3) > bestParams(2) * 0.5 &&... % do we really have enough to fit a function to it?
                    parameters.minYOffset < bestParams(4) && parameters.maxYOffset > bestParams(4)) ||...% is it in the right place? 
                    ~any(~(bestParams(3)  < windows  | bestParams(3)  > windows + windowSize)) % is it in the window that we're looking in
            bestStdErr = inf; % set high so that any other fit is accepted since this one has parameters out of range
        end
        
        % refit variables
        if bestStdErr < parameters.errThresh       
            
            bestParams(1) = dataFilt(wherePeaks(indexEPSP)) - dataFilt(whereStarts(indexEPSP));  
            bestParams(4) = dataFilt(whereStarts(indexEPSP));
            % find where the trace is at 20% of max rise
            howLong = min([45 wherePeaks(indexEPSP) - whereStarts(indexEPSP)]);
            [loc loc] = max(1 ./ (dataFilt(whereStarts(indexEPSP):whereStarts(indexEPSP) + howLong) - (bestParams(4) + .10 * bestParams(1))));
            % make sure that this point is the last time we have this situation (is on the rising phase)
            
            % linearly interpolate
            pointDrop = dataFilt(loc + whereStarts(indexEPSP) - 1) - dataFilt(loc + whereStarts(indexEPSP)); 

            % sometimes the pointDrop is zero and this creates an infinite rise time
            if pointDrop == 0 || pointDrop * (PSPsDown - .5) < 0 % if this product is negative then we're dealing with a jagged spot
                loc = loc + 1;
                pointDrop = dataFilt(loc + whereStarts(indexEPSP) - 1) - dataFilt(loc + whereStarts(indexEPSP)); 
                twentyRise = wherePeaks(indexEPSP) - whereStarts(indexEPSP) - (loc + 1 - ((bestParams(4) + .10 * bestParams(1) - dataFilt(whereStarts(indexEPSP) + loc)) / pointDrop));                
            else
                twentyRise = wherePeaks(indexEPSP) - whereStarts(indexEPSP) - (loc + 1 - ((bestParams(4) + .10 * bestParams(1) - dataFilt(whereStarts(indexEPSP) + loc)) / pointDrop));
            end
                
            if parameters.riseFit
                startPoint = [];
                twentyRise = round(twentyRise);
                if wherePeaks(indexEPSP) - twentyRise <= whereStarts(indexEPSP)
                    whereStarts(indexEPSP) = wherePeaks(indexEPSP) - twentyRise - 1;
                end
%                 if twentyRise > 10 % if this is a slow one then fit it with a more advanced method
%                     % fit the portion of the rise that we think is definitley clean
%                     [estimates estimates estimates estimates] = fitDecayDouble(dataFilt(wherePeaks(indexEPSP) - twentyRise:wherePeaks(indexEPSP) - 2));
%                     if ~isnan(estimates)
%                         xdata = ((whereStarts(indexEPSP) - wherePeaks(indexEPSP)) + twentyRise:twentyRise - 2);
%                         errorVector = (estimates(1) + sign(bestParams(3)) * estimates(2) .* exp(xdata./estimates(3)) + sign(bestParams(3)) * estimates(4) .* exp(xdata./estimates(5)) - dataFilt(round(xdata + wherePeaks(indexEPSP) - twentyRise))) .^ 2;
%                         errBound = mean(errorVector(length(xdata) - twentyRise + 1:end)) + 3 * std(errorVector(length(xdata) - twentyRise + 1:end));
% 
%                         % find the first two points where we deviate from the curve more than we do in the clean part
%                         startPoint = find(errorVector(1:length(xdata) - twentyRise) > errBound & errorVector(2:length(xdata) - twentyRise + 1) > errBound, 1, 'last') + 1;
%                         if ~isempty(startPoint) && parameters.debugging
%                             xdata = xdata(startPoint:end);
%                             FittedRise = estimates(1) + sign(bestParams(3)) * estimates(2) .* exp(xdata./estimates(3)) + sign(bestParams(3)) * estimates(4) .* exp(xdata./estimates(5));
%                         end
%                     end
%                 end
                
                % if the above fit failed or we didn't have enough point to attempt it then
                if isempty(startPoint) && twentyRise > 3
                    % fit the portion of the rise that we think is definitley clean
                    [estimates estimates estimates] = fitDecaySingle(dataFilt(wherePeaks(indexEPSP) - twentyRise:wherePeaks(indexEPSP) - 2));
                    if ~isnan(estimates)
                        xdata = ((whereStarts(indexEPSP) - wherePeaks(indexEPSP)) + twentyRise:twentyRise - 2);
                        errorVector = (estimates(1) + sign(bestParams(3)) * estimates(2) .* exp(xdata./estimates(3)) - dataFilt(round(xdata + wherePeaks(indexEPSP) - twentyRise))) .^ 2;
                        errBound = mean(errorVector(length(xdata) - twentyRise + 1:end)) + 3 * std(errorVector(length(xdata) - twentyRise + 1:end));

                        % find the first two points where we deviate from the curve more than we do in the clean part
                        startPoint = find(errorVector(1:length(xdata) - twentyRise) > errBound & errorVector(2:length(xdata) - twentyRise + 1) > errBound, 1, 'last') + 1;
                        if ~isempty(startPoint) && parameters.debugging
                            xdata = xdata(startPoint:end);
                            FittedRise = estimates(1) + sign(bestParams(3)) * estimates(2) .* exp(xdata./estimates(3));
                        end
                    end
                end
                
                if isempty(startPoint)
                    startPoint = loc;
                    FittedRise = ones(twentyRise, 1) * dataFilt(whereStarts(indexEPSP));
                    errBound = 0;
                end
                bestParams(3) = startPoint  + whereStarts(indexEPSP);
            else
                bestParams(3) = whereStarts(indexEPSP);
            end
            bestParams(3) = whereStarts(indexEPSP);
            bestParams(2) = wherePeaks(indexEPSP) - bestParams(3); %whereStarts(indexEPSP);
            if parameters.decayFit
                % change bestParams(4) to the decay tau
                whichData = round(bestParams(3) + bestParams(2) * 1.5:min([bestParams(3) + bestParams(2) * 1.5 + 100 whereStarts(indexEPSP + 1)]));
                if length(whichData) > 5
                    [bestParams(4) FittedDecay] = fitDecaySingle(dataFilt(whichData));
                    residuals = FittedDecay' - dataFilt(whichData);
                    if sqrt(residuals' * residuals) / (length(whichData) - 2) / abs(bestParams(1)) > parameters.errThresh
                        bestParams(4) = NaN;
                        FittedDecay = NaN;
                    end
                else
                    bestParams(4) = NaN;
                    FittedDecay = NaN;
                end

                if isnan(bestParams(4))
                   % make a manual guess
                   if PSPsDown == 0
                        tempDecay = find(dataFilt(wherePeaks(indexEPSP) + 2:min([wherePeaks(indexEPSP) + 90 whereStarts(indexEPSP + 1)])) < (dataFilt(wherePeaks(indexEPSP)) - log(2) * (dataFilt(wherePeaks(indexEPSP)) - min(dataFilt(wherePeaks(indexEPSP) + 2:min([wherePeaks(indexEPSP) + 90 whereStarts(indexEPSP + 1)]))))), 1, 'first');
                   else
                        tempDecay = find(dataFilt(wherePeaks(indexEPSP) + 2:min([wherePeaks(indexEPSP) + 90 whereStarts(indexEPSP + 1)])) > (dataFilt(wherePeaks(indexEPSP)) - log(2) * (dataFilt(wherePeaks(indexEPSP)) - max(dataFilt(wherePeaks(indexEPSP) + 2:min([wherePeaks(indexEPSP) + 90 whereStarts(indexEPSP + 1)]))))), 1, 'first');                       
                   end
                   if ~isempty(tempDecay)
                        bestParams(4) = tempDecay;
                        FittedDecay = ones([1 length(whichData)]) * dataFilt(wherePeaks(indexEPSP));
                   else
                        bestParams(4) = parameters.minDecay - 1;
                   end
                end

                if parameters.debugging               
                   set(fitProps, 'String',  [{['\bf Amp: ' num2str(bestParams(1))]};{[' Rise: ' num2str(bestParams(2))]};{[' Start: ' num2str(bestParams(3))]};{[' Decay: ' num2str(bestParams(4))]}]);
                   set(decayLine, 'Xdata', whichData, 'Ydata', FittedDecay);
                   set(gca, 'ylimmode', 'auto');
                   set(gca, 'xlim', [max([1 whereStarts(indexEPSP) - 10]) min([max([1 whereStarts(indexEPSP) - 10]) + max([bestParams(2) * 5 200]) length(data)])]);
                   savedLims = get(gca, 'ylim');
                   set(riseStart, 'xdata', bestParams(3), 'ydata', dataFilt(round(bestParams(3))));
                   set(gca, 'ylim', savedLims);
                   pause
                end
            else
                bestParams(4) = parameters.minDecay + 1;
            end
            
            if bestParams(4) >= parameters.minDecay && bestParams(4) <= parameters.maxDecay &&...
                    bestParams(1) >= parameters.minAmp && bestParams(1) <= parameters.maxAmp
%                 bestParams(2) = wherePeaks(indexEPSP) - whereStarts(indexEPSP);
                params(numEvents + 1, :) = bestParams;
                if parameters.decayFit
                    decayFits{numEvents + 1} = FittedDecay;
                end
                %dataFilt  = dataFilt - alpha([bestParams(:, 1:3) zeros(size(bestParams, 1), 1)], 1:length(dataFilt)); % subtract off found data (0 is to avoid subtracting off the yOffset)
                numEvents = numEvents + 1;
            end
        end
    end
end

if ~parameters.decayFit
    decayFits = nan(size(params));
    params(:,4) = nan;
end

% show how well our found trace fits the original data
if nargout == 0 || parameters.forceDisplay
    if parameters.outputAxis == 0 || ~ishandle(parameters.outputAxis)
        if max(data) > 50 || min(data) < -100
            parentHandle = newScope(data, 1:length(data), 'Trace I');
        else
            parentHandle = newScope(data, 1:length(data), 'Trace V');
        end
        parentHandle = parentHandle.axes;
    else
        parentHandle = parameters.outputAxis;      
    end

    set(0, 'currentfigure', get(parentHandle, 'parent'));
    set(gcf, 'currentAxes', parentHandle);      
    
    % set the time variables to be in the time units of the current axis
    timeDiff = get(gca, 'child');
    timeDiff = timeDiff(end - 2);
    timeDiff = get(timeDiff, 'xdata');
    timeDiff = timeDiff(2) - timeDiff(1);
    params(:, 2:4) = params(:, 2:4) * timeDiff;
    parameters.dataStart = parameters.dataStart * timeDiff;
    
    try
        for i = 1:size(params, 1)
            % plot starts
            line(parameters.dataStart + params(i, 3), data(round(params(i, 3)/timeDiff)), 'Color', [0 0 1], 'linestyle', 'none', 'marker', '+', 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Start time = ' sprintf('%6.1f', params(i,3)) ''')']);
            % plot amplitudes
            line(parameters.dataStart + [params(i, 3) + params(i, 2) params(i, 3) + params(i, 2)], [data(round(params(i, 3)/ timeDiff + params(i, 2) / timeDiff)) - params(i, 1) data(round(params(i, 3)/ timeDiff + params(i, 2)/ timeDiff))], 'Color', [0 1 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', {''Rise time = ' sprintf('%4.1f', params(i,2)) '''; ''Amplitude = ' sprintf('%7.2f', params(i,1)) '''})']);
            if parameters.decayFit
                % plot decay tau
                line(parameters.dataStart + ((params(i, 3)/timeDiff + params(i, 2)/timeDiff * 1.5:params(i, 3)/timeDiff + params(i, 2)/timeDiff * 1.5 + numel(decayFits{i}) - 1) * timeDiff), decayFits{i}, 'Color', [1 0 0], 'buttondownfcn', ['set(get(get(gcbo, ''parent''), ''userdata''), ''string'', ''Decay tau = ' sprintf('%6.2f', params(i,4)) ''')']);        
            end
        end
    catch
        % at least return something
        
    end
end