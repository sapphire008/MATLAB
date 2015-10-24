function [V_brain,V_brain_mask] = FSL_Bet_skull_stripping(P,Q,fsldir,varargin)
% Use FSL bet to skull strip and return skull stripped image and mask. 
% This function interfaces bet with more user friendly calling methods in 
% MATLAB. Make sure the function points to the correct FSL bet path. bet is
% a wrapper for the bet2 (a binary file).
%
% [V_brain,V_brain_mask] = FSL_Bet_skull_stripping(P,Q,fsldir,'arg1',...)
%
% Inputs:
%   P: path to input image, before skull stripping. Can be either T1 or T2
%      images
%   Q: output directory
%   fsldir: directory to fsl folder. This directory should directly contain
%           ${FSLDIR}/bin and ${FSLDIR}/etc. Default value can be set in
%           the function.
% 
% Options of current function
%            Function Options        bet2 Options       Default Value
%         'surf_outline'          :      -o        :        false
%         'bin_mask'              :      -m        :        true
%         'skull_img'             :      -s        :        false
%         'no_brain_out'          :      -n        :        false
%         'frac_int_thresh'       :      -f        :        0.65
%         'vert_grad_thresh'      :      -g        :        0
%         'head_rad'              :      -r        :        []
%         'smooth'                :      -w        :        []
%         'cent_gravity'          :      -c        :        []
%         'thresh'                :      -t        :        false
%         'mesh'                  :      -e        :        false
%         'verbose'               :      -v        :        false
% The following options are defaults true for bet2, which must be set one
% by one in bet: 
%         'robust'                :      -R        :        true
%         'clean_eye'             :      -S        :        true
%         'clean_neck'            :      -B        :        true
%         'clean_Z'               :      -Z        :        true
%         'apply_4D'              :      -F        :        true
%         'better_skull'          :      -A        :        false
%         'coregister_T1T2'       :      -A2       :        []
%
% Outputs:
%   V_brain: skull stripped image
%   V_brain_mask: binary mask of skull stripped image
%


[PATHSTR,NAME,~] = fileparts(P);
if nargin<2 || isempty(Q)%if only a path
    Q = fullfile(PATHSTR,[NAME,'_brain.nii']);
elseif ischar(Q)
    [~,~,EXT] = fileparts(Q);%get the extension
    if isempty(EXT)%if only a directory
        Q = fullfile(Q,[NAME,'_brain.nii']);
    end
else
    error('Output must be string!');
end

% path to FSL
if nargin<4 || isempty(fsldir)
    fsldir = '/hsgs/projects/jhyoon1/pkg64/standaloneapps/fsl/5.0.5';
end

% set up option dictionary
opt_name = {'surf_outline','bin_mask','skull_img','no_brain_out',...
    'frac_int_thresh','vert_grad_thresh','head_rad','smooth',...
    'cent_gravity','thresh','mesh','verbose','robust','clean_eye',...
    'clean_neck','clean_Z','apply_4D','better_skull','coregister_T1T2'};
opt_key = {'-o','-m','-s','-n','-f','-g','-r','-w','-c','-t','-e','-v',...
    '-R','-S','-B','-Z','-F','-A','-A2'};
opt_val ={false,true,false,false,0.6,[],[],[],[],false,false,false,...
    true,true,true,true,true,false,[]};
flag = sub_parse_opt_input(varargin,opt_name,opt_key,opt_val);

% convert options to strings
OPT = '';
FN = fieldnames(flag);
for n = 1:length(FN)
    if ~isempty(flag.(FN{n}).val)%value is not empty
        %logical value is not false
        if islogical(flag.(FN{n}).val) && flag.(FN{n}).val
            OPT = [OPT,flag.(FN{n}).key,' ']; %#ok<AGROW>
        elseif ~islogical(flag.(FN{n}).val)%assuming is corresponding input
            % make sure every thing is in string
            if isnumeric(flag.(FN{n}).val)
                flag.(FN{n}).val = num2str(flag.(FN{n}).val);
            end
            OPT = [OPT,flag.(FN{n}).key,' ',flag.(FN{n}).val,' ']; %#ok<AGROW>
        end
    end
end
clearvars opt* FN PATHSTR NAME;
% put a space between argument and options
if ~isempty(OPT)
    OPT = [' ',OPT];
end
% use bet to skull strip
[status,result] = call_fsl(fsldir,[fullfile(fsldir,'bin','bet'),' ',P,' ',Q,OPT],'NIFTI');

% check successful run
if status || numel(result)>=10
    disp(result);
    return;
end

% parse output
V_brain = Q;
if flag.bin_mask.val
    V_brain_mask = regexprep(Q,'\.nii','_mask.nii');
else
    V_brain_mask = [];
end

if flag.no_brain_out.val
    V_brain = [];%the output skull stripped brain does not exist anyway
end
end

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