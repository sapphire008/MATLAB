function Q = FSL_4D_subset(P,subset,Q,fsldir)
% Get a subset of 4D images using FSL's function fslroi.
%
%   V = FSL_4D_subset(P,subset,Q,fsldir);
%   
% Inputs:
%   P: full path of the file, or loaded file handle using spm_vol
%   subset: logical array with 1s to keep and 0s to discard. Can also input
%           as indices to keep (if positive) or to discard (if negative);
%           positive indices and negative indices cannot coexist! Index
%           starts at 1.
%   Q: (optional) full save path of the new file. Warning: Default is to 
%       overwrite!
%   fsldir:(optional) FSL directory. Default can be set within the script
%
% Output:
%   V: full path of the output 4D image

if ~nargin
    help FSL_4D_subset
end
if nargin<2 || isempty(subset)
    warning('''subset'' argument is required. No changes made\n');
    return;
end
if nargin<3 || isempty(Q)
   Q = P;
end
Q = regexprep(Q,'.gz','');%remove .gz extension
if nargin<4 || isempty(fsldir)
    fsldir = '/hsgs/projects/jhyoon1/pkg64/standaloneapps/fsl/5.0.5/';
end

% get the number of volumes in the 4D image
[~,numvols] = call_fsl(fsldir,[fullfile(fsldir,'bin','fslnvols'),' ',P]);
numvols = regexp(numvols,'\n','split');
numvols=numvols(~cellfun(@isempty,numvols));
numvols = str2num(numvols{end});
% parse subset argument
if islogical(subset) && numel(subset)<numvols
    error('subset (logical) does not have the same length with the number of input volumes\n');
elseif any(subset<0) && any(subset>0)
    error('subset cannot have both positive and negative indices\n');
elseif any(subset<0)
    tmp = subset;
    subset = true(1,numvols);
    subset(-tmp) = false;
    clear tmp;
elseif any(subset>0)
    tmp = subset;
    subset = false(1,numvols);
    subset(tmp) = true;
    clear tmp;
else
    error('Unrecognized subset input\n');
end

% separate subset into continuous blocks
subset = get_continuous_blocks(find(subset)-1);

% get the subset of 4D images
% fslroi <input> <output> <tmin> <tsize>
if length(subset)>1
    [PATHSTR,NAME,EXT] = fileparts(Q);
    S = cellfun(@(x) sprintf('%s_%d%s',fullfile(PATHSTR,NAME),x,EXT),...
        num2cell(1:numel(subset)),'un',0);
    clear PATHSTR NAME EXT;
    for k = 1:length(subset)
        % separating into different blocks first
        [status,result]=call_fsl(fsldir,[fullfile(fsldir,'bin','fslroi'),...
            ' ',P,' ',S{k},' ',sprintf('%d ',subset{k})],'NIFTI');
        % check successful run
        if status || numel(result)>=10
            disp(result);
            return;
        end
    end
    % merge the 4D files
    [status,result] = call_fsl(fsldir,...
        [fullfile(fsldir,'bin','fslmerge'),' -t ',Q,' ',...
        cell2mat(cellfun(@(x) [x,' '],S,'un',0))],'NIFTI');
    % check successful run
    if status || numel(result)>=10
        disp(result);
        return;
    else
        cellfun(@delete,S);%remove intermediate
    end
else
    [status,result]=call_fsl(fsldir,[fullfile(fsldir,'bin','fslroi'),...
        ' ',P,' ',Q,' ',sprintf('%d ',subset{:})],'NIFTI');
    % check successful run
    if status || numel(result)>=10
        disp(result);
        return;
    end
end
end

%% sub-routines
function C = get_continuous_blocks(X)
% separting a vector of integers into continuous blocks
X = unique(X);% sort the vector
IND = [1,find(diff(X)>1)+1,numel(X)+1];
C = cell(1,numel(IND)-1);
for m = 1:length(C)
    C{m} = [X(IND(m)),IND(m+1)-IND(m)];
end
end

function [status,result] = call_fsl(fsldir,cmd,fsloutputtype)
% [status, output] = call_fsl(fsldir,cmd)
% 
% Wrapper around calls to FSL binaries
% clears LD_LIBRARY_PATH and ensures
% the FSL envrionment variables have been
% set up
% Debian/Ubuntu users should uncomment as
% indicated. 
%   
% Adapted from the FSL's built-in matlab wrapper. Not working on PC.

%fsldir=getenv('FSLDIR');
setenv('FSLDIR',fsldir);
if nargin<3 || isempty(fsloutputtype) || ~any(ismember(...
        {'NIFTI','NIFTI_PAIR','NIFTI_GZ','NIFTI_PAIR_GZ'},fsloutputtype))
    try
        fsloutputtype=getenv('FSLOUTPUTTYPE');
        if isempty(fsloutputtype)
            fsloutputtype = 'NIFTI_GZ';
        end
    catch
        fsloutputtype = 'NIFTI_GZ';
    end
end

%check if the system is linux
ISLINUX = strncmpi(computer,'GLNX',4);

% Debian/Ubuntu
if ISLINUX%is linux
    if any(~cellfun(@isempty,regexpi(evalc('!uname -a'),{'ubuntu','debian'})))%is ubuntu/debian
        fsllibdir=sprintf('%s/%s', fsldir, 'bin');
    end
end

% set environment variables according to system
if ismac
    dylibpath=getenv('DYLD_LIBRARY_PATH');
    setenv('DYLD_LIBRARY_PATH');%empty the dynamic library path
elseif ISLINUX || isunix
    ldlibpath=getenv('LD_LIBRARY_PATH');
    setenv('LD_LIBRARY_PATH');%assign empty value
    % Debian/Ubuntu
    if any(~cellfun(@isempty,regexpi(evalc('!uname -a'),{'ubuntu','debian'})))%is ubuntu/debian
        setenv('LD_LIBRARY_PATH',fsllibdir);
    end
% elseif ispc% assume ipc
%     dlllibpath=getenv('PATH');
%     setenv('PATH');%empty the dynamic library path
else
    error('unrecognized operating system');
end

%run bash config script
command = sprintf('/bin/sh -c ''. ${FSLDIR}/etc/fslconf/fsl.sh''');
system(command);
% run fsl command
setenv('FSLOUTPUTTYPE',fsloutputtype);%set outputtype environment
command = sprintf('/bin/sh -c '' %s''',cmd);
[status,result] = system(command);

%change the library path back
if ismac
  setenv('DYLD_LIBRARY_PATH', dylibpath);
elseif ISLINUX || isunix
  setenv('LD_LIBRARY_PATH', ldlibpath);
% elseif ispc % assume ispc
%     setenv('PATH',dlllibpath);
end
end