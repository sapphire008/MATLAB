
function R = ndim_rotation_matrix(x, y, sanity_check)

% Implemented based on MATLAB code from
% https://math.stackexchange.com/questions/598750/finding-the-rotation-matrix-in-n-dimensions

% x, y are n-dimensional column vectors

% u = x / |x|
% v = y - (u'*y).*u
% v = v / |v|

% cos(theta) = x' * y / (|x| |y|)
% sin(theta) = sqrt(1-cos(theta)^2)

% R = I - u*u' - v*v' + [u, v] R_theta [u, v]'

% Sanity check:

% R * R' = I
% R * x  = y'
% or
% x' * R' = y

% Exmample
% x=[2,4,5,3,6]';
% y=[6,2,0,1,7]';

if nargin<3, sanity_check = false; end

u=x/norm(x);

v=y-u'*y*u;

v=v/norm(v);

cost=x'*y/norm(x)/norm(y);

sint=sqrt(1-cost^2);

R = eye(length(x))-u*u'-v*v' + [u v]* [cost -sint;sint cost] *[u v]';


% Sanity check
if sanity_check
  fprintf('testing\n');

  should_be_identity = R*R'

  should_be_y = R*x
end

end
