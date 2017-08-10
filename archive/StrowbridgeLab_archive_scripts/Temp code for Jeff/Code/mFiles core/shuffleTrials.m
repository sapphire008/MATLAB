function newArray1 = shuffleTrials(array1)
    % revised 5 Jan 2015 BWS for poly3
    % changed to operate on one egg at a time
    newArray1 = array1;
    for column = 1:size(array1, 2)
        newArray1(randperm(size(array1, 1)),column) = array1(1:size(array1,1),column);
    end
end