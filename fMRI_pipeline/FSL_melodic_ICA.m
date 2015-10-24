function Q = FSL_melodic_ICA(P,output_dir,prefix,fsldir)
% FSL interface of MELODIC Independent Componenet Analysis of fMRI data
% 
% Q = FSL_melodic_ICA(P,output_dir,prefix,fsldir,'opt_1',val_1)
% 
% Inputs:
%   P: a list (cellstr or char) of file names of 3D .nii file, or a name
%      for a 4D .nii/.nii.gz file
%   output_dir: output directory
%   prefix (optional): prefix of IC removed images. Default 'i'
%   fsldir: fsl directory. Default can be set in the function
%
% Output:
%   Q: a list of IC removed 3D images, or a path to IC removed 4D images

% in case input is 3D, fslmaths require 4D image
if (iscellstr(P) && length(P)>1) || (ischar(P) && size(P,1)>1)
    V = use_fslmerge_3D(P,TR,true,fsldir);
else% otherwise, assume it is already 4D image
    V = P;
end

OPT = '';

end

function Q = use_fslmerge_3D(P,TR,remove_source,fsldir)
% fslmaths requires a 4D image. Merge the file
tmp_P = cellstr(P);
[PATHSTR,NAME,~] = fileparts(tmp_P{1});
if length(tmp_P)>1
    tmp_P(1:end-1) = cellfun(@(x) [x,' '],tmp_P(1:end-1),'un',0);
end
tmp_P = cell2mat(tmp_P(:)');
Q = fullfile(PATHSTR,[NAME,'_4D.nii']);
[status,result] = call_fsl(fsldir,...
    [fullfile(fsldir,'bin','fslmerge'),' -tr ',Q,' ',tmp_P,' ',num2str(TR)]);
% delete source
if remove_source
    cellfun(@delete,cellstr(P),'un',0);
end
end

function Q = use_fslsplit_4D(input_4D,save_path,save_names,remove_source,fsldir)
% do splitting
[status,result] = call_fsl(fsldir,...
    [fullfile(fsldir,'bin','fslsplit'),' ',input_4D,' ',fullfile(save_path,'tmp3D_vol_'),' -t']);
% rename the splitted files
M = dir(fullfile(save_path,'tmp3D_vol_*'));%should be in order
M = cellfun(@(x) fullfile(save_path,x),{M.name},'un',0);%tmp file
Q = cellfun(@(x) fullfile(save_path,x),save_names,'un',0);% final output
%char(M)
%char(Q)
for n = 1:length(M)
    % check .gz
    [~,~,EXT] = fileparts(M{n});
    if strcmpi(EXT,'.gz')
        char(gunzip(M{n}));
        tmp = M{n}(1:end-3);
        delete(M{n});
    else
        tmp = M{n};
    end
    % rename
    eval(['!mv ',tmp,' ',Q{n}]);
    clear tmp;
end
if remove_source
    delete(input_4D);
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