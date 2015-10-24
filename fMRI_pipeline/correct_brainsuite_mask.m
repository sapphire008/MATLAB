function varargout = correct_brainsuite_mask(Mask_dir,Brain_dir)
% from BrainSuite's skull stripping mask, correct the mask, and create the
% extracted brain
%
% [M,B] = correct_brainsuite_mask(Mask_dir, Brain_dir);
% 
% Inputs:
%   Mask_dir: directory of the mask. If only to create extracted brain,
%             leave this as empty: 
%                   M = correct_brainsuite_mask(Mask_dir)
%   Brain_dir: directory of the brain to be extracted. Must have mask.
%
%
% Outputs:
%   M: corrected mask
%   B: extracted brain

% initialize
B = [];
[M,X] = correct_mask(Mask_dir);

if ~isempty(Brain_dir)
    B = create_brain(Brain_dir,X);
end
varargout = {M,B};
varargout = varargout(~cellfun(@isempty,varargout));
end

function [M,X] = correct_mask(Mask_dir)
if ischar(Mask_dir)
    M = spm_vol(Mask_dir);
elseif isstruct(Mask_dir) && isfield(Mask_dir,'private')
    M = Mask_dir;
else
    error('Unrecognized input Mask_dir');
end
% create corrected mask
X = double(M.private.dat);
X(X>0)=1;%change the value of the mask to 0's and 1's
M.dt = [16,0];%change to float32
M = spm_write_vol(M,X);
end

function B = create_brain(Brain_dir,X)
if ischar(Brain_dir)
    B = spm_vol(Brain_dir);
elseif isstruct(Brain_dir) && isfield(Brain_dir,'private')
    B = Brain_dir;
else
    error('Unrecognized input Brain_dir');
end

% create extracted brain
Y = double(B.private.dat);
Y = Y.*X;%mask out
[PATHS,NAME,EXT] = spm_fileparts(B.fname);
B.fname = fullfile(PATHS,[NAME,'_brain',EXT]);
B = spm_create_vol(B);
B = spm_write_vol(B,Y);
end