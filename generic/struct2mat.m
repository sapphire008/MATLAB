function varargout = struct2mat(dim, S, varargin)
if ~isstruct(S), error('Must input structure'); end
for n = 1:length(varargin)
    varargout{n} = [];
    for m = 1:length(S)
        varargout{n} = cat(dim, varargout{n}, S(m).(varargin{n}));
    end
end
end