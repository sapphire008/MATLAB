function [outMatrix coefficients] = normalizeMatrix(inMatrix, dim)
% normalize a matrix along a given dimension
% dim = 0 does a global normalization
% outMatrix = normalizeMatrix(inMatrix, dim);
% defaults:
%   dim = 2

if nargin < 2
    dim = 0;
end

matSize = size(inMatrix);

if dim == 0
    % global normalization
    dataMin = min(inMatrix);
    dataMax = max(inMatrix);
    for i = 2:numel(matSize)
        dataMin = min(dataMin);
        dataMax = max(dataMax);
    end
    if dataMax > dataMin
        outMatrix = (inMatrix - repmat(dataMin, matSize)) ./ (repmat(dataMax - dataMin, matSize));
    else
        outMatrix = 0.5 * ones(size(inMatrix));
    end
    coefficients = [dataMin dataMax - dataMin];
else
    switch dim
        case 1
        	outMatrix = (inMatrix - repmat(min(inMatrix, [], 2), 1, size(inMatrix, 2))) ./ repmat(range(inMatrix, 2), 1, size(inMatrix, 2));
            coefficients = [min(inMatrix, [], 2); range(inMatrix, 2)]';
        case 2
        	outMatrix = (inMatrix - repmat(min(inMatrix, [], 1), size(inMatrix, 1), 1)) ./ repmat(range(inMatrix, 1), size(inMatrix, 1), 1);
            coefficients = [min(inMatrix, [], 1); range(inMatrix, 1)]';
        otherwise
            newSize = ones(size(matSize));
            newSize(dim) = matSize(dim);
            outMatrix = (inMatrix - repmat(min(inMatrix, [], dim), newSize)) ./ repmat(max(inMatrix, [], dim) - min(inMatrix, [], dim), newSize);                
            coefficients = [min(inMatrix, [], dim); range(inMatrix, dim)]';
    end
end

outMatrix(isnan(outMatrix)) = .5;

function outData = range(inData, dim)
    outData = max(inData, [], dim) - min(inData, [], dim);