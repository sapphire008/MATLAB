function V = spm_imghdr2nii(V,remove_source)
% change .img/.hdr NIFTI file format to .nii
%
% Inputs:
%   V: paths to .img file. Otherwise, spm_vol loaded handle of the .img
%      file
%   remove_source (optional): remove original .img/.hdr file. Default is 
%      true.

if ischar(V);V = spm_vol(V);end
if nargin<2 || isempty(remove_source)
    remove_source = true;
end
% store original data
W = double(V.private.dat);
% change name
[PATHS,NAME,~] = spm_fileparts(fname);
V.fname = fullfile(PATHS,[NAME,'.nii']);
% rewrite the file to nii
V = spm_create_vol(V);
V = spm_write_vol(V,W);
% remove original .img and .hdr file
if remove_source
    eval(['!rm ', fullfile(PATHS,[NAME,'.img'])]);
    eval(['!rm ', fullfile(PATHS,[NAME,'.hdr'])]);
end
end