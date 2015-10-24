function  results = beta_series_correlation_multi_roi(SPM_loc, ROI_loc, Events,trimsd)
% results = beta_series_multi_roi(SPM_loc, ROI_loc, Events,trimsd)
%
% Takes multiple roi for multiple beta series and
% returns the correlation
%
% SPM_loc - a string that points to a single SPM mat file location
% SPM_loc = '/nfs/modafinil/Con/MC01/SPM5_Analysis_April08/SPM.mat'
%
% ROI_loc - cell array of strings that points to a several nifti format ROI
% file locations
% ROI_loc = {'/nfs/modafinil/Con/SPM5_IRF_Analysis_May08/withingroup/MCn18/ROIs/anatomical_ROI+DMN/miniMEGAmask_(bACC+bPCC)/p0005/MCn18_IRF_DMN&bACC_p0005.nii'...
% '/nfs/modafinil/Con/SPM5_IRF_Analysis_May08/withingroup/MCn18/ROIs/anatomical_ROI+DMN/miniMEGAmask_(bACC+bPCC)/p0005/MCn18_IRF_DMN&bPCC_p0005.nii'...
% '/nfs/modafinil/Con/SPM5_IRF_Analysis_May08/withingroup/MCn18/ROIs/anatomical_ROI+DMN/miniMEGAmask_(bACC+bPCC)/p0005/MCn18_IRF_DMN&IPL_L_p0005.nii'}
%
% Events - A cell array of a cell of strings - used to identify the Events in the beta series
% Events = {{'GreenCue_Correct' 'bf(1)'} {'RedCue_Correct' 'bf(1)'}}
%
% trimsd is the is number of standard deviations to use if
% you wish the raw data to be Windsorized
% set to 0 if you wish the raw data to be used

if ~exist('trimsd','var'), trimsd = 0; end
if ~iscell(Events), Events = {Events}; end

% load SPM mat file
load(SPM_loc);


for n = 1:length(Events)
    % locate beta_images related to Event
    P = location_of_beta_images_from_event_discription(Events{n},SPM);
    % get beta values (in Vector form)
    vbetas = spm_get_data(P,SPM.xVol.XYZ);
    results{n}.Event = Events{n};
    % apply each of the ROIs to the beta time series (for current Event)
    % trim results if needed
    for k = 1:length(ROI_loc)
        % get ROI
        roi = spm_get_data(ROI_loc{k},SPM.xVol.XYZ);
        idx = find(roi);
        % extract mean of ROI from each beta
        for j = 1:size(vbetas,1)
            mean_roi{k}(j) = mean(vbetas(j,idx));
        end
        % trim results if > 0
        if trimsd > 0,
            mean_roi{k} = windsor(mean_roi{k}, trimsd);
        end 
    end
    results{n}.n = length(mean_roi{1});
    if size(ROI_loc,2) == 2
        [foo, name1] = fileparts(ROI_loc{1});
        [foo, name2] = fileparts(ROI_loc{2});
        results{n}.ROI{1} = [name1,'__',name2];
        results{n}.corr{1} = corr(mean_roi{1}(:),mean_roi{2}(:));
    else
        count = 1;
        for k = 1:size(ROI_loc,2)-1
            for j = k+1:size(ROI_loc,2)
                results{n}.corr{count} = corr(mean_roi{k}(:),mean_roi{j}(:));
                [foo, name1] = fileparts(ROI_loc{k});
                [foo, name2] = fileparts(ROI_loc{j});
                results{n}.ROI{count} = [name1,'__',name2];
                %disp([num2str(k),'  ',num2str(j)])
                %disp([results{n}.Event{1},' ', results{n}.ROI{count},' ',num2str(results{n}.corr(count)) ])
                count = count + 1;
            end
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function P = location_of_beta_images_from_event_discription(Events,SPM)
% P = location_of_beta_images_from_event_discription(Events,SPM)
% Events = Cell Array of Strings that defines a unique set of beta images
% SPM data structure

discription = {SPM.Vbeta.descrip}; % extract discription

% this block finds sets of index where discriptions match Events
Event_name = '';
for n = 1:length(Events),
    idx{n} = strfind(discription,Events{n});
    idx{n} = find(~cellfun('isempty',idx{n})); %strip out non matching results
    Event_name = [Event_name,'_',Events{n}];
end

% this block find the intersection of all sets of index
ref_idx = idx{1};
for n = 2:length(idx),
    reduced_idx{n-1} = intersect(idx{n},ref_idx);
end
final_idx = [];
for n = 1:length(reduced_idx),
    final_idx = union(reduced_idx{n},final_idx);
end

beta_images = {SPM.Vbeta(final_idx).fname}; % name of beta_images for selected events

% make array of location of beta images
for n = 1:length(beta_images)
    P{n} = fullfile(SPM.swd,beta_images{n});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function x = windsor(x,sd)

% remove the mean from X
me = mean(x);
x = x - me;

% replace the outliers
idx = find(abs(x) > sd * std(x));

x(idx) = sign(x(idx)) * sd * std(x);

x = x + me;




