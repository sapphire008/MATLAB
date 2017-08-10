function timeAsString = getTimeAsString(timeAsSec)
  % hello
 if timeAsSec < 60
     timeAsString = [sprintf('%.1f', timeAsSec) 'sec'];
 else
     hours = fix(timeAsSec / (60 * 60));
     tempTime = timeAsSec - (hours * (60 * 60));
     mins = fix(timeAsSec / 60);
     secs = round(tempTime - (mins * 60));
     finalSec = num2str(100 + secs);
     if hours > 0
        timeAsString = [num2str(hours) ':'];
     else
        timeAsString = '';
     end
     timeAsString = [timeAsString num2str(mins) ':' finalSec(2:3)];
 end
end