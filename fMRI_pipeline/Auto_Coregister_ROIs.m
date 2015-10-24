function [ROI,M] = Auto_Coregister_ROIs(ROI,Template_reference,Template_source,fname,varargin)
% Automatically coregister ROI from one template to another
%
% [ROI,M] = Auto_Coregister_ROIs(ROI,Template_reference,Template_source,fname,'flags1',val1,...)
%
% Inputs:
%
%   ROI: full file to ROI to be coregistered, or spm_vol loaded nifti
%        handle of the ROI
%
%   Template_reference: reference image, which is the new template space.
%        Either full path to the template image or spm_vol loaded nifti 
%        handle of the image.
%
%   Template_source: source image, which is in the same space with ROI.
%        Either full path to the template image or spm_vol loaded nifti 
%        handle of the image.
%
%   fname: output new ROI's name. If not specified, will append a 'x' in
%          front of the original ROI's name and saved under the same path
%          as the original ROI
%
%   For optional flags, see help documents of spm_coreg and spm_reslice
%
% Outputs:
%   
%   ROI: handle of coregistered ROI
%   
%   M: transformation matrix fro source to reference

% load images
if ischar(ROI), ROI = spm_vol(ROI);end
if nargin<4 || isempty(fname)
    [PATHS,NAME,EXT] = spm_fileparts(ROI.fname);
    fname = fullfile(PATHS,['x',NAME,EXT]);
    clear PATHS NAME EXT;
end
if ischar(Template_reference), Template_reference = spm_vol(Template_reference);end
if ischar(Template_source), Template_source = spm_vol(Template_source);end

% estimate coregistration
flags = parse_varargin(varargin,{'sep',[4,2,1,0.5]},{'params',[0,0,0,0,0,0]},...
    {'cost_fun','nmi'},{'tol',[0.02 0.02 0.02 0.001 0.001 0.001]},...
    {'fwhm',[7,7]},{'graphics',false});
X = spm_coreg(Template_reference,Template_source,flags);
% calculate transformation
M = spm_matrix(X);

% change the ROI image header
D = double(ROI.private.dat);%get the data
ROI.mat = M*ROI.mat;%correct the orientation
ROI.fname = fname;%change to new name

% for each ROI inside, reslice the ROI
ROI_label = unique(D(:));
ROI_label = ROI_label(ROI_label>0);
D = 0;
for n = 1:length(ROI_label)
    % get ROI with current label
    D = D + reslice_each_ROI(ROI,Template_reference.fname,ROI_label(n),varargin{:});
end

%write out resliced ROI
ROI.dim = size(D);
ROI.mat = Template_reference.mat;
ROI = spm_create_vol(ROI);
ROI = spm_write_vol(ROI,D);
end

function D = reslice_each_ROI(ROI,reference_fname,ROI_label,varargin)
% ROI: ROI handle
% reference_name: reference image to be resliced into
% ROI_label: label to use in the resulting ROI
% D: data with only 1 ROI

% get the optional flags for reslicing
flags = parse_varargin(varargin,{'mask',false},{'mean',false},{'interp',4},...
    {'which',1},{'wrap',[0,0,0]},{'prefix',''});
% load only data with current label
D = double(ROI.private.dat);
%label everything with 1's and 0's only
D(D~=ROI_label) = 0;
D(D>0) = 1;
% save the image as a temp file
[PATHS,NAME,EXT]=spm_fileparts(ROI.fname);
ROI.fname = fullfile(PATHS,[NAME,'_tmp',EXT]);
ROI.dt = [16,0];%make sure data is in float32 for better interpolation
% recreate the file
ROI = spm_create_vol(ROI);
ROI = spm_write_vol(ROI,D);
% reslice the file
spm_reslice([{reference_fname};{ROI.fname}],flags);
% read in the ROI again / update handle
ROI = spm_vol(ROI.fname);
D = double(ROI.private.dat);
D(isnan(D)) = 0;
D = round(D);
D(D>0) = ROI_label;
% remove the temp file
delete(ROI.fname);
end

function flags = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1'}.
flags = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flags.(varargin{n}{1}) = options{2*find(tmp,1)};
    else
        flags.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end
