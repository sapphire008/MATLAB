function timeFormat = sec2time(numSecs)
% convert seconds to hh:mm:ss.s format
% timeFormat = sec2time(numSecs);

    if length(numSecs) == 1
        timeFormat = [sprintf('%2.0f', fix(numSecs / 3600)) ':' sprintf('%02.0f', fix((numSecs - fix(numSecs / 3600) * 3600) / 60)) ':' sprintf('%04.1f', numSecs - fix((numSecs - fix(numSecs / 3600) * 3600) / 60) * 60 - fix(numSecs / 3600) * 3600)];
    else
        for i = 1:size(numSecs, 1)
            if ischar(numSecs(i,:))
                tempSecs = str2double(numSecs(i,:));
            else
                tempSecs = numSecs(i,:);
            end
            timeFormat{i, :} =  [sprintf('%2.0f', fix(tempSecs / 3600)) ':' sprintf('%02.0f', fix((tempSecs - fix(tempSecs / 3600) * 3600) / 60)) ':' sprintf('%04.1f', tempSecs - fix((tempSecs - fix(tempSecs / 3600) * 3600) / 60) * 60 - fix(tempSecs / 3600) * 3600)];
        end
    end