function [ADJ_ONSETS,I] = adjust_time(ONSETS,TIME)
% adjust onsets to the nearest given TIME
%given that each row of X and Y are observations
%DIST = X'*X+Y'Y-2*X*Y'
% pair-wise distance
D = bsxfun(@plus,dot(ONSETS(:),ONSETS(:),2),dot(TIME(:),TIME(:),2)')-2*(ONSETS(:)*TIME(:)');
[~,I] = min(D,[],2);
I = I(:)';%row vector
TIME = TIME(:)';%row vector
ADJ_ONSETS = TIME(I);
end