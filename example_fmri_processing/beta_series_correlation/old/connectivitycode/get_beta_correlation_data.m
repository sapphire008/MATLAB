addpath('/nfs/uhr08/code/connectivitycode/')
addspm5

subjects = {'epc05', 'epc11', 'epc22', 'epc26', 'epc30', 'epc31', 'epc41', 'epc64', 'epc70', 'epc73', 'epc80', 'epc94', 'epc98', 'epc100', 'epc109', 'epp05', 'epp39', 'epp51', 'epp62', 'epp70', 'epp131', 'epp145', 'epp153', 'epp158', 'epp172', 'epp179', 'epp217'};
% subjects = {'101' '102' '103'}
        
subject_dir = '/nfs/sn/connectivity_analysis/';
extension_dir = '/SPM.mat';
save_dir = '/nfs/sn/beta_correlations_results/R_Inf_Front/ProbeA/';
event = 'CorrectProbe'

for n = 1:length(subjects);

    SPM_loc = [subject_dir subjects{n} extension_dir];
    data(n).subjects = subjects{n};
    data(n).event = event;
    data(n).beta_series = beta_series_roi_nomars(SPM_loc,'/nfs/sn/ROIs/C-SZ_CorrectProbe_Inferior_Frontal.nii',{event,'bf(1)'},0);


end

eval(['save ', save_dir,event,'.mat ', 'data']);