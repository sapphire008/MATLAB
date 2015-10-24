function  [Cout, SE] = beta_series_correlation_nomars(SPM, ROI_loc, Events,trimsd,threshold)
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
%
% Output:
%   Cout: output Pearson's R values
%   SE: standard error of the Fisher's Z. 1/(sqrt(N-3))

if ~exist('trimsd','var'), trimsd = 0; end
if ~exist('threshold','var'), threshold = 1; end
if ~iscell(Events), Events = {Events}; end

% locate beta_images related to Event
P = location_of_beta_images_from_event_discription(Events,SPM);
save('P.mat','P','Events','SPM');return;

% Get header info for beta data
V = spm_vol(P);

% get ROI index and transform matrix
[XYZ ROImat]= roi_find_index(ROI_loc,threshold);

% generate XYZ locations for each beta image
% correcting for alignment issues
betaXYZ = adjust_XYZ(XYZ, ROImat, V);

% extract mean of ROI from each beta
for n = 1:length(betaXYZ),
    foo = spm_get_data(P(n),betaXYZ{n});
    mean_roi(n) = mean(foo(:));
end

clear foo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if trimsd > 0,
    mean_roi = trimts(mean_roi, trimsd, []);
end

%load all beta data
vbetas = spm_get_data(P,SPM.xVol.XYZ);
% for each voxel in beta images
for n = 1:size(vbetas,2),
    if trimsd > 0,
        vbetas(:,n) = trimts(vbetas(:,n), trimsd, []);
    end
    Cout(n)  = corr(mean_roi',vbetas(:,n),'type','Pearson');
end

SE = 1/sqrt(length(P)-3);


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

if ~isempty(varargin) > 0
    
    
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
        yf(wh(i)+1:end) = yf(wh(i)+1:end) - m;
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


function [H] = scale(S)

% SCALE returns the homogenous coordinate transformation matrix
% corresponding to a scaling along the x, y and z-axis
% 
% Use as
%   [H] = translate(S)
% where
%   S		[sx, sy, sz] scaling along each of the axes
%   H 	corresponding homogenous transformation matrix

% Copyright (C) 2000-2005, Robert Oostenveld
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Log: scale.m,v $
% Revision 1.2  2005/08/15 08:15:33  roboos
% reimplemented the rotate function, which contained an error (the error is in the AIR technical reference)
% changed all functions to be dependent on the rotate, translate and scale function
% all functions now behave consistenly, which also means that they are not compleetly backward compatible w.r.t. the order of the rotations
%
% Revision 1.1  2004/05/19 09:57:07  roberto
% added GPL copyright statement, added CVS log item
%

H = [
  S(1) 0    0    0 
  0    S(2) 0    0
  0    0    S(3) 0
  0    0    0    1
  ];



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
if length(idx)==1,
    reduced_idx=idx;
else
    for n = 2:length(idx),
        reduced_idx{n-1} = intersect(idx{n},ref_idx);
    end
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

