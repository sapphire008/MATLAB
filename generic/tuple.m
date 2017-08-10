function varargout = tuple(varargin)
% allows simultaneous assignment
% [a,b,c] = tuple(x,y,z);
if nargin == nargout
    varargout = varargin;
elseif nargin==1
    for k = 1:nargout
        varargout{k} = varargin{1};
    end
else
    error('Unbalanced number of input and output arguments')
end
end

function varargout = tuple2(varargin)
% allows simultaneous assignment
% [a,b,c] = tuple(x,y,z);
varargout = varargin;
end