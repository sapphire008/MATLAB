function  beta_series_correlation_mars(SPM_loc, ROI_loc, Events,trimsd)
% beta_series(SPM_loc, ROI_loc, Events,trimsd )
%
% takes the beta series from one roi (the seed) and correlates it to
% all the voxels in the brain and saves the results as an image
% SPM_loc - a string that points to a single SPM mat file location
% results will be written in to the same location as the SPM mat file
%
% ROI_loc - a string that points to a single nifti format ROI file location
%
% Events - A cell array of strings that will be used to identify the Events in the beta series
% This allows for a multipass string isolation
% For example Events = {'GreenProbe_Correct', 'Sn(1)','bf(1)'}
% First locate the set of events that match 'GreenProbe_Correct',
% Second locate the set of events that match Sn(1)
% Third locate the set of events that match bf(1)
% The final set of event will be the those in the intersection of the
% three sets
% Events can be a single string
%
% trimsd is the is number of standard deviations to use if
% you wish the raw data to be Windsorized
% set to 0 if you wish the raw data to be used

if ~exist('trimsd','var'), trimsd = 0; end
if ~iscell(Events), Events = {Events}; end

% define path to estimation data (assume SPM.mat and beta's in same location
[pathstr,name,ext] = fileparts(SPM_loc);

% load SPM mat file
load(SPM_loc);

% locate beta_images related to Event
P = location_of_beta_images_from_event_discription(Events,SPM);

% get ROI
Vroi = spm_vol(ROI_loc);
roi = spm_get_data(Vroi,SPM.xVol.XYZ);
%roi = spm_read_vols(Vroi);
%old_size = size(roi);
roi = roi(:); % convert roi to vector
idx = find(roi);

% get beta values
V = spm_vol(P);
for n = 1:length(V)
    foo = spm_get_data(V{n},SPM.xVol.XYZ);
    vbetas(n,:) = foo(:);
    mean_roi(n) = mean(foo(idx));% extract mean of ROI from each beta
    clear foo
end

% for each voxel in beta images
for k = 1:size(vbetas,1),
    for n = 1:size(vbetas,2),
        Cout(n)  = corr(mean_roi',vbetas(:,n),'type','Pearson');
    end
end


[foo,roiLabel,ext] = fileparts(ROI_loc);
% output R correlation results to image
corr_file = fullfile([pathstr,'/'],['Rcorr_',roiLabel,Event{1},'.nii']);
writeCorrelationImage(Cout,corr_file, SPM.xVol);

% output R correlation results to image
corr_file = fullfile([pathstr,'/'],['R_atanh_corr_',roiLabel,Event{1},'.nii']);
writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);

% output Z correlation results to image
corr_file = fullfile([pathstr,'/'],['Zcorr_',roiLabel,Event{1},'.nii']);
writeCorrelationImage((atanh(Cout)*sqrt(length(sorted_betas)-3)),corr_file, SPM.xVol);
