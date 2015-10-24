function [XY_NN,IND, Nth] = find_nearest_neighbor(MAP, XY, NN)
% Given a map of coordinates, find up to NNth nearest neighbors of 
% specified coordinate XY
% Inputs:
%   MAP and XY: coordinates of points, where each row is a point, and each
%               column is a dimension
%   NN: up to NNth neighbor to find
% 
% Outputs:
%   XY_NN: coordinates of up to NNth nearest neighbor found within MAP
%   IND: index of nearest neighbors, so that MAP(IND,:) = XY_NN
%   Nth: current point is the Nth nearest neighbor to XY on MAP.

% Eliminate XY itself from MAP
[~,IA,~] = intersect(MAP,XY,'rows','stable');
MAP = setdiff(MAP,XY,'rows','stable');
% find pairwise distance
D_mat = sqrt(bsxfun(@plus, dot(MAP,MAP,2), dot(XY,XY,2)')-2*(MAP*XY'));
[~,~,ID] = unique(D_mat);
% find up to NNth nearest neighbor
IND = find(ID<=NN);
XY_NN = MAP(IND,:);
Nth = ID(IND);
if ~isempty(IA),IND = IND + 1*(IND>=IA);end
end