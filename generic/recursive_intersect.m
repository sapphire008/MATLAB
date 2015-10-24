function C = recursive_intersect(varargin)
% take intersection over multiple inputs of vectors
%   C = recursive_intersect(A,B,C,D,E,...)
%       or
% Given A = {vect1, vect2, vect3, vect4, ...}
%   C = recursive_intersect(A{:}) 
% Takes the intersection vect1 ^ vect2 ^ vect3 ^ vect 4 ^ ...
C = intersect(varargin{1},varargin{2});
if length(varargin)>2
    C = recursive_intersect(C,varargin{3:end});
end
end