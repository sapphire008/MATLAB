function outData = allPointsMax(inData, startms, stopms)

%This function takes a data set (inData) and the range to look at (startms,
%stopms in ms) and assumes the number of points/s is 10k and returns the 
%maximum voltage of the input data found in the histogram.

if size(inData, 1) < size(inData, 2)
    inData = inData';
end

 if (startms) == 0
     startms = 1;
 else
      startms = startms*10; 
 end
 
 if stopms == 0
     stopms = size(inData,1);
 else
     stopms = stopms*10;  
 end

[~, xout] = hist(inData(startms:stopms),floor(min(inData(startms:stopms))):0.1:ceil(max(inData(startms:stopms))));
[~, I] = max(hist(inData(startms:stopms),floor(min(inData(startms:stopms))):0.1:ceil(max(inData(startms:stopms)))));

outData = xout(I);