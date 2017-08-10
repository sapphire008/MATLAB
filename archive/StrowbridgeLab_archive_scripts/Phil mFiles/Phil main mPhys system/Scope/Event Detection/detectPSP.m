function events = detectPSP(inData, timePerPoint)
    if ~nargin
        events = 'PSPs';
    else
        events = [];
        if ~isappdata(0, 'pspGui');
            currentFigure = gcf;
            pspGui;
            set(0, 'currentFigure', currentFigure);
        end
    end