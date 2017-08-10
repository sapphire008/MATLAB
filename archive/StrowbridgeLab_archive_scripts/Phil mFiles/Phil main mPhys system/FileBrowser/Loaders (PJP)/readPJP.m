function zData = readPJP(filename, infoOnly)

if nargin == 1
    [zData.protocol zData.traceData] = pjpload(filename, 0);
elseif isnumeric(infoOnly) && infoOnly == 1
    zData = pjpload(filename, 1);
else
    [zData.protocol zData.traceData] = pjpload(filename, infoOnly);
end