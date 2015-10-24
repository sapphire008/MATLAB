function Q = FSL_fslmaths_temporal_filter(P,TR,low_pass,high_pass,prefix,fsldir)
% Use FSL's fslmaths to filter time series of data
% 
% Inputs:
%   P: a list of 3D NIFTI files, or a 4D NIFTI file
%   TR: Time Repetition
%   low_pass: low pass cut off time (s), to do only high pass, set to -1.
%             Default value is -1
%   high_pass: high pass cut off time (s), to do only low pass, set to -1.
%              Default is 128
%   prefix (optional): prefix after filtering, default 'p'
%   fsldir: fsl directory. Default can be set in the function
%
% Outpus:
%   Q: a list of filtered 3D NIFTI files, or 4D NIFTI file

% display filtering
fprintf('temporal filtering: ');
if low_pass>0 && high_pass >0
    fprintf('band pass %.3fHz ~ %.3fHz\n',1/low_pass, 1/high_pass);
elseif low_pass>0 && high_pass <=0
    fprintf('low pass %.3fHz\n',1/low_pass)
elseif low_pass<=0 && high_pass>0
    fprintf('high pass %.3fHz\n',1/high_pass);
else
    error('Unrecognized filter frequency\n');
end
% parse inputs
if nargin<6 || isempty(fsldir)
    fsldir = '/hsgs/projects/jhyoon1/pkg64/standaloneapps/fsl/5.0.5/';
end
% Default no low pass filter
if nargin<3 || isempty(low_pass)
    low_pass = -1;
end
% Default high pass filter 128 seconds
if nargin<4 || isempty(high_pass)
    high_pass = 128;
end
% if nargin<5
%     mask = [];
% end
if nargin<5 || (~ischar(prefix) && isempty(prefix))
    prefix = 'p';
end
% in case input is 3D, fslmaths require 4D image
if (iscellstr(P) && length(P)>1) || (ischar(P) && size(P,1)>1)
    V = use_fslmerge_3D(P,TR,true,fsldir);
else% otherwise, assume it is already 4D image
    V = P;
end
% find directories and names
if strcmpi(V((end-2):end),'.gz')
    [PATHSTR,NAME,~] = fileparts(V(1:end-3));
else
    [PATHSTR,NAME,~] = fileparts(V);
end
Q = fullfile(PATHSTR,[NAME,'_tmp_filtered_4D.nii.gz']);
% operator for fslmaths filtering
OPR = sprintf(' -bptf %.3f %.3f ',low_pass/TR, high_pass/TR);
% use fslmaths to filter: result is 4D
[status,result] = call_fsl(fsldir,[fullfile(fsldir,'bin','fslmaths'),' ',V,OPR,Q]);
% split result 4D
[PATHSTR,NAME,EXT] = cellfun(@fileparts,cellstr(P),'un',0);
save_names = cellfun(@(x,y) [prefix,x,y],NAME,EXT,'un',0);
save_path = PATHSTR{1};
Q = use_fslsplit_4D(Q,save_path,save_names,true,fsldir);
end

%% subroutines
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