function zData = readABF(filename, infoOnly, varargin)

if nargin == 1
    [zData.protocol zData.traceData] = abfload(filename, varargin{:});
elseif isnumeric(infoOnly)
    zData = abfload(filename, varargin{:});
else
    [zData.protocol zData.traceData] = abfload(filename, infoOnly, varargin{:});
end