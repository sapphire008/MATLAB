function V = ROI_thresh_map(V_spmT,ROI, thresh_criterion,varargin)
V_spmT = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/mid/analysis/GLM_Cue_Feedback/M3129_CNI_060814/spmT_0019.img';
ROI = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/TR2/M3129_CNI_060814_TR2_SNleft.nii';
% load spmT and ROI
if ischar(V_spmT),V_spmT = spm_vol(V_spmT);end
if ischar(ROI), ROI = spm_vol(ROI);end
flag = parse_varargin(varargin,{'quantile_range',[0.5,0.997]},{'thresh_at',[]},{'above_below','>='});
% get ROI indices
ROI_XYZ = get_roi_info(ROI.fname);
% get spmT map at ROI
ROI_Y = spm_get_data(V_spmT,ROI_XYZ);
switch lower(thresh_criterion)
    case 'remove_outlier'
        % need stats toolbox
        LOC = remove_outlier(ROI_Y,[],flag.quantile_range);
    case 'fdr'
        % need stats toolbox
        pID = FDR(1-tcdf(ROI_Y,numel(ROI_Y)-1));
        tID = tcdf(1-pID, numel(ROI_Y)-1);
        LOC = find(ROI_Y>tID);
    case 'cluster'
        LOC = activation_cluster(ROI_XYZ,ROI_Y);
    case 'thresh'
        LOC = threshold_val(ROI_Y,flag.thresh_at,flag.above_below);
end
% subset of indices
Y = ROI_Y(LOC);
ROI_XYZ = ROI_XYZ(:,LOC);
% write new ROI
V = ROI;
[PATHS,NAME,EXT] = spm_fileparts(ROI.fname);
V.fname = fullfile(PATHS,[NAME,'_thresh',EXT]);
IND = sub2ind(V.dim,ROI_XYZ(1,:),ROI_XYZ(2,:),ROI_XYZ(3,:));
W = zeros(V.dim); W(IND) = Y;
V = spm_create_vol(V);
V = spm_write_vol(V,W);
end

function LOC = threshold_val(X,thresh_at,above_below)
%instead of set to 0, set to VAL for flexibility (0 or NaN or some
%other number can be chosen in the future)
NaN_IND = isnan(X);
X(isnan(X))=0;
%evalc(sprintf('IDX = (X %s thresh_at);',above_below));
switch above_below
    %be explicit
    case '<'
        IDX = (X<thresh_at);
    case '<='
        IDX = (X<=thresh_at);
    case '>'
        IDX = (X>thresh_at);
    case '>='
        IDX = (X>=thresh_at);
end
LOC = find((~NaN_IND) & IDX);
end

function LOC = activation_cluster(XYZ,X)
% minimize both distance and values of the voxel
MAT = [XYZ;X]'; MAT = bsxfun(@rdivide, MAT,mean(MAT,1));
%D_mat = sqrt(bsxfun(@plus,dot(MAT,MAT,2),dot(MAT,MAT,2)')-2*(MAT*MAT'));
% kmeans clustering
IDX = kmeans(MAT,2,'Distance','sqEuclidean','Start','uniform',...
    'Replicates',7,'EmptyAction','drop');
U_IDX = unique(IDX);
[~,LOCID] = max(cellfun(@(x) mean(X(IDX==x)),num2cell(U_IDX)));
LOC = find(IDX==U_IDX(LOCID));
end

function LOC = remove_outlier(X,W,P)
% use boxplot method to remove outliers. Requires statistical toolbox to
% calculate quantile and IQR
% Inputs:
%   X: values
%   W: whisker length. Default 1.58
%   P: quantile range [min, max], default [0.25, 0.75]
% Outputs:
%   Y: value after outlier removal
%   LOC: index of Y relative to X

if nargin<2 || isempty(W), W = 1.58;end
if nargin<3 || isempty(P), P = [0.25, 0.75];end
boxplot_thresh = quantile(X,P)+W*[-1,1]*iqr(X);
LOC = find((X>=boxplot_thresh(1)) & (X<=boxplot_thresh(2)));
end

function [pID,pN] = FDR(p,q)
% FORMAT [pID,pN] = FDR(p,q)
% 
% p   - vector of p-values
% q   - False Discovery Rate level
%
% pID - p-value threshold based on independence or positive dependence
% pN  - Nonparametric p-value threshold
%______________________________________________________________________________
% $Id: FDR.m,v 1.1 2009/10/20 09:04:30 nichols Exp $

if nargin<2 ||isempty(q), q = 0.05;end

p = p(isfinite(p));  % Toss NaN's
p = sort(p(:));
V = length(p);
I = (1:V)';

cVID = 1;
cVN = sum(1./(1:V));

pID = p(max(find(p<=I/V*q/cVID)));
pN = p(max(find(p<=I/V*q/cVN)));

if isempty(pID),pID = 0;end
if isempty(pN), pN = 0; end
end

function [XYZ,M,mat,dim,dt]=get_roi_info(V)
% get ROI or any binary mask information
% Inputs:
%   V: either path to the image or spm_vol loaded image handle
% Outputs:
%   XYZ: coordinate the mask
%   M: values at the coordiante
%   mat: rotation matrix of the mask
%   dim: dimension of the mask
%   dt: data type
if iscellstr(V),V = char(V);end
if ischar(V),V = spm_vol(V);end
mat = V.mat;dim=V.dim;dt=V.dt;
V = double(V.private.dat);
[X,Y,Z] = ind2sub(size(V),find(V));
XYZ = [X(:)';Y(:)';Z(:)']; clear X Y Z;
M = V(V~=0); M = M(:)';
end

function flag = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1'}.
flag = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
    else
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end