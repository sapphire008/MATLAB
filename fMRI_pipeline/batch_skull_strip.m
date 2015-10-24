addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/fMRI_pipeline/');
base_dir ='/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR3/';
source_file = 'resample_*TR3.nii';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR3/skull_stripped/';

files = dir(fullfile(base_dir, source_file));
files = {files(3:end).name};
files = cellfun(@(x) fullfile(base_dir,x),files,'un',0);
for n = 24:length(files)
    FSL_Bet_skull_stripping(files{n},save_dir,true,[],'bin_mask',true);
end
