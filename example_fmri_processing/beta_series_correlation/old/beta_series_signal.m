function  beta_series_signal(SPM_loc, ROI_loc, Events)
% beta_series(SPM_loc, ROI_loc, Events,trimsd )
%
% extract an ROI from a subjects beta images
% and high pass filters the series and normalises to the first 
% data point
%
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

if ~iscell(Events), Events = {Events}; end

% define path to estimation data (assume SPM.mat and beta's in same location
[pathstr,name,ext] = fileparts(SPM_loc);

% load SPM mat file
load(SPM_loc);

% locate beta_images related to Event
P = location_of_beta_images_from_event_discription(Events,SPM);
% get beta values (in Vector form) 
vbetas = spm_get_data(P,SPM.xVol.XYZ);
% get ROI
roi = spm_get_data(ROI_loc,SPM.xVol.XYZ);
idx = find(roi);
% extract mean of ROI from each beta
for n = 1:size(vbetas,1)
    mean_roi(n) = mean(vbetas(n,idx));
end
























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
