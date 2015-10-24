function resample_nii(nii_path,save_path,dim,C3DPATH)
% resample nifti files to specified dimension
% uses C3D from ITK-Snap to resample images
% resample_nii(nii_path,save_path,dim,C3DPATH)
% Inputs:
%       nii_path: full path of nifti image
%       save_path: full path, with name, of save directory
%       dim:  1x3 vector, dimensions of new image. 
%	      Default 1x1x1mm
%       C3DPATH: (optional) directory of C3D pacakge. 
%                If not specified, will try to, 
%                use addmatlabpkg to locate the file

if nargin<3 || isempty(dim)
    dim = [1,1,1];
end
if nargin<4 || isempty(C3DPATH)
    C3DPATH = '/hsgs/projects/jhyoon1/pkg64/standaloneapps/c3d-0.8.2-Linux-x86_64/bin/c3d';
end
%convert dim into a string intepretable by the program
dim = [sprintf('%0.1fx',dim(1:2)),sprintf('%0.1fmm',dim(3))];
eval(['!',C3DPATH,' ',nii_path,' -resample-mm ',dim,' -o ',save_path]);
end
