function [Q,V] = create_thresholded_image(P,Q,thresh,above_below,background_val)
% Create thresholded image. Requires NIFTI package
% 
% Inputs:
%       P: input image
%       Q (optional): save directory or fullpath of the output image. 
%                     If not specified, will append '_thresholded' to the
%                     original image
%       thresh: threshold
%       above_below (optional): above or below the threshold. There are 5
%                               choices implemented: '<','>','<=','>=',
%                               and '='. Default '>='
%       background_val(optional): to what value will the pixels/voxels not
%                                 meeting the threshold. Default is NaN.
%       
%
% Output:
%       Q: full path to the output image
addmatlabpkg('NIFTI');
% parse save names
if nargin<2 || isempty(Q)
    [PATHSTR,NAME,EXT] = fileparts(P);
    Q = fullfile(PATHSTR,[NAME,'_thresholded',EXT]);
elseif ischar(Q) && size(Q,1) == 1%either a directory or whole file name
    [PATHSTR,NAME,EXT] = fileparts(Q);
    if ~isempty(PATHSTR) && isempty(EXT)% specified as a folder
        [~,NAME2,EXT2] = fileparts(P);
        Q = fullfile(Q,[NAME2,EXT2]);
    elseif isempty(PATHSTR)
        [PATHSTR2] = fileparts(P);
        Q = fullfile(PATHSTR2,[NAME,EXT]);
    end
end
if nargin<3 || isempty(thresh)
    error('Threshold required!\n');
end
% above_below
if nargin<4 || isempty(above_below)
    above_below = '>=';
end
%background_val
if nargin<5 || isempty(background_val)
    background_val = NaN;
end

% load IMAGE
V = spm_vol(P);
IMAGE = double(V.private.dat);
V.fname = Q;
V = spm_create_vol(V);

% find the index of each part of imge
switch above_below
    %be explicit
    case '<'
        %IDX = (IMAGE<thresh);
        U_IDX = (IMAGE>=thresh);
    case '<='
        %IDX = (IMAGE<=thresh);
        U_IDX = (IMAGE>thresh);
    case '>'
        %IDX = (IMAGE>thresh);
        U_IDX = (IMAGE<=thresh);
    case '>='
        %IDX = (IMAGE>=thresh);
        U_IDX = (IMAGE<thresh);
    case {'==','='}
        %IDX = (IMAGE ~= thresh);
        U_IDX = (IMAGE ==thresh);
    otherwise
        error('unrecognized threholding scheme!\n');
end

% set to background
IMAGE(U_IDX) = background_val;

% save the IMAGE
V = spm_write_vol(V,IMAGE);
end

