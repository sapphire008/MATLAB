function Y_fitted = extract_roi_fitted_time_course(ROI_loc,SPM,Events)
% Extract fitted time course from an ROI
% 
% Y_fitted = extract_roi_fitted_time_course(ROI_loc, SPM, Events)
% 
% Inputs:
%   ROI_loc: path to ROI, or spm_vol handle of the ROI
%   SPM: path to SPM.mat file, or SPM structure, of trialwise GLM.
%   Events: cellstr list of events to extract fitted time course from. 
% 
% Output:
%   Y_fitted: fitted time course cell array of structures
%       .event_name: current event name
%       .time_course: mean time course of the ROI
%

% ROI_loc = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR2/MP023_052013_TR2_SNleft.nii';
% SPM= '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/trialwiseGLM/MP023_052013/SPM.mat';
% Events = {'Cue_gain5','Cue_gain1','Cue_gain0','Cue_lose0','Cue_lose1','Cue_lose5'};

% get coordinate of ROI
ROI_XYZ = get_roi_info(ROI_loc);
% load SPM if not already
if ischar(SPM),load(SPM);end
% initialize data structure
Y_fitted(length(Events)) = struct;
% transversing through all events
for n = 1:length(Events)
    % get fitted time course for all voxels ofthe ROI, at current event
    Y = event_fitted_time_course(SPM,event_name,ROI_XYZ);
    Y_fitted(n).event_name = Events{n};
    % take an average over all voxels
    Y_fitted(n).time_course = mean(Y,2);
    clear Y;
end
end

% calculate fitted percent signal change time course
function Y = event_fitted_time_course(SPM, event_name, ROI_XYZ)
% Given Y = X*Beta+epsilon --> PSC = X*Beta_hat / intercept *100
% Use trialwise GLM to estimate percent signal change per trial more 
% accurately

% get event index
event_IND = ~cellfun(@isempty,cellfun(@(x) regexp(x,event_name),{SPM.Vbeta.descrip},'un',0));
% get session number of current event
% sess_num = cellfun(@(x) regexp(x,'Sn\((\d)\)','tokens'),{SPM.Vbeta(event_IND).descrip},'un',0);
% sess_num = cellfun(@(x) str2double(x{1}{1}), sess_num,'un',0);
% get roi beta values
V = spm_vol(char(cellfun(@(x) fullfile(SPM.swd,x),{SPM.Vbeta(event_IND).fname},'un',0)));
betas = spm_get_data(V,ROI_XYZ);
clear V;
% get design matrix
X = SPM.xX.X(:,find(event_IND)); %design matrix
% construct temporal points: Y_hat = X*betas
Y = X*betas;
clear X betas event_IND;
% get constant term ROI data
constant_IND = ~cellfun(@isempty,cellfun(@(x) regexp(x,'constant'),{SPM.Vbeta.descrip},'un',0));
V = spm_vol(char(cellfun(@(x) fullfile(SPM.swd,x),{SPM.Vbeta(constant_IND).fname},'un',0)));
C = spm_get_data(V,ROI_XYZ);
clear V;
C = mat2cell(C,ones(1,size(C,1)),size(C,2));
C = cellfun(@(x,y) repmat(x,y,1),C,num2cell(SPM.nscan(:)),'un',0);
C = cell2mat(C);
% calculate percent signal change
Y = Y./C*100;
clear C;
end

function [XYZ,mat,dim]=get_roi_info(V)
% get ROI or any binary mask information
% Inputs:
%   V: either path to the image or spm_vol loaded image handle
% Outputs:
%   XYZ: coordinate the mask
%   mat: rotation matrix of the mask
%   dim: dimension of the mask
if iscellstr(V),V = char(V);end
if ischar(V),V = spm_vol(V);end
mat = V.mat;dim=V.dim;
V = double(V.private.dat);
[X,Y,Z] = ind2sub(size(V),find(V));
XYZ = [X(:)';Y(:)';Z(:)']; clear X Y Z;
end