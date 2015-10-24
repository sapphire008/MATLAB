function Vb = spm_create_binary_mask(V,out_dir,thresh,above_below,bool_intersection)
% create binary mask based on intensity threshold
%  Vb = spm_create_binary_mask(V,out_dir,thresh,above_below,intersection)
% 
% Input:
%   V: input images. Either V = spm_vol(P), or P = full paths to images as
%      character array. NaNs in the image will be treated as 0s.
%   out_dir: output directory. Default the same directory as the input,
%            with '_mask' appended to the end of the name. If desired to
%            specify a different name, input as a cellstr or character
%            array of new names with length the same as the number of 
%            input images
%   thresh: a numeric or a matrix of numerics with the same size as
%              IMAGE
%   above_below: threhold above or below the set threshold. Input as
%                symbols of comparison operators, such as '<','>',
%                '<=',and '>='. E.g. if above_below='>=', then, values
%                >= thresh will be 1 and values < thresh will be 0;
%   intersection: [true|false] set to true to create intersection 
%                masks instead of creating maks for each input image,
%                assuming all the images are coregistered/normalized.
%                Default is false.
%
% Output:
%   Vb: binary image handle
%   
%
% Example: 
%       Vb = spm_create_binary_mask(P,pwd,100,'>=');

if nargin<1
    help spm_create_binary_mask;
end
% load image if not already
if ~isstruct(V)
    V = spm_vol(char(V));
end
% parse bool_intersection
if nargin<5 || isempty(bool_intersection) || length(V)<2
    bool_intersection = false;
end
% parse save names
if nargin<2 || isempty(out_dir)
    [PATHSTR,NAME,EXT] =arrayfun(@(x) fileparts(x.fname),V,'un',0);
    if bool_intersection
        out_dir = fullfile(PATHSTR{1},'intersection_mask.nii');
    else
        out_dir = cellfun(@(x,y,z) fullfile(x,[y,'_mask',z]),...
            PATHSTR,NAME,EXT,'un',0);
    end
elseif ischar(out_dir) && size(out_dir,1) == 1
    [PATHSTR,NAME,EXT]=fileparts(out_dir);
    if isempty(NAME)
        NAME = 'intersection_mask';
        EXT = '.nii';
    end
    if bool_intersection
        out_dir = fullfile(PATHSTR,[NAME,EXT]);
    else
        [~,NAME,EXT] = arrayfun(@(x) fileparts(x.fname),V,'un',0);
        out_dir = cellfun(@(y,z) fullfile(out_dir,[y,'_mask',z]),...
            NAME,EXT,'un',0);
    end
else % assuming either character array of list of images or cellstr
    out_dir = cellstr(out_dir);
end
if nargin<3 || isempty(thresh) || isnan(thresh) || ~isnumeric(thresh)
    error('Threshold required');
end
% parse above_below
if nargin<4 || isempty(above_below)
    above_below = '>=';
end


if ~bool_intersection
    % place holding for output images
    Vb = num2cell(V);
    % change the save name
    Vb = cellfun(@setfield,Vb,cellstr(repmat('fname',length(Vb),1)),out_dir);
    % create image
    Vb = spm_create_vol(Vb);
    % write data
    for n = 1:length(Vb)
        Vb(n) = spm_write_vol(Vb(n),...
            threshold_main_func(double(V(n).private.dat),thresh,above_below));
    end
else% create intersection mask
    Vb = V(1);
    % Check if all the images have the same orientation
    %D_mat = sqrt(bsxfun(@plus,dot(A,A,2),dot(B,B,2)')-2*(A*B'));
    mat={V.mat};mat=cellfun(@(x) x(:),mat,'un',0);mat=cell2mat(mat)';
    D_mat = sqrt(bsxfun(@plus,dot(mat,mat,2),dot(mat,mat,2)')-2*(mat*mat'));
    if any(D_mat(:))
        error('Images are not in the same orientation\n');
    else
        clear D_mat mat;
    end
    % Check if all the images have the same dimension
    dim={V.dim};dim=cellfun(@(x) x(:),dim,'un',0);dim=cell2mat(dim)';
    D_dim = sqrt(bsxfun(@plus,dot(dim,dim,2),dot(dim,dim,2)')-2*(dim*dim'));
    if any(D_dim(:))
        error('Images do not have the same dimension\n');
    else
        clear D_dim dim;
    end
    % Change the output name
    Vb.fname = char(out_dir);
    Vb = spm_create_vol(Vb);
    MASK = true(Vb.dim);
    for n = 1:length(V)
        MASK = MASK & threshold_main_func(double(V(n).private.dat),thresh,above_below);
    end
    Vb = spm_write_vol(Vb,MASK);
end
end

function IMAGE = threshold_main_func(IMAGE,thresh,above_below)
%instead of set to 0, set to VAL for flexibility (0 or NaN or some
%other number can be chosen in the future)
IMAGE(isnan(IMAGE))=0;
switch above_below
    %be explicit
    case '<'
        IDX = (IMAGE<thresh);
        U_IDX = (IMAGE>=thresh);
    case '<='
        IDX = (IMAGE<=thresh);
        U_IDX = (IMAGE>thresh);
    case '>'
        IDX = (IMAGE>thresh);
        U_IDX = (IMAGE<=thresh);
    case '>='
        IDX = (IMAGE>=thresh);
        U_IDX = (IMAGE<thresh);
end
IMAGE(IDX) = 1;%set the part user want to keep as 1
IMAGE(U_IDX) = 0;%set the part user want to discard as VAL
IMAGE = logical(IMAGE);
end