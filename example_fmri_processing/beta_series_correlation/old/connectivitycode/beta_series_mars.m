function  beta_series_mars(SPM_loc, ROI_loc, Events,trimsd )
% beta_series(SPM_loc, ROI_loc, Events,trimsd )
%
% takes the beta series from one roi (the seed) and correlates it to
% all the voxels in the brain and saves the results as an image
% SPM_loc - a string that points to a single SPM mat file location
% results will be written in to the same location as the SPM mat file
%
% ROI_loc - a string that points to a single marsbar ROI mat file location
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

roi = maroi(ROI_loc);% make marbar roi object from mars ROI mat file
roiLabel = label(roi);% extract label from opject

% define path to estimation data (assume SPM.mat and beta's in same location
[pathstr,name,ext] = fileparts(SPM_loc);

maroi_file = fullfile(pathstr,['marsData_',roiLabel]); % file name for mars estimations

%%%%%%%%%%%%%%% estimate beta series for all events %%%%%%%%%%%%%%%%
if ~exist([maroi_file,'.mat'],'file'),
    marsD = mardo(SPM_loc);  % make mars design object from SPM.mat
    marsY = get_marsy(roi,marsD,'mean'); % gets data in ROIs from images
    marsData = estimate( marsD, marsY ); % estimate method - estimates GLM for SPM model
    xCon = get_contrasts(marsD); % get contrasts from design object (if they exist)
    marsData = set_contrasts(marsData, xCon ); % set contrasts into design object
    save(maroi_file,'marsData');
else
    load( maroi_file );
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi_betas = betas(marsData);  % get design betas

% load SPM mat file
load(SPM_loc);

%%%%%%%%%%%%match Event string to beta image discription %%%%%%%%%%

discription = {SPM.Vbeta.descrip}; % extract discription

% this block finds sets of index where discriptions match Events
for zz = 1:length(Events),
    idx{zz} = strfind(discription,Events{zz});
    idx{zz} = find(~cellfun('isempty',idx{zz})); %strip out non matching results
    Event_name = Events{zz};
    final_idx = idx{zz};
    P = {};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    sorted_betas = roi_betas(final_idx); % mean of ROI beta series for selected events
    beta_images = {SPM.Vbeta(final_idx).fname}; % name of beta_images for selected events

    % make array of location of beta images
    for n = 1:length(beta_images)
        P{n} = fullfile(pathstr,beta_images{n});
    end
    % get voxel values for select images
    vbetas = spm_get_data(P,SPM.xVol.XYZ);

    Cout = [];
    % for each voxel in beta images
    for n = 1:size(vbetas,2),
        if trimsd > 0,
            sorted_betas = trimts(sorted_betas, trimsd, []); vbetas(:,n) = trimts(vbetas(:,n), trimsd, []);
        end
        Cout(n)  = corr(sorted_betas,vbetas(:,n),'type','Pearson');
    end


    % output R correlation results to image
    %corr_file = fullfile(pathstr,['Rcorr_',roiLabel,Event_name,'.nii']);
    %writeCorrelationImage(Cout,corr_file, SPM.xVol);

    % output R_atanh correlation results to image
    corr_file = fullfile(pathstr,['Ratanh_corr_',roiLabel,Event_name,'.nii']);
    writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);

    % output Z correlation results to image
    %corr_file = fullfile(pathstr,['Zcorr_',roiLabel,Event_name,'.nii']);
    %writeCorrelationImage((atanh(Cout)*sqrt(length(sorted_betas)-3)),corr_file, SPM.xVol);
end
