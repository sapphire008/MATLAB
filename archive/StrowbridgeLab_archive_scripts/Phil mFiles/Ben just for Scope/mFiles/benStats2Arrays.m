function [mean1, sem1, mean2, sem2, pValue]=benStats2Arrays(inArray1, inArray2)
    mean1=mean(inArray1);
    sem1=std(inArray1)/nthroot(numel(inArray1),2);
    mean2=mean(inArray2);
    sem2=std(inArray2)/nthroot(numel(inArray2),2);
    [junk pValue]=ttest2(inArray1,inArray2);
end
    

    