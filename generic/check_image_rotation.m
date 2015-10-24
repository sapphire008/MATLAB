%yaw   = alpha, around z-axis
%pitch = beta,  around x-axis
%roll  = gamma, around y-axis

% V.before = ...
%  [1.0000         0         0    -107.5000;...
%          0    1.0000         0  -121.5000;...
%          0         0    1.0000  -94.5000;...
%          0         0         0    1.0000];   
% 
% V.after = ...
%     [1.3938    0.1146    0.2477 -186.6642;...
%     0.0561   -2.2817    0.3699  235.8400;...
%    -0.1193    0.2659    3.0679 -308.1905;...
%          0         0         0    1.0000];
% 
% 
% V.affine_mat = ...
%    [ 0.711111415562423   0.028617816961778  -0.060874255329916  -0.271054109766681;...
%    0.021660575321649  -0.431324356938137   0.050259673737034  -0.243670720544600;...
%    0.025778933288716   0.038493330804259   0.319236551497780  -0.380580393711995;...
%                    0                   0        sym('R.pitch = [1 0 0; 0 cosd(pitch) -sin(pitch); 0 sin(pitch) cos(pitch)]');           0   1.000000000000000];

% Forward: from specification to affine transformation matrix
               
%V.affine_mat*V.before = V.after;
%V.affine = V.after * inv(V.before);
%translations
T.x = 0.5;
T.y = -0.4;
T.z = 1.2;
%angles
pitch = 0.12;
roll = 0.08;
yaw = -0.05;
%stretch factors
U.resize.x = 1.4;
U.resize.y = -2.3;
U.resize.z = 3.1;
R.pitch = [1 0 0; 0 cos(pitch) -sin(pitch); 0 sin(pitch) cos(pitch)]);
R.roll  = [cos(roll) 0 sin(roll); 0 1 0; -sin(roll) 0 cos(roll)]; 
R.yaw   = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
R.mat = R.yaw * R.pitch * R.roll;
%final
Affine.trans = vertcat(horzcat(R.mat*U.resize.mat,[T.x;T.y;T.z]),[0 0 0 1]);

