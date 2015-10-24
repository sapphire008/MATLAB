function [XY_NN,IND,Nth] = find_nearest_neighbor(MAP, XY, NN, badelectrodes)
% Given a map of coordinates, find up to NNth nearest neighbors of 
% specified coordinate XY
% Inputs:
%   MAP and XY: coordinates of points, where each row is a point, and each
%               column is a dimension
%   NN: up to NNth neighbor to find
%   badelectrodes: list of bad electrodes to exclude from searching
% 
% Outputs:
%   XY_NN: coordinates of up to NNth nearest neighbor found within MAP
%   IND: index of nearest neighbors, so that MAP(IND,:) = XY_NN
%   Nth: current point is the Nth nearest neighbor to XY on MAP.

if nargin<4, badelectrodes = []; end
% Eliminate XY itself from MAP
badelectrodes = [badelectrodes;XY];
[~,IA,~] = intersect(MAP,badelectrodes,'rows','stable');
% find pairwise distance
D_mat = sqrt(bsxfun(@plus, dot(MAP,MAP,2), dot(XY,XY,2)')-2*(MAP*XY'));
[~,~,ID] = unique(D_mat);
% find up to NNth nearest neighbor
IND = setdiff(find(ID<=(NN+1)), IA, 'stable');
XY_NN = MAP(setdiff(IND,IA,'stable'),:);
Nth = ID(IND)-1;
end