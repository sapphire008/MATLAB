function [V,Vo] = spm_4D_subset(P,subset,Q)
% Get a subset of 4D images using SPM's function.
%
%   V = spm_4D_subset(P,subset,Q);
%   
% Inputs:
%   P: full path of the file, or loaded file handle using spm_vol
%   subset: logical array with 1s to keep and 0s to discard. Can also input
%           as indices to keep (if positive) or to discard (if negative);
%           positive indices and negative indices cannot coexist!
%   Q: full save path of the new file. Warning: Default is to overwrite!

if nargin<1
    help spm_4D_subset;
end
if nargin<2 || isempty(subset)
    warning('''subset'' argument is required. No changes made\n');
    return;
end
% parse input image
if ischar(P)
    [~,~,EXT] = fileparts(P);
    if strncmpi(EXT,'.gz',3)
        P = char(gunzip(P));%gzipped 4D files
    end
    V = spm_vol(P);
    if nargin<3 || isempty(Q)
        Q = P;
    end
elseif isstruct(P) && isfield(P,'private') && isa(P.private,'nifti')
    V = P;clear P;
    if nargin<3 || isempty(Q)
        Q = V.fname;
    end
else
    error('Unrecognized image input\n');
end
% parse subset argument
if islogical(subset) && numel(subset)<numel(V)
    error('subset (logical) does not have the same length with the number of input volumes\n');
elseif any(subset<0) && any(subset>0)
    error('subset cannot have both positive and negative indices\n');
elseif any(subset<0)
    tmp = subset;
    subset = true(1,numel(V));
    subset(-tmp) = false;
    clear tmp;
elseif any(subset>0)
    tmp = subset;
    subset = false(1,numel(V));
    subset(tmp) = true;
    clear tmp;
else
    error('Unrecognized subset input\n');
end

% split all the files
V = spm_file_split(V);
% get only a subset of the files
Vo = V(subset);
% write out the 4D files again
Vo = spm_file_merge(Vo,Q);
% delete all the splitted files
cellfun(@delete,{V.fname});
end