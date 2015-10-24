addspm8;
addpath /nfs/pkg64/contrib/nifti/;
addpath /nfs/jong_exp/midbrain_pilots/scripts/search_area_ROI/;
addpath /home/cui/scripts/archive/;

spmT_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/GLM/';
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
target_con_name = 'Cue_gain5+Cue_gain1-Cue_gain0';
tolerate_names = 'Cue_gain0.2';


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
        %find peak voxel
        [peak_t,IND] = max(t_values);
        peakXYZ = XYZ(:,IND);
        
    end
end