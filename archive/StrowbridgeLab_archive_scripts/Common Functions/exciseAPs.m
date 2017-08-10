function [cleanTrace APendTimes APthreshList] = exciseAPs(inTrace, APtimes, lagPoints, PointsPerMs)
  % revised 19 April 2012 BWS
  cleanTrace = inTrace;
  APendTimes = [];
  APthreshList = [];
  for AP = 1:numel(APtimes)
      APstart = (PointsPerMs * APtimes(AP)) + lagPoints;
      IndexSet = fix(APstart + (-1:1)');
      APthresh = mean(inTrace(IndexSet));
      if APstart < (numel(inTrace) - 100)
         i = fix(APstart + 5);
         while (inTrace(i) > APthresh) && (i < numel(inTrace))
           i = i + 1;
         end 
         for j = fix(APstart):i
            cleanTrace(j) = APthresh; 
         end
         APendTimes = [APendTimes ((1/PointsPerMs) * i)];
         APthreshList = [APthreshList APthresh];
      end
  end
end