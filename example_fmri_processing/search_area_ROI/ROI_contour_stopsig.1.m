% addspm8;
% addpath /nfs/pkg64/contrib/matlabpackages/NIFTI/;
% addpath /nfs/jong_exp/midbrain_pilots/scripts/search_area_ROI/;
% addpath /home/cui/scripts/archive/;
% addpath(genpath('/home/cui/scripts/MATLAB_3D2XHTML/'));
spmT_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM/';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
save_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/ROI_peak_T_voxel/ROI_3D_mesh/';
ROI_ext = {'_TR2_SNleft.nii','_TR2_STNleft.nii'};
subjects = {'JY_052413_haldol','MM_051013_haldol',...
    'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
    'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP122_061213','MP123_061713','MP124_062113','MP125_072413'};

% specify contrast conditions to search for
target_con_name = 'StopInhibit+StopRespond-Go';
tolerate_names = 'StopInhibit+StopRespond-GO_ONLY';
% choose whether or not converting to html format
con2html = false;

for s = 1:length(subjects)
    clear SPM CON_IMG IMG_NAME spmT_loc;
    %Display subject being processed
    disp(subjects{s});
    %load SPM
    load(fullfile(spmT_dir,subjects{s},'SPM.mat'));
    %find the image of target condtrast
    [CON_IMG,IMG_NAME]=search_contrasts(SPM,target_con_name,tolerate_names);
    %find the location of the spmT file
    spmT_loc = fullfile(spmT_dir,subjects{s},CON_IMG);
    for r = 1:length(ROI_ext)
        clear ROI XYZ t_values V S;
        %find the path of ROI
        ROI = fullfile(ROI_dir, [subjects{s},ROI_ext{r}]);
        %find the coordinate of the ROI
        XYZ = roi_find_index_no_mat(ROI);
        %find t_values of each voxel in this ROI
        t_values = spm_get_data(spmT_loc,XYZ);
        %construct alpha shape
        [V,S] = alphavol(XYZ',2);
        % make the 3D object
        figure;
        trisurf(S.bnd,XYZ(1,:),XYZ(2,:),XYZ(3,:),t_values,'EdgeColor','none');
        axis equal;
        title(['t-value distribution over the surface of ',...
            subjects{s},ROI_ext{r}],'interpreter','none');
        xlabel('R (large) <-->L (small)');
        ylabel('P (small) <-->A (large)');
        zlabel('I (small) <-->S (large)');
        colorbar;
        caxis([-1,3]);
        % save the figure
        saveas(gcf, regexprep(fullfile(save_dir,[subjects{s},ROI_ext{r}]),'.nii','.fig'),'fig');
        % convert to html if chosen so
        if conv2html
            figure2xhtml(...
                regexprep(fullfile(save_dir,[subjects{s},ROI_ext{r}]),'.nii',''),...
                struct('interactive',true,'title',figure_list{n}));
        end
        
        close all;%clear the figure after saving
    end
end



%convex hull
%http://www.mathworks.com/products/matlab/examples.html?file=/products/demos/shipping/matlab/demoDelaunayTri.html#18

% coronal-->116:124 (Y) length 9
% axial-->96:102 (Z) length 7
% sagittal-->95:103 (X) length 9



% max_XYZ = max(XYZ');
% 
% [X,Y,Z] = meshgrid(1:max_XYZ(1),1:max_XYZ(2),1:max_XYZ(3));
% 
% IMG = zeros(max_XYZ);
% IND = sub2ind(size(IMG),XYZ(1,:),XYZ(2,:),XYZ(3,:));
% IMG(IND) = t_values;
% 
% xslice = 5;
% yslice = [];
% zslice = [];
% 
% % plot each slice
% slice(X,Y,Z,IMG,xslice,yslice,zslice);

%# Plot the scattered points:
% subplot(2,2,1);
% scatter3(interiorPoints(:,1),interiorPoints(:,2),interiorPoints(:,3),'.');
% axis equal;
% title('Interior points');
% 
% %# Plot the tetrahedral mesh:
% subplot(2,2,2);
% tetramesh(DT);
% axis equal;
% title('Tetrahedral mesh');

%# Plot the 3-D convex hull:
%subplot(2,2,3);
