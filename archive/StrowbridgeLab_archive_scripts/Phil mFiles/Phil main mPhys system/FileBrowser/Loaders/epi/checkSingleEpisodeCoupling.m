function outText = checkSingleEpisodeCoupling(fileNames)
    persistent lastVals
    
    if ~nargin
        outText = 'Check Coupling';
        return
    end
    
    if isempty(lastVals)
        lastVals = {'.5', '3', '1', '1'};
    end
    
    whereBounds = inputdlg({'Window Delay (msec)', 'Window Length (msec)', 'Fitting Option'},'',1, lastVals);
    
    if ~isempty(whereBounds)
        lastVals = whereBounds;
        windowDelay = str2double(whereBounds{1});
        windowLength = str2double(whereBounds{2});
        fittingOption = str2double(whereBounds{3});
        % find all selected files
        for i = fileNames
            checkCoupling(i{1}, windowLength, windowDelay, [fittingOption 1 1 1]);
        end
    end