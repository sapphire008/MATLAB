% batch change figure view
clear; clc; close all;
figure_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/ROI_peak_T_voxel/ROI_3D_mesh/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/ROI_peak_T_voxel/ROI_3D_screenshots/';

%AZ = 36.50; EL=26
%AZ = -36.50;EL=26;
AZ=167.50;EL=26;
% get a list of figures to adjust in the current folder
F = dir(fullfile(figure_dir,'*.fig'));
F = {F.name};
F = F(~strcmpi(F,'.') & ~strcmpi(F,'..'));
F = F(~cellfun(@isempty,regexp(F,'bilateral')));
F = cellfun(@(x) fullfile(figure_dir,x),F,'un',0);

for f = 1:length(F)
    open(F{f});
    view(AZ,EL);
    xlabel('Right-->Left');
    set(get(gca,'xlabel'),'rotation',5);
    ylabel('Posterior-->Anterior');
    set(get(gca,'ylabel'),'rotation',-60);
    zlabel('Inferior-->Superior');
    set(gcf,'Position',[100,100,1400,857]);
    % figure name
    [~,NAME,~] = fileparts(F{f});
    saveas(gcf,fullfile(save_dir,[NAME,'.tif']),'tiff');
    close(gcf);
end
