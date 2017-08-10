function varargout = tupleapply(func, inputs, varargin)
% [a,b,c] = tuple(func, {x,y,z}, ...);
if ischar(func)
    func = str2func(func);
end
for k = 1:length(inputs)
    varargout{k} = func(inputs{k}, varargin{:});
end
end