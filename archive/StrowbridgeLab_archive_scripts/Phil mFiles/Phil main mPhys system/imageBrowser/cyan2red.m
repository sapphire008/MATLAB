function c = cyan2red(m)
%CYAN2RED Shades of cyan to red.
%   CYAN2RED(M) returns an M-by-3 matrix containing a "cyan2red" colormap.
%   CYAN2RED, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%       colormap(cyan2red)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

if nargin < 1, m = size(get(gcf,'colormap'),1); end
r = (0:m-1)'/max(m-1,1); 
c = [r 1-r 1-r];