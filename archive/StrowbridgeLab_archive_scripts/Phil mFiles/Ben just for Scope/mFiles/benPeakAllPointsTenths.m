function retValue = benPeakAllPointsTenths(inData)
%  this function returns the integer value that represents the peak of the
%  all points histogram of the data array

retValue=nan;
inData=10.*inData;
arrayMax=round(max(inData));
arrayMin=round(min(inData));
histogram=zeros(1,(1+(arrayMax-arrayMin)));
for i=1:numel(inData)
    index=1+(round(inData(i))-arrayMin);
    histogram(index)=histogram(index)+1;
end
target=max(histogram);
for i=1:numel(histogram)
    if histogram(i)==target 
        retValue=((i-1)+arrayMin)/10;
        break
    end
end

end 