function outTime = randSpread(centerTime, numTTL, timingGap)
if nargin
    % generate times
    if timingGap ~= 0
        setappdata(0, 'randSpread', (-(numTTL - 1) / 2 * timingGap:timingGap:numTTL / 2 * timingGap) + centerTime);
    else
        setappdata(0, 'randSpread', centerTime * ones(numTTL, 1));
    end
end

% choose a random time
allTimes = getappdata(0, 'randSpread');
whichTime = fix(rand * numel(allTimes) + 1);
outTime = allTimes(whichTime);
setappdata(0, 'randSpread', allTimes([1:whichTime - 1 whichTime + 1:end]));