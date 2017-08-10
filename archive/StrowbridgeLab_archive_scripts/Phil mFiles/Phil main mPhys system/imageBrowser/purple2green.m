function c = purple2green(m)
%PURPLE2GREEN Shades of green to blue.
%   PURPLE2GREEN(M) returns an M-by-3 matrix containing a "purple2green" colormap.
%   PURPLE2GREEN, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%       colormap(purple2green)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

if nargin < 1, m = size(get(gcf,'colormap'),1); end
r = (0:m-1)'/max(m-1,1); 
c = [1-r r 1-r];