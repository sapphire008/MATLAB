function c = redSat(m)
%REDSAT Shades of Black aNd White color map that saturates at red.
%   REDSAT(M) returns an M-by-3 matrix containing a "redsat" colormap.
%   REDSAT, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%       colormap(redsat)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

if nargin < 1, m = size(get(gcf,'colormap'),1); end
r = (0:m-2)'/max(m-1,1); 
c = [[r; 1] [r; 0] [r; 0]];