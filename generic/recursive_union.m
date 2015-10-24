function C = recursive_union(varargin)
% take union over multiple inputs of vectors
%   C = recursive_union(A,B,C,D,E,...)
%       or
% Given A = {vect1, vect2, vect3, vect4, ...}
%   C = recursive_union(A{:}) 
% Takes the union vect1 v vect2 v vect3 v vect 4 v ...
C = union(varargin{1},varargin{2});
if length(varargin)>2
    C = recursive_union(C,varargin{3:end});
end
end