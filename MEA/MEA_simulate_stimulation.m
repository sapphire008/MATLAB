function U = MEA_simulate_stimulation(Sigma,J,PITCH, XY_NN, Psi)
% Simulate single electrode stimulation. Used to test conductivity tensor
% calculation.

%if nargin<4 || isempty(make_plot), make_plot = true; end
%% Parameter Definition
if nargin<1
    PITCH = 0.2;              % pitch in mm
    J = [-5:5];                % in uA
    XY_NN = [1,0;0,1;-1,0;0,-1;1,1;-1,1;-1,-1;1,-1];
    
    %
    sxx = 0.35;           % in mS/(mm^2)
    syy = 0.28;           % in mS/(mm^2)
    sxy = 0.08;           % in mS/(mm^2)
    
    Sigma = [sxx sxy;...
        sxy syy];
    
    Psi = [0, 0.10]; % Gaussian noise level [mean, std]
    
    cellfun(@assignin, repmat({'caller'},1,8),...
        {'PITCH','J','XY_NN','sxx','syy','sxy','Sigma','Psi'}, ...
        {PITCH, J, XY_NN, sxx, syy, sxy, Sigma, Psi});
end

%% Computing W and its inverse

[L,D] = eig(Sigma);

W = L*diag(1./sqrt(diag(D)));

tW = W.';
%% Generate nearest neighbor
%XY_NN = generate_nearest_neighbor_coord(NN);

%% This result should be the identity matrix
% 
% W'*S*W

%% Computing potential at neighbor electrodes

V = @(x,y,A) J/(4*pi)*1./sqrt( (A(1,1)*x+A(1,2)*y).^2 + (A(2,1)*x+A(2,2)*y).^2 );

%% Voltage
XY_NN = XY_NN*PITCH;
U = zeros(size(XY_NN,1), numel(J));
for n = 1:size(XY_NN,1)
    U(n,:) = V(XY_NN(n,1),XY_NN(n,2),tW);
end

% Add noise
U = U + randn(size(U))*Psi(2) + Psi(1);

if nargout<1
    assignin('caller','U',U);
end

% if make_plot
%     u = -0.5:0.01:0.5;
%     %u(abs(u)<0.01) = [];
%     [x,y] = meshgrid(u);
%     
%     % figure
%     % surf(x,y,V(x,y,tW))
%     % xlabel('X')
%     % ylabel('Y')
%     
%     V = @(x,y,A) J(1)/(4*pi)*1./sqrt( (A(1,1)*x+A(1,2)*y).^2 + (A(2,1)*x+A(2,2)*y).^2 );
%
%     figure
%     imagesc(u,u',V(x,y,tW))
%     hold on
%     plot(PITCH,0,'wo')
%     plot(0,PITCH,'wo')
%     plot(-PITCH,0,'wo')
%     plot(0,-PITCH,'wo')
%     plot(PITCH,PITCH,'w+')
%     plot(-PITCH,PITCH,'w+')
%     plot(-PITCH,-PITCH,'w+')
%     plot(PITCH,-PITCH,'w+')
%     xlabel('X')
%     ylabel('Y')
%     colorbar
%     axis xy
%     axis equal
%     axis tight
% end
end