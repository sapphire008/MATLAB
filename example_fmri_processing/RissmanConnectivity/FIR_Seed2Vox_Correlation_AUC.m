function FIR_Seed2Vox_Correlation_AUC(SPM,Events,ROI_loc,ROI_names,Mask_loc,output_image,postproc,verbose)
% generate connecitivty maps based on FIR deconvolved time series. 
% Requires SPM
%
% FIR_Seed2Vox_Correlation(SPM,Events,ROI_loc,ROI_name,Mask_loc,output_image,postproc,verbose)
%
% Inputs:
%   SPM: either the full path of SPM.mat or loaded SPM
%   ROI_loc (cellstr): full paths to ROIs, input as cellstr for multiple ROIs
%   ROI_name (cellstr): ROI name to be used in the output file
%   Mask_loc (char): full path to binary mask of the brain to be analyzed
%   output_img (char): full path to save image. Output type, ROI name,
%           and event name will be appended. Default is the same directory
%           as SPM.
%   postproc: cellstr of post-processing of the correlation maps. Default
%             contains {'pearson'}.
%             Can ignore saving 'pearson' by overwritting with other
%             options. Available options are the following:
%             1). 'Pearson': Pearson's R correlation
%             2). 'R2Z': Fisher's R to Z transform, atanh(R)
%             3). 'Z_Test': divide R2Z map by standard error of R2Z values,
%                           which is 1/sqrt(numel(N)-3, where N is numebr
%                           of data used in computing correlation
%   verbose (boolean): optional. display progress. Default is false.
%
% Outpus:
%   Output images of connectivity maps.


if ~isstruct(SPM),load(SPM);end
if nargin<6 || isempty(output_image),output_image=SPM.swd;end
if nargin<7 || isempty(postproc),postproc = {'pearson'};end
if nargin<8 || isempty(verbose),verbose=false;end

% get event associated files
for k = 1:length(Events)
    FIR_beta_series_correlation(SPM,Events{k},ROI_loc,ROI_names,...
        Mask_loc,output_image,postproc,verbose);
end
end

%% Sub-routines
% main function: apply to each event as it constitutes different set of
% source beta images
function V_map = FIR_beta_series_correlation(SPM,Events,ROI,ROI_names,...
    Mask,output_image,postproc,verbose)
% Running this function can be quite memory intensive, but the performance
% speed is better.

if verbose,fprintf('Importing images and ROIs ...\n');end
% get a list of event associated files
P = [];
for bf = 1:SPM.xBF.order
    % basis x trial
    P = [P;location_of_beta_images_from_event_discription(...
        {Events,sprintf('bf(%d)',bf)},SPM,bf==SPM.xBF.order)];
end
if isempty(P)
    V_map = [];
    fprintf('Event %s does not exist; skipped\n',Event_name);
    return;
elseif verbose
    fprintf('Current Event: %s\n',Event_name);
end
% Standard error
SE = 1/sqrt(numel(P)-3);
% get header of each image, concatenated over time
V = spm_vol(char(P)); clear P;
% get ROI indices
[ROI_XYZ,~,dim,~] = cellfun(@get_roi_info,ROI,'un',0);
dim = dim{1};
% get ROI averaged time series
ROI_TS = cellfun(@(x) nanmean(spm_get_data(V,x),2),ROI_XYZ,'un',0);
ROI_TS = cellfun(@(x) block_AUC(x,1,SPM.xBF.order)',ROI_TS,'un',0);%AUC
clear ROI_XYZ;
% get the handle of the mask
Mask = spm_vol(Mask);
% create correlation images to be written
V_map = repmat(V(1),numel(postproc),numel(ROI));
[PATHSTR,NAME,EXT] = fileparts(output_image);
for p = 1:numel(postproc)
    for r = 1:numel(ROI)
        description = [postproc{p},'_',ROI_names{r},'_',Event_name];
        V_map(p,r).fname = fullfile(PATHSTR,[NAME,'_',description,EXT]);
        V_map(p,r).descrip = description;
        V_map(p,r) = spm_create_vol(V_map(p,r));
    end
end
% transverse through each plane
if verbose,fprintf('Calculating Correlation Maps ...\n');end
for s = 1:dim(3)
    if verbose,print_progress('Current Plane: ',s,dim(3));end
    Mask_Y = spm_get_slice(Mask,3,s);
    if all(~Mask_Y(:))
        % create empty.
        image_type = 'zero';
    else
        % get current XYZ
        Image_Y = spm_get_slice(V,3,s);
        Image_Y(isnan(Image_Y)) = 0;
        % mask out current slices
        Image_Y = bsxfun(@times,Image_Y,Mask_Y);
        Image_Y = block_AUC(Image_Y,1,SPM.xBF.order);%AUC
        image_type = 'postproc';
    end
    clear Mask_Y;
    % create correlation maps 
    for r = 1:numel(ROI_TS)
        % do correlation
        if ~strcmpi(image_type,'zero')
            R = squeeze(faster_corr(repmat(ROI_TS{r},...
                [1,dim(1:2)]),Image_Y));
        end
        % write to plane
        for p = 1:numel(postproc)
            if ~strcmpi(image_type,'zero'),image_type = postproc{p};end
            switch lower(image_type)
                case 'pearson'
                    V_map(p,r) = spm_write_plane(V_map(p,r),R,s);  
                case 'r2z'
                    V_map(p,r) = spm_write_plane(V_map(p,r),atanh(R),s);          
                case 'z_test'
                    V_map(p,r) = spm_write_plane(V_map(p,r),atanh(R)/SE,s);                  
                case 'zero'
                    V_map(p,r) = spm_write_plane(V_map(p,r),zeros(dim(1:2)),s);
            end
        end
        clear R;
    end
    clear Image_Y;
end
end

function [XYZ,mat,dim,dt]=get_roi_info(P)
% get some fields of spm_vol(P)
if ~isstruct(P)
    P = spm_vol(P);
end
mat = P.mat; dim = P.dim; dt=P.dt;
P = double(P.private.dat);
[X,Y,Z] = ind2sub(size(P),find(P>0 & ~isnan(P)));
clear P;
XYZ = [X(:)';Y(:)';Z(:)'];
clear X Y Z;
end

function R=faster_corr(X,Y)
%faster way to compute Pearson's correlation
%http://stackoverflow.com/questions/9262933/what-is-a-fast-way-to-compute-column-by-column-correlation-in-matlab
%rows index time, columns index dimension
X=bsxfun(@minus,X,mean(X,1));% remove column mean
Y=bsxfun(@minus,Y,mean(Y,1));% remove column mean
X=bsxfun(@times,X,1./sqrt(sum(X.^2,1))); %% L2-normalization
Y=bsxfun(@times,Y,1./sqrt(sum(Y.^2,1))); %% L2-normalization
R=sum(X.*Y,1);
end

function Y = spm_get_slice(P,dim,slicenum)
% Get data from the specified slice from a stack of 3D volumes
% Inputs:
%   P: spm_vol loaded image handle
%   dim: dimension to get the slice from
%   slicenum: which slice to get
% Output:
%   Y: T x M x N matrix, where T is the number of volumes in P, M and N are
%      dimensions of the slices

% sanity check
nslices = P(1).dim(dim);
if slicenum>nslices
    error('Slice number requested is beyond the total number of slices in current dimension\n');
end
clear nslices;
notdim = [1,2,3];
notdim = notdim(notdim~=dim);
[Y,X] = meshgrid(1:P(1).dim(notdim(2)),1:P(1).dim(notdim(1)));
XYZ = zeros(3,numel(X));
XYZ(dim,:) = slicenum*ones(1,numel(X));
XYZ(notdim(1),:) = X(:)';
XYZ(notdim(2),:) = Y(:)';
clear X Y;
Y = spm_get_data(P,XYZ);
clear XYZ;
Y = reshape(Y,[numel(P),P(1).dim(notdim)]);
end

function [P,Event_name] = location_of_beta_images_from_event_discription(Events,SPM,return_event_name)
% P = location_of_beta_images_from_event_discription(Events,SPM)
% Events = Cell Array of Strings that defines a unique set of beta images
% SPM data structure

discription = {SPM.Vbeta.descrip}; % extract discription

% this block finds sets of index where discriptions match Events
%Event_name = '';
idx = cell(1,length(Events));
Event_name = '';
for n = 1:length(Events),
    idx{n} = strfind(discription,Events{n});
    idx{n} = find(~cellfun('isempty',idx{n})); %strip out non matching results
    Event_name = [Event_name,'_',Events{n}];
end

% Fix Event_name
if return_event_name
    Event_name =  regexprep(Event_name, 'bf\((\d*)\)','');%remove bf(n)
    underscoreIND = regexp(Event_name,'_');
    Event_name(underscoreIND(underscoreIND==1 | ...
        underscoreIND==length(Event_name)))='';
    IND = intersect(regexp(Event_name,'(\W)'),...
        intersect(regexp(Event_name,'(\S)'),...
        regexp(Event_name,'[^_-+]')));
    Event_name(IND) = '';
    assignin('caller','Event_name',Event_name);
    clear underscoreIND IND;
end

% this block find the intersection of all sets of index
ref_idx = idx{1};
if length(idx)==1,
    reduced_idx=idx;
else
    for n = 2:length(idx),
        reduced_idx{n-1} = intersect(idx{n},ref_idx);
    end
end
final_idx = [];
for n = 1:length(reduced_idx),
    final_idx = union(reduced_idx{n},final_idx);
end

if isempty(final_idx)
    P = [];
    return;
end

% make array of location of beta images
P = cellfun(@(x) fullfile(SPM.swd,x),{SPM.Vbeta(final_idx).fname},'un',0);
end

function print_progress(Message,Ind,OutOf)
% print progress in a for loop
if Ind == 1
    fprintf('%s %d',Message,Ind);
else
    fprintf(repmat('\b',1,numel(num2str(Ind-1))));
    fprintf('%d',Ind);
end
if Ind==OutOf, fprintf('\n');end
end

function Y = block_AUC(Y,dim,M)
% blockwise average area under the curve performed on an N-dimensional data
% matrix.
% Inputs:
%   Y: data matrix
%   dim: dimension to calculate AUC
%   M: block size, dividing dimension dim into blocks with size of M.
%      size(Y,dim) must be divisible by M.
XYZ = size(Y);
XYZ = [XYZ(1:dim-1),0,XYZ(dim:end)];
XYZ(dim) = M;
if mod(XYZ(dim+1),M)>0
    error('dimension must be divisible by block size!\n');
end
XYZ(dim+1) = XYZ(dim+1)/M;
Y = reshape(Y,XYZ);
Y = squeeze(trapz(Y,dim))/M;
end

function psc=beta2psc(beta_series)
% convert beta of FIRs to percent signal change. beta_series is a matrix
% whose rows represent trials and columns as time. 
beta_series = bsxfun(@minus,beta_series,mean(beta_series,2));

end