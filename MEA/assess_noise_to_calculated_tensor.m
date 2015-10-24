% assess noise to calculated tensor
addpath('Z:\Documents\Edward\scripts\MEA\');
addpath('Z:\Documents\Edward\scripts\BiomeCardio\');

Sigma = [0.35, 0.08; 0.08, 0.28];
XY_NN = [1,0;0,1;-1,0;0,-1;1,1;-1,1;-1,-1;1,-1];
PITCH = 0.2;
J = -5:5;

%% Assess different levels of noise
Psi = 0:0.001:1;
Psi = [zeros(length(Psi),1),Psi(:)];

% D = zeros(size(Psi,1),100);
% F = zeros(size(Psi, 1),100);
h = waitbar(0,'Calculating tensor robustness ...');
parpool(3)
try
for n = 93:size(Psi,1)
    waitbar(n/size(Psi,1));
    parfor m = 1:100 % randomly generate this 100 times
        % simulate U
        U = MEA_simulate_stimulation(Sigma,J,PITCH, XY_NN, Psi(n,:));
        % calculate tensor
        [Sigma2, W2, DIAGNOSTICS, SUMMARY] = MEA_compute_conductivity_tensor(U,J,0.2,[0,0],XY_NN, 'diagnostics',false);
        % calculate distance
        K = std(Sigma2,1,3);
        Sigma2 = median(Sigma2,3);
        D(n,m) = norm(Sigma - Sigma2);
        F(n,m) = mean(K(:));
        %D(3,n) = SUMMARY.fvals;
    end
end
catch
    save('Z:\Data\Edward\Analysis\2014 September 12\test_robust_10102014.mat');
end
close(h);
save('Z:\Data\Edward\Analysis\2014 September 12\robustedness_tensor_by_W_with_linearization.mat','D','Psi');

% plot
% figure;
% plot(Psi(:,2),log10(D(1,:)));
% hold on;
% plot(Psi(:,2),smoothn(log10(D(1,:))),'r--');
% saveas(gcf,'Z:\Data\Edward\Analysis\2014 September 12\Simulation_verify_tensor_computation_with_S.fig');

% %% Assess tolerance affect convergence
% Psi = [0, 0.5];
% %D = zeros(2,100);
% for n = 1:100
%     U = MEA_simulate_stimulation(Sigma,J,PITCH, XY_NN, Psi);
%     [Sigma2, W2, DIAGNOSTICS, SUMMARY] = MEA_compute_conductivity_tensor2(U,J,0.2,[0,0],XY_NN, 'diagnostics',false);
%     % calculate distance
%     K = std(Sigma2,1,3);
%     Sigma2 = median(Sigma2,3);
%     D(3,n) = norm(Sigma - Sigma2);
%     %D(2,n) = SUMMARY.fvals;
%     D(4,n) = mean(K(:));
% end