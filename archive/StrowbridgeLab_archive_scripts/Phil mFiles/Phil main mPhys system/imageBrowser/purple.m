function c = purple(m)
%PURPLE Shades of red to blue.
%   PURPLE(M) returns an M-by-3 matrix containing a "purple" colormap.
%   PURPLE, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%       colormap(purple)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

if nargin < 1, m = size(get(gcf,'colormap'),1); end
r = (0:m-1)'/max(m-1,1); 
c = [r zeros(m,1) 1-r];