function Vo = spm_gz2nii(gznifti_file,save_dir)
% convert 4D file to 3D nifti file for SPM
% Vo = spm_gz2nii(gznifti_file,save_dir)
%
% Inputs:
%       gznifti_file: fullf path to the 4D .nii file. Can either be .gz.nii
%                     or .nii 4D file
%       save_dir: save directory, if not specified, the same path as the
%                 source 4D .nii file
%
% Outputs:
%       Vo: spm_vol structure array of output files, directly from
%           spm_file_split output
%
% requires SPM package

% Last modified: 12/09/2013

addspm8('NoConflicts');
[PATHSTR,~,EXT] = fileparts(gznifti_file);
if nargin<2 || isempty(save_dir)
    save_dir = PATHSTR;
end
% if as .nii.gz
if strcmpi(EXT,'.gz')
    NAME = gunzip(gznifti_file,PATHSTR);
    % pass NAME, the full path of extracted file
    gznifti_file = NAME{1};
end
V = spm_vol(gznifti_file);
Vo = spm_file_split(V,save_dir);
% remove the extracted file
if strcmpi(EXT,'.gz')
    delete(NAME{1});
end
end