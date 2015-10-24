function MEA_tensor_field(Sigma, XY, BACKGROUND)
% Plot MEA discrete tensor field. Each tensor at specified location will be
% represented as an ellipse
% 
% Sigma: 2x2xN tensor list
% XY: Nx2 coordinate list
%% Debug
%addpath('Z:\Documents\Edward\scripts\MEA\subroutines\');
%load('Z:\Data\Edward\Analysis\2014 September 30\worksheet_summary.mat');
%%
% Knowing that input Sigma is [s_rr,s_rc; s_cr, s_cc], converting into 
% [s_xx, s_xy; s_yx, s_yy]
Sigma = [Sigma(2,:,:);Sigma(1,:,:)];
Sigma = [Sigma(:,2,:),Sigma(:,1,:)];
% Convert XY from [row, col] to [X,Y]
XY = [XY(:,2),max(XY(:,1))+1-XY(:,1)];
if nargin>2 && ~isempty(BACKGROUND), imagesc(BACKGROUND); hold on; end
for n = 1:size(Sigma,3)
    % Calculate ellipse for each Sigma
    [X,Y] = CalculateTensorEllipse(squeeze(Sigma(:,:,n)),XY(n,:));
    % Plot the tensor on the map
    fill(X,Y,1);
    hold on;
end
% draw background
axis off tight square;
hold off;
title('tensor map');
end

function [X,Y] = CalculateTensorEllipse(S, x0y0, steps)
% This functions returns points to draw an ellipse based on a tensor
% 
% Inputs:
%       S: 2x2 tensor matrix
%       x0y0: 1x2 XY center coordinate 
%       step: resolution of X Y. Default 72.
%
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