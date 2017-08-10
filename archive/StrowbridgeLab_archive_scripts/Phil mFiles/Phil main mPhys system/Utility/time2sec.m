function seconds = time2sec(time)
% convert hh:mm:ss.s format to a number of seconds
% seconds = time2sec(time)

    whereColons = [0 find(time == ':')];
    
    seconds = str2double(time(whereColons(end) + 1:end));
    if length(whereColons) > 1
        for i = 1:length(whereColons) - 1
            seconds = seconds + str2double(time(whereColons(i) + 1:whereColons(i + 1) - 1)) * 60 ^ (length(whereColons) - i);
        end
    end