function ROI_reslice3D2template(IMAGE,outfile,TEMPLATE,ROI,C3DPATH)
% reslice native space ROIs to a template ROI
% ROI_reslice3D2template(ROI, outfile,TEMPLATE)
% Requires Convert3D from ITK-SNAP
% Inputs:
%       IMAGE: image to extract the normalized ROI data from
%       ROI: full path to target ROI
%       outfile: full path to output file
%       TEMPLATE: full path to template ROI
%       C3DPATH: full path to Convert3D tool

IMAGE = 
ROI = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/MP026_062613_TR2_SNleft.nii';
outfile = '/nfs/jong_exp/midbrain_pilots/ROIs/coreg_MP026_062613_TR2_SNleft.nii';
TEMPLATE = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/MP025_061013_TR2_SNleft.nii';









% Use Convert3D's -align-landmarks function (newly developed)
if nargin<4 || isempty(C3DPATH)
    C3DPATH = '/usr/local/pkg64/matlabpackages/c3d-1.0.0-Linux-x86_64/bin/c3d';
end

match_landmark_C3D(TEMPLATE,ROI,outfile,C3DPATH);

end



%% Methods of transformation

% use SPM's coregistration function to calculate an affine transformation
% matrix to apply to the moving image
function spm_coreg_match_template(TEMPLATE,ROI,varargin)
flags = ParseOptionalInputs(varargin,...
    {'cost_fun','sep','fwhm'},...
    {'nmi',[4,2,1,0.5],[2,2]});
VF = spm_vol(TEMPLATE);
VG = spm_vol(ROI);
X = spm_coreg(VF,VG,flags);
end

% use Convert3D's -align-landmarks command, which calculates an affine
% transformation matrix to apply to the moving image. So far this command
% is documented, but not released.
function match_landmark_C3D(TEMPLATE,ROI,OUTFILE,C3DPATH)
% parse outfile
[PATHSTR, NAME, ~] = fileparts(outfile);
% output file name of the affine matrix
AFFINE_MAT_NAME = fullfile(PATHSTR,[NAME,'_affine.mat']);
% calculating transformation
eval(['!',C3DPATH, ' ',TEMPLATE,' ',ROI,' -align-landmarks 12 ',AFFINE_MAT_NAME]);
% reslicing by applying transformation
eval(['!',C3DPATH, ' ',TEMPLATE,' ',ROI,' -reslice-matrix',AFFINE_MAT_NAME,' -o ',OUTFILE]);
end

