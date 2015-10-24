addpath('/nfs/pkg64/contrib/nifti/');
base_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/primary_auditory_cortex_func_ROIs/';
ROI_list = dir(fullfile(base_dir,'*.img'));
ROI_list = {ROI_list.name};

for r = 1:length(ROI_list)
    disp(ROI_list{r});
    clear tmp;
    tmp = load_nii(fullfile(base_dir,ROI_list{r}));
    if length(unique(tmp.img)) ~= 2
        disp([ROI_list{r},' is not binary']);
    end
end

