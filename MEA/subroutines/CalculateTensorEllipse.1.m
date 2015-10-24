function [X,Y] = calculateEllipse(S, x0y0, steps)
% This functions returns points to draw an ellipse
%
% S       tensor
% x0y0    XY center coordinate 
% step    resolution of X Y.
narginchk(2, 3);
if nargin<3, steps = 72; end
alpha = linspace(0, 2*pi, steps)';
% decompose to orthogonal axes of the ellipse
[V,D] = eig(S);
D = diag(sqrt(D));
theta = angle(complex(V(:,1),V(:,2)));
theta(theta<0) = theta(theta<0) + 2*pi;%correct to only positive angles
% major axis with smaller rotation
[theta, theta_IND] = min(theta);
a = D(theta_IND); 
b = D(setdiff(1:2,theta_IND));
% calcualte ellipse
X = x0y0(1) + (a * cos(alpha) * cos(theta) - b * sin(alpha) * sin(theta));
Y = x0y0(2) + (a * cos(alpha) * sin(theta) + b * sin(alpha) * cos(theta));
if nargout==1, X = [X Y]; end
end