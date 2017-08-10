function Out = nonEqualVectorOperation(X,Y, func, varargin)
% Apply a function to two vectors of not equal length. The returned result
% will have the legnth of shorter vector. Assume the beginning of the two
% vectors matches in time.
V_len = min(length(X), length(Y));
X = X(1:V_len);
Y = Y(1:V_len);
Out = func(X,Y, varargin{:});
end