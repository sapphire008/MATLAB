function [LOC, DIST] = PointLocation(P,AREA)
% Find where the point is relative to the search area
% Inputs:
%       P: N x 1 column vector that specifies the coordainte of a
%          point in R^N space
%       Area: N x M matrix that defines the search area point by
%             point. Each column defines one point.
%
% Outputs:
%       LOC: location of the point P with respect to AREA in R^N space.
%              'within': within the search area
%              'surface': on the surface/border of the search area
%              'corner': on the corner of the search area
%              'outside': outside of the search area
%       DIST: distance of the point from the centroid of the search area

if nargout>1
    % find the distance between the point and the centroid of search area
    DIST = sqrt(nansum((nanmean(AREA,2)-P).^2));
end

% find where the point is relative to the search area
if isempty(intersect(P',AREA','rows'))
    LOC = 'outside';%outside of the search area
    return;
end

%find the border points of the search AREA
surface_IND = [];%within the search area at least in 1 dimension
corner_IND = [];%on the corner of all dimensions of the search area
for M = 1:size(AREA,2)
    clear tmp border_vect;
    tmp = AREA(:,M);
    border_vect = false(1,length(tmp));
    for N = 1:length(tmp)
        tmp2 = tmp + [zeros(N-1,1);1;zeros(length(tmp)-N,1)];
        tmp3 = tmp - [zeros(N-1,1);1;zeros(length(tmp)-N,1)];
        border_vect(N) = isempty(intersect(tmp2',AREA','rows')) | ...
            isempty(intersect(tmp3',AREA','rows'));
    end
    if all(border_vect)%border at all dimensions -->corner
        corner_IND(end+1) = M;
    elseif any(border_vect)% border at some dimensions -->surface
        surface_IND(end+1) = M;
    else
        continue;
    end
end

%see if the point belongs to one of the surface/corner points
if ~isempty(intersect(P',AREA(:,surface_IND)','rows'))
    LOC = 'surface';%at the surface, but not corner
elseif ~isempty(intersect(P',AREA(:,corner_IND)','rows'))
    LOC = 'corner';%at the corner
else
    LOC = 'within';%within search area
end
end