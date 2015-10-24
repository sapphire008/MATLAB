function H = FSL_archive_nii(mode,P,Q,fsldir,varargin)
% Use FSL's functions fslmerge and fslsplit to archive NIfTI files
%   [status,result] = FSL_archive_nii(mode,P,Q,fsldir,'arg1',val1,...)
% Inputs:
%   mode: mode of actions:
%           'merge': calling fslmerge to archive files
%           'split': calling fslsplit to decompress files
%
%   P:    source file directory. Either a cellstr of list of files, or its
%         char equivalent
%
%   Q:    (optional) output file(fslmerge)/directory(fslsplit). Default is 
%         the same directory  (and base name) as the first file specified 
%         in P.
%
%   fsldir:(optional) FSL directory. Default can be set within the script
%   
%   'TR':  optional flag for fslmerge when archiving. Set the TR of the 4D
%          image in seconds.
%   'basename': optional flag for fslsplit when splitting. Set a
%               basename to the splitted files and the numbering will
%               appended.
%   'deletesource': optional flag for deleting the source after archiving.
%                   Default is false
% Outpus:
%
%   H: list of files created
%

% Parse inputs
if nargin<1
    help FSL_archive_nii%display help document
end
if isempty(mode)
    error('mode of operation required!\n')
end
P = cellstr(P);
if nargin<3 || isempty(Q)
    [Q,NAME,~] = fileparts(P{1});
    if any(ismember({'merge','archive','compress','fslmergs'},mode))
        Q = fullfile(Q,[NAME,'.nii.gz']);
    end
end
if nargin<4 || isempty(fsldir)
    fsldir = '/hsgs/projects/jhyoon1/pkg64/standaloneapps/fsl/5.0.5/';
end


% call fsl functions based on mode
switch mode
    case {'merge','archive','compress','fslmerge'}
        % parse input files
        ARG = [Q,' '];
        clear NAME;
        for m = 1:length(P)
            ARG = [ARG,P{m},' '];
        end
        % parse optional inputs
        opt_name = {'TR','deletesource'};
        opt_key = {'-tr',''};
        opt_val ={0,false};
        flag = sub_parse_opt_input(varargin,opt_name,opt_key,opt_val);
        if flag.TR.val==0
            ARG = ['-t ',ARG(1:end-1)];
        else
            ARG = [flag.TR.key,' ',ARG,num2str(flag.TR.val)];
        end
        % call fslmerge
        [status,result] = call_fsl(fsldir,[fullfile(fsldir,'bin','fslmerge'),' ',ARG],'NIFTI_GZ');
        % return the list of files
        H = cellstr(Q);% output file list
    case {'split','unarchive','decompress','fslsplit'}
        if (ischar(P) && size(P,1)>1) || (iscellstr(P) && numel(P)>1)
            error('Cannot split more than two files using this function. Use for loop instead\n');
        end
        % get list of file in the current directory
        list_files_before = dir(Q);
        list_files_before = cellfun(@(x) fullfile(Q,x),{list_files_before.name},'un',0);
        opt_name = {'basename','deletesource'};
        opt_key = {'',''};
        opt_val = {'vol',false};
        flag = sub_parse_opt_input(varargin,opt_name,opt_key,opt_val);
        % get output names
        if ischar(flag.basename.val)
            if ~isempty(flag.basename.val)
                ARG = [char(P),' ',fullfile(Q,flag.basename.val)];
            else
                ARG = [char(P),' ',Q,filesep];
            end
        else
            ARG = [char(P),' ',Q,filesep];
        end
        % call fslsplit
        [status,result] = call_fsl(fsldir,[fullfile(fsldir,'bin','fslsplit'),' ',ARG],'NIFTI');
        % get list of file in the after fslsplit
        list_files_after = dir(Q);
        list_files_after = cellfun(@(x) fullfile(Q,x),{list_files_after.name},'un',0);
        % get the list of resulted files
        H = list_files_after(cell2mat(cellfun(@(x) ~ismember(...
            x,list_files_before),list_files_after,'un',0)));
        clear list_files_before list_files_after;
        % rename the output if the numbering starts at 0
        K = regexp(H,fullfile(Q,[flag.basename.val,'(\d*)','.nii']),'tokens');
        K = cellfun(@(x) x{1}{1},K,'un',0);
        if str2num(K{1}) == 0
            K = cellfun(@(x) fullfile(Q,sprintf('%s%04.f.nii',...
                flag.basename.val,str2num(x)+1)),K,'un',0);
            for k = length(K):-1:1
                eval(['!mv ',H{k},' ',K{k}]);
            end
            H = K; 
        end
        clear K;
end
% check successful run
if status || numel(result)>=10
    disp(result);
    return;
end
% delete source
if flag.deletesource.val
    cellfun(@delete,P);
end
end

%% sub-routines
function flag=sub_parse_opt_input(search_varargin_cell,name,key,val)
%convert everything into cell array if single input
if ~iscell(name)
    name={name};
end
if ~iscell(key)
    key = {key};
end
if ~iscell(val)
    val={val};
end

flag=struct();%place holding
for n = 1:length(name)
    % add in key of the dictionary
    flag.(name{n}).key = key{n};
    % parse values
    IND=find(strcmpi(name(n),search_varargin_cell),1);
    if ~isempty(IND)

        flag.(name{n}).val=search_varargin_cell{IND+1};
    else
        flag.(name{n}).val=val{n};
    end
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