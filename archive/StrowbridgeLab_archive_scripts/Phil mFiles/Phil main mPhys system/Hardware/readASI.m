function currentPosition = readASI

    if ~isappdata(0, 'asiPort')
        currentPosition = [0 0 0];
        return;
    end
	commPort = getappdata(0, 'asiPort');
    
    try
        fwrite(commPort, [char(24) char(97) char(3) char(58)]);
        tempData = fread(commPort, 3, 'char');
        if numel(tempData)
            currentPosition(1) = (tempData(1) + 256 * tempData(2) + 256 * 256 * tempData(3)) / 10;
            if currentPosition(1) > 2^23 / 10
                currentPosition(1) = -2^24 / 10 + currentPosition(1);
            end
        else
            currentPosition(1) = nan;
            warning off last
        end

        fwrite(commPort, [char(25) char(97) char(3) char(58)]);
        tempData = fread(commPort, 3, 'char');
        if numel(tempData)
            currentPosition(2) = (tempData(1) + 256 * tempData(2) + 256 * 256 * tempData(3)) / 10;
            if currentPosition(2) > 2^23 / 10
                currentPosition(2) = -2^24 / 10 + currentPosition(2);
            end        
        else
            currentPosition(2) = nan;
            warning off last
        end

        fwrite(commPort, [char(26) char(97) char(3) char(58)]);
        tempData = fread(commPort, 3, 'char');
        if numel(tempData)
            currentPosition(3) = -(tempData(1) + 256 * tempData(2) + 256 * 256 * tempData(3)) / 10;
            if currentPosition(3) < -2^23 / 10
                currentPosition(3) = 2^24 / 10 + currentPosition(3);
            end        
        else
            currentPosition(3) = nan;
            warning off last
        end
    catch
        % reset the com port
        fclose(commPort);
        fopen(commPort);
        currentPosition = [nan nan nan];
    end