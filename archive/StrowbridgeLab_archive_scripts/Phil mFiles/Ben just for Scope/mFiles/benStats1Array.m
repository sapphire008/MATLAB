function [mean1, sem1, pValue]=benStats1Array(inArray1, testValue)
    mean1=mean(inArray1);
    sem1=std(inArray1)/nthroot(numel(inArray1),2);
    [junk pValue]=ttest(inArray1,testValue);
end