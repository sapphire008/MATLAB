function V = ROI_masked_maps(Map,ROI,fname,subset,verbose)
% Get the map within a given ROI
%   V = ROI_masked_maps(Map, ROI, fname, subset, verbose);
%
% Inputs:
%   Map: either full path to maps/images to be masked out, or spm_vol 
%        loaded handles of the maps/images
%   ROI: either full path to ROI,  or spm_vol loaded handle
%   fname: (optional) output image name. Default is Mapname_ROI_name.nii,
%          saved in the same path as the map. If specified not as full
%          path, image will be saved at the current working directory.
%   subset: (optional) subset of ROI labels. Default include all the labels
%           greater than 0. Specify positive labels to include and negative
%           values of the labels to exclude the labels
%   verbose:(optional) display progress
%
% Output:
%   V: nifti handle of the output images

% load image handles
if nargin<5 || isempty(verbose),verbose = false;end
if verbose,disp('loading images ...');end
if ischar(Map)
    Map = spm_vol(Map);
elseif iscellstr(Map)
    Map = spm_vol(char(Map));
end
if ischar(ROI),ROI = spm_vol(ROI);end
if nargin<3 || isempty(fname)
    [PATHSTR,NAME_map,~] = cellfun(@fileparts,{Map.fname},'un',0);
    [~,NAME_roi,~] = fileparts(ROI.fname);
    fname = cellfun(@(x,y) fullfile(x,sprintf('%s_%s.nii',y,NAME_roi)),PATHSTR,NAME_map,'un',0);
    clear PATHSTR NAME_roi NAME_map;
end
if ischar(fname),fname = cellstr(fname);end
% get ROI and mask index
ROI = double(ROI.private.dat);
IND = unique(ROI(ROI>0));
if nargin<4 || isempty(subset),subset = IND;end
% parse subset argument
if any(subset>0) && any(subset<0)
    error('subset cannot contain both positive and negative labels\n');
elseif any(subset>0)
    IND = intersect(IND,subset);
elseif any(subset<0)
    IND = setdiff(IND,-subset);
else
    error('unrecognized subset specification\n');
end
if isempty(IND),error('No labels avilable in the ROI\n');end
% write the map
ROI(ROI>0)=1;
V=Map;
for m = 1:numel(Map)
    if verbose,fprintf('image %d\n',m);end
    V(m).fname = fname{m};
    K = double(Map(m).private.dat).*ROI;
    V(m) = spm_create_vol(V(m));
    V(m) = spm_write_vol(V(m),K);
    clear K;
end
clear ROI;
end