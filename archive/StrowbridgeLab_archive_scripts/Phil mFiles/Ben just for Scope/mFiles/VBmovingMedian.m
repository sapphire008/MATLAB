function outArray = VBmovingMedian (inArray, windowSize)
if nargin==1 
    windowSize=5;
end
outArray=medfilt1(inArray,windowSize);