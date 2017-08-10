function handles = scaleBar(currentAxis, info)

    if nargin == 1
        currentAxis = gca;
    end
   
    if isfield(info, 'SizeOnSource')
        mPerP = micronsPerPixel(sscanf(info.Objective, '%*s %gx/%*g'), sscanf(info.SizeOnSource, 'Size = %g by'), info.Width);
    else
        % assume is a frame grab, which are 7 x 5.25 V
%         info.Objective = 'Zeiss 5x/.12';
        info.Objective = 'Olympus 60x/.90W ';        
        mPerP = micronsPerPixel(sscanf(info.Objective, '%*s %gx/%*g'), 7, info.Width);
    end
    colors = [1 1 1; 1 0 0; 0 1 0; 0 0 1];
    colorIndex = 4;
    
    positions = [.7 .1; .7 .9; .1 .9; .1 .1];
    positionIndex = 4;
    
    % add scale bar
    xGap = diff(get(currentAxis, 'xlim'));
    howManyXDigits = floor(log10(xGap * mPerP / 5));
    if howManyXDigits < 0
        howManyXDigits = floor(log10(xGap * mPerP) / 2.5);
    end
    xBarSize = round((xGap/(5*10^howManyXDigits)) * mPerP)*10^howManyXDigits; 

    switch 1
        case xBarSize >= 1000
            xLabel = [num2str(xBarSize  / 1000) ' mm'];
        case xBarSize >= 1
            xLabel = [num2str(xBarSize) ' ' char(181) 'm'];
        otherwise
            xLabel = [num2str(xBarSize * 1000) ' nm'];
    end 

    handles(1) = line(min(get(currentAxis, 'xlim')) + positions(mod(positionIndex, 4) + 1, 1) * diff(get(currentAxis, 'xlim')) + [0 xBarSize / mPerP], min(get(currentAxis, 'ylim')) + positions(mod(positionIndex, 4) + 1, 2) * diff(get(currentAxis, 'ylim')) + [0 0], 'linewidth', 3, 'parent', currentAxis, 'color', colors(mod(colorIndex, 4) + 1,:), 'tag', 'scaleBar');
    handles(2) = text(min(get(currentAxis, 'xlim')) + positions(mod(positionIndex, 4) + 1, 1) * diff(get(currentAxis, 'xlim')) + xBarSize / mPerP / 2, min(get(currentAxis, 'ylim')) + (positions(mod(positionIndex, 4) + 1, 2) - 0.03) * diff(get(currentAxis, 'ylim')), xLabel, 'parent', currentAxis, 'color', colors(mod(colorIndex, 4) + 1,:), 'horizontalalignment', 'center', 'tag', 'scaleBar');
    set(handles, 'buttonDownFcn', @mouseDown);

    function mouseDown(varargin)
        switch get(gcf, 'selectionType')
            case 'alt'
                % change the color
                colorIndex = colorIndex + 1;
                set(handles, 'color', colors(mod(colorIndex, 4) + 1, :));
            case 'extend'
                % change the location
                positionIndex = positionIndex + 1;
                set(handles(1), 'xData', min(get(currentAxis, 'xlim')) + positions(mod(positionIndex, 4) + 1, 1) * diff(get(currentAxis, 'xlim')) + [0 xBarSize / mPerP], 'ydata', min(get(currentAxis, 'ylim')) + positions(mod(positionIndex, 4) + 1, 2) * diff(get(currentAxis, 'ylim')) + [0 0]);
                set(handles(2), 'position', [min(get(currentAxis, 'xlim')) + positions(mod(positionIndex, 4) + 1, 1) * diff(get(currentAxis, 'xlim')) + xBarSize / mPerP / 2, min(get(currentAxis, 'ylim')) + (positions(mod(positionIndex, 4) + 1, 2) - .03) * diff(get(currentAxis, 'ylim'))]);
        end
    end
end