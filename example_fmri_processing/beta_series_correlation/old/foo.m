ROI_loc = {'/nfs/modafinil/Con/SPM5_IRF_Analysis_May08/withingroup/MCn18/ROIs/anatomical_ROI+DMN/miniMEGAmask_(bACC+bPCC)/p0005/MCn18_IRF_DMN&bACC_p0005.nii'...
 '/nfs/modafinil/Con/SPM5_IRF_Analysis_May08/withingroup/MCn18/ROIs/anatomical_ROI+DMN/miniMEGAmask_(bACC+bPCC)/p0005/MCn18_IRF_DMN&bPCC_p0005.nii' ...
 '/nfs/modafinil/Con/SPM5_IRF_Analysis_May08/withingroup/MCn18/ROIs/anatomical_ROI+DMN/miniMEGAmask_(bACC+bPCC)/p0005/MCn18_IRF_DMN&IPL_L_p0005.nii'};

SPM_loc = '/nfs/modafinil/Con/MC01/SPM5_IRF_BetaSeries_Aug08/SPM.mat';


Events = {{'Placebo_Checkerboard' 'bf(1)'} {'Drug_Checkerboard' 'bf(1)'}};

trimsd = 2;

results = beta_series_correlation_multi_roi(SPM_loc, ROI_loc, Events,trimsd)
