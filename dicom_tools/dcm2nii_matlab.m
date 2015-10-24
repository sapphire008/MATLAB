function [status,result]=dcm2nii_matlab(dicom_folder,output_dir,out_format,archive)
% dicom import using dcm2nii
% [status,result] = dcm2nii_matlab(dicom_folder,output_dir,out_format,archive)
%
% Inputs:
%       dicom_folder: directory of dicoms
%       output_dir(optional): output directory, default will be
%                             dicom_folder
%       out_format(optional): file conversion format
%                 '4d': create 4D concatenated images (Default)
%                 'spm8': single 3D .nii files
%                 'analyze': single 3D analyze format files
%       archive(optional): [true|false] create .gz archives as output 
%                           default is true
%
% Outputs:
%       status: successful or unsuccessful conversion (0 for success and
%               numeric for unsuccessful error code)
%       result: output from the run. If not specified as an output, the
%               result will be written in the output_dir

% directory of mricron's dcm2nii
dcm2nii_path = '/hsgs/projects/jhyoon1/pkg64/standaloneapps/mricron/dcm2nii';
% parse output_dir
if nargin<2 || ~exist('output_dir','var') || isempty(output_dir)
    opt.output_dir = '';%use source directory
else
    opt.output_dir = ['-o ',output_dir,' '];%use specified save_dir
    %check if the directory exists
    if ~exist(output_dir,'dir')
        eval(['!mkdir -p ',output_dir]);
    end
end
% parse output format
if nargin<3 || ~exist('out_format','var') || isempty(out_format)
    opt.out_format = '';
else
    switch out_format
        case '4d'
            opt.out_format = '-4 y ';
        case 'spm8'
            opt.out_format = '-n y -4 n ';
        case 'analyze'
            opt.out_format = '-s y -4 n ';
    end
end
% parse archive (if use .gz format)
if nargin<4 || ~exist('archive','var') || isempty(archive)
    opt.archive = '-g n ';%default no archive
elseif archive
    opt.archive = '-g y ';
else
    opt.archive = '-g n ';
end

% do the conversion
[status,result]=unix([dcm2nii_path,' -v y ',opt.out_format,opt.output_dir,opt.archive,dicom_folder]);

% save conversion results if not specified as an output
if nargout<2
    if nargin<2 || ~exist('output_dir','var') || isempty(output_dir)
        output_dir = dicom_folder;
    end
    FID = fopen(fullfile(output_dir,'dicomimort_result.txt'),'w');
    fprintf(FID,'dicom import started: ');
    fprintf(FID,datestr(now,'mm-dd-yyyy HH:MM:SS'));
    fprintf(FID,'\ndicom source: %s\n\n',dicom_folder);
    fprintf(FID,result);
    fclose(FID);
end
end