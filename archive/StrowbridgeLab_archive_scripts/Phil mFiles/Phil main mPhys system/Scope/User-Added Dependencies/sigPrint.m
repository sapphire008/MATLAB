function outString = sigPrint(inVal, sigDigits, fieldSize)
% generate a string with the specified number of significant digits

if nargin < 2
    sigDigits = 4;
end

if nargin < 3
    fieldSize = 10;
end

if inVal == 0
    outString = sprintf(['%' sprintf('%0.0f', fieldSize) '.0f'], 0);
else
    outString = sprintf(['%' sprintf('%0.0f', fieldSize) '.' sprintf('%0.0f', max([0 sigDigits - log10(max([10^-sigDigits abs(inVal)]))])) 'f'], inVal);
end