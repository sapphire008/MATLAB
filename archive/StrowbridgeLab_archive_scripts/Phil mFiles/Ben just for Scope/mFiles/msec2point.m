function outString = msec2point(inString, pointsPerMsec, firstTime)

[starts stops] = regexp(inString, 'data\(.*?[:)]');
[junk stops2] = regexp(inString, 'data\(.*?\)');

if ~isempty(starts)
    if stops2(1) == stops(1)
		if isnan(str2double(inString(starts(1) + 5:stops(1) - 1)))
			% probably a logical
			outString = inString(1:stops(1) - 1);
		else
			% single number
			outString = [inString(1:starts(1) + 4) num2str(round((str2double(inString(starts(1) + 5:stops(1) - 1)) - firstTime) * pointsPerMsec + 1))];
		end
	else
		% range
        outString = [inString(1:starts(1) + 4) num2str(round((str2double(inString(starts(1) + 5:stops(1) - 1)) - firstTime) * pointsPerMsec + 1)) ':' num2str(round((str2double(inString(stops(1) + 1:stops2(1) - 1)) - firstTime) * pointsPerMsec + 1))];
    end

    for i = 2:length(starts)
        if stops2(i) == stops(i)
			if isnan(str2double(inString(starts(i) + 5:stops(i) - 1)))
				outString = [outString inString(stops2(i - 1):stops(i) - 1)];
			else
				outString = [outString inString(stops2(i - 1):starts(i) + 4) num2str(round((str2double(inString(starts(i) + 5:stops(i) - 1)) - firstTime) * pointsPerMsec + 1))];
			end
        else
            outString = [outString inString(stops2(i - 1):starts(i) + 4) num2str(round((str2double(inString(starts(i) + 5:stops(i) - 1)) - firstTime) * pointsPerMsec + 1)) ':' num2str(round((str2double(inString(stops(i) + 1:stops2(i) - 1)) - firstTime) * pointsPerMsec + 1))];     
        end
    end
    outString = [outString inString(stops2(end):end)];
else
    outString = inString;
end