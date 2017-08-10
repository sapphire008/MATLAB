function minPoints = fcnMin(inData, number, type)
% finds the minima of the given input data
% second two arguements function like those of the find command

if nargin == 2
    type = 'first';
end

if ~ismember(type, {'first', 'last'})
    error('Third arguement to findZero must be one of {''first'', ''last''}')
end

inData = diff(inData);

if nargin > 1
    minPoints = find((inData(2:length(inData)) ./ inData(1:length(inData) -1) < 0 | inData(2:length(inData)) == 0) & inData(1:length(inData) - 1) < 0, number, type);
else
    minPoints = find((inData(2:length(inData)) ./ inData(1:length(inData) -1) < 0 | inData(2:length(inData)) == 0) & inData(1:length(inData) - 1) < 0);
end