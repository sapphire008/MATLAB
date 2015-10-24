addpath('/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/code/connectivity_code/')
addspm5

subjects = {'epc05' 'epc11' 'epc22' 'epc26' 'epc30' 'epc31' 'epc41' 'epc64' 'epc70' 'epc73' 'epc80' 'epc94' 'epc98' 'epc100' 'epc109' 'epp05' 'epp39' 'epp51' 'epp62' 'epp70' 'epp131' 'epp145' 'epp153' 'epp158' 'epp172' 'epp179' 'epp217' };
% subjects = {'101' '102' '103'}
        
subject_dir = '/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/subjects/';
extension_dir = '/tw_2mm_smoothed/';
save_dir = '/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/Andrew_Analysis_121310/';
event = 'ProbeBX';

for n = 1:length(subjects);

    SPM_loc = [subject_dir subjects{n} extension_dir,'/SPM.mat'];
    data(n).subjects = subjects{n};
    data(n).event = event;
    data(n).beta_series = beta_series_roi_nomars(SPM_loc,'/nfs/u2/SZ_MAIN/new_recon/spm5_analysis/roi/For_Andrew_121310/rDLPFC_L_7Vox_Jong_xyz_bin_LEFT_646440.nii',{event,'bf(1)'},0);


end

eval(['save ', save_dir,event,'.mat ', 'data']);