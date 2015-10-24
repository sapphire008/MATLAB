function  mean_roi = beta_series_roi_nomars(SPM_loc, ROI_loc, Events,trimsd)
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
%
% For example Events = {'GreenProbe_Correct', 'Sn(1)','bf(1)'}
%
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
% get beta values (in Vector form) 
vbetas = spm_get_data(P,SPM.xVol.XYZ);
% get ROI
roi = spm_get_data(ROI_loc,SPM.xVol.XYZ);
roi_idx = find(roi);
% extract mean of ROI from each beta
for n = 1:size(vbetas,1)
    mean_roi(n) = mean(vbetas(n,roi_idx));
end


if trimsd > 0,
    mean_roi = trimts(mean_roi, trimsd, [])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y,ntrimmed] = trimts(y,sd,X,varargin)
% function [y,ntrimmed] = trimts(y,sd,X,[do spike correct])
% 1.  Adjusts for scan effects (unless X is empty)
% 2.  Windsorizes timeseries to sd standard deviations
%       - Recursive: 3 steps
% 3.  Adds scan effects back into timeseries
% Tor Wager

% filter y using X matrix; yf is residuals

if ~isempty(X),
    mfit = X * pinv(X) * y;
    yf = y - mfit;
else
    yf = y;
end

if length(varargin) > 0
    
    
    % attempt to correct for session-to-session baseline diffs
    
    tmp = diff(yf);
    mad12 = median(abs(tmp)) * Inf;    % robust est of change with time (dt)
    wh = find(abs(tmp) > mad12);
    n = 20;
    
    for i = 1:length(wh), 
        st = max(wh(i) - (n-1),1);  % start value for avg
        en = max(wh(i),1);
        st2 = wh(i)+1;
        en2 = min(wh(i)+n,length(yf));  % end value for after
        wh2 = st2:en2;
        m = mean(yf(wh(i)+1:en2)) - mean(yf(st:en)); % average of 5 tp after -  5 time points before
        %figure;plot(st:en2,yf(st:en2));
        yf(wh(i)+1:end) = yf(wh(i)+1:end) - m;,
    end
    
    
    % do spike correction!  Interpolate values linearly with 1 nearest
    % neighbor
    %
    % replace first val with mean
    n = min(length(yf),50);
    yf(1) = mean(yf(1:n));
    
    tmp = diff(yf);
    mad5 = median(abs(tmp)) * 5;    % robust est of tail of dist. of change with time (dt)
    wh = find(abs(tmp) > mad5);
    
    % find paired changes that are w/i 3 scans
    whd = diff(wh);
    wh = wh(whd < 3);
    whd = whd(whd < 3);

    % value of spike is avg of pre-spike and post-spike val.
    wh(wh == 1 | wh == length(yf)) = [];
    for i = 1:length(wh)-1   % bug fix, CW
        yf(wh(i)+1) = mean([yf(wh(i)) yf(wh(i)+1+whd(i))]);
    end
    

end
    
    
    
% trim residuals to sd standard deviations
% "Windsorize"

my = mean(yf);
%sy = std(yf);

%w = find(yf > my + sd * sy);
%w2 = find(yf < my - sd * sy);

%yf(w) = my + sd * sy; 	%NaN;
%yf(w2) = my - sd * sy;

allw = [];

for i = 1:3
    yf2 = scale(yf);
    w = find(abs(yf2) > sd);
    yf(w) = mean(yf) + sd * std(yf) * sign(yf(w));
    
    allw = [allw; w];
end

% put means back into yf
if ~isempty(X),
    y = yf + mfit;
else
    y = yf;
end

ntrimmed = length(unique(allw));  % w) + length(w2);

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

