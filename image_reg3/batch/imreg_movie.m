%play movie for 
data_struct = load('/nfs/r21_gaba/subjects/VP544_060811/movement_badmovedata/run1_v1_analysis_09-Jun-2011/short_workspace.mat');
datamat= [translational.displacement.x',translational.displacement.y'];
for n = 1: size(datamat,1)
    plot(datamat(n,1),datamat(n,2),'.');
    hold on;
    M(n) = getframe(gcf);
end

movie(M);
    