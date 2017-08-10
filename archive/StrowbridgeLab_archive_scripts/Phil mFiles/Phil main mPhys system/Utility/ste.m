function errVal = ste(inData, dim)

if isvector(inData)
    errVal = std(inData) / sqrt(numel(inData)-1);
elseif nargin > 1
    errVal = std(inData, 0, dim) ./ sqrt(sum(~isnan(inData),dim) - 1);
else
    errVal = std(inData, 0, 1) ./ sqrt(sum(~isnan(inData),1) - 1);
end