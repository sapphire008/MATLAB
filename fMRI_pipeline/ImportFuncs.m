function Q = ImportFuncs(raw_list,func_dir,scenario,varargin)
% Map raw files and import them to each individual func folders according
% to source image types. This function depends on a lot of other functions
% and packages, depending on usage. Dependencies may include SPM, FSL,
% and MRICron.
%
% ImportFuncs(raw_list, func_list, scenario, opt1,val1)
%
% Inputs:
%   raw_list: list of raw images. See 'scenario' for input format 
%             requirement
%   func_dir: full path of the func folder to import the images into
%
%   scenario: specify type of raw images:
%       1. 3D dicom files (2D dicoms stacked in the same file).
%          raw_list is a cell array
%       2. 2D dicom files (separate 2D dicoms, each file is one slice).
%         raw_list is the folder that contains all the dicom files
%       3. 4D .nii.gz (3D NIfTI volumes stacked in a single gzip file).
%          raw_list is char/string
%   Options (required under certain scenario):
%       'dicom_tool': for Scenario 1 and 2 only. Type of dicom import tool
%                     to use to convert .dcm to .nii images. Options are:
%           ~ 'spm': make sure to add SPM package before use.
%           ~ 'mricron': use MRICron to import
%           (recommended for 2D dicom import in Scenario 2)
%       'format': '4d', 'spm8'. Options for mricron dicom import.
%                 Default is 'spm8' or 3D volumes.
%       'subset': keep only a subset of imported volumes. For 4D outpus, 
%                 input negative indices to exclude images: e.g. [-1,-2] to
%                 discard the first two images. See also 'subset'
%                 argument in 'FSL_4D_subset' for 4D outputs. For 3D 
%                 outputs, input positive indices to exclude images: e.g.
%                 [1,2] to discard first two images. See also 
%                 'discard_vect' argument 'renumber_files' for 3D outputs.
%       'fsldir': For Scenario 3 only. FSL directory. Set default by 
%                 editing this function
%       'mricrondir': When only selecting mricron to import. Set default by
%                     editing this function
% Output:
%        Q: list of imported files

% parse optional flags
flag = parse_varargin(varargin,{'dicom_tool','spm'},{'format','spm8'},...
    {'format','spm8'},{'subset',[]},...
    {'fsldir','/hsgs/projects/jhyoon1/pkg64/standaloneapps/fsl/5.0.5'},...
    {'mricrondir','/hsgs/projects/jhyoon1/pkg64/standaloneapps/mricron/dcm2nii'});
% make the directory if it does not already exist
if ~exist(func_dir,'dir')
    eval(['!mkdir -p ',func_dir]);
end
% default output type 3D
outtype = 0;%3D
% import the raw images according to scenarios
switch scenario
    case {1,2}%dicoms, use SPM by default, otherwise, use mricron
        % get a list of files present in the present output folder to compare later
        P = dir(func_dir); P = {P.name};
        switch lower(flag.dicom_tool)
            case 'spm'
                matlabbatch = build_SPM_dicom_import_jobfile(raw_list,func_dir);
                spm_jobman('initcfg');
                spm_jobman('run',matlabbatch);
                clear matlabbatch;
            case 'mricron'
                
                dcm2nii_matlab(raw_list, func_dir,flag.format,flag.mricrondir);
                if strcmpi(flag.format,'4d')
                    outtype = 1;%4d
                end  
            otherwise
                error('Unrecognized dicom import method!\n');
        end
        % get the files that are updated from the import
        Q = dir(func_dir);Q = {Q.name};
        Q = Q(cell2mat(cellfun(@(x) ~ismember(x,P),Q,'un',0)));
    case 3
        switch lower(flag.format)
            case 'spm8'%use FSL to split
                Q = FSL_split_nii(raw_list,func_dir,flag.fsldir);
            case '4d'%make symbolic link
                [~,NAME,EXT]=fileparts(raw_list);
                Q = fullfile(func_dir,[NAME,EXT]);
                eval(['!ln -s ',raw_list,' ',fullfile(func_dir,[NAME,EXT])]);
                clear NAME EXT;
            otherwise
                error('Cannot create specified format in Scenario 3\n');
        end
    otherwise
        error('Unrecognized scenario!\n');
end

% organize files
if ~isempty(flag.subset)
    switch outtype
        case 0%separate 3D files
            Q = renumber_files(Q,4,[],1,flag.subset,[]);
        case 1%1 4D file
            Q = FSL_4D_subset(func_dir,flag.subset,[],flag.fsldir);
    end
else%renumber the 3D files
    if ~outtype && scenario~=3
        Q = renumber_files(Q,4,[],1);
    end
end
end

%% SPM's dicom import
function matlabbatch = build_SPM_dicom_import_jobfile(dicom_list,func_dir)
matlabbatch{1,1}.spm.util.data = dicom_list;
matlabbatch{1,1}.spm.util.root = 'flat';
matlabbatch{1,1}.spm.util.outdir = func_dir;
matlabbatch{1,1}.spm.util.convopts.format='.nii';
matlabbatch{1,1}.spm.util.convopts.icedims=0;
end
%% MRICron's dicom import
function [status,result]=dcm2nii_matlab(dicom_folder,output_dir,out_format,dcm2nii_path)
% parse output_dir
output_dir = ['-o ',output_dir,' '];%use specified save_dir
% parse output format
switch out_format
    case '4d'
        out_format = '-4 y ';
    case 'spm8'
        out_format = '-n y -4 n ';
    case 'analyze'
        out_format = '-s y -4 n ';
end
% parse archive (if use .gz format)
archive = '-g n ';%default no archive

% do the conversion
[status,result]=unix([dcm2nii_path,' -v y ',out_format,output_dir,archive,dicom_folder]);
end

%% varargin input
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
%% split 4D files into 3D
function H = FSL_split_nii(P,Q,fsldir,varargin)
% Use FSL's functions fslmerge and fslsplit to archive NIfTI files

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
if status>0,error(result);end
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

%% 3D renumber
function new_file_name=renumber_files(FILES,num_len,target_dir,mode,...
    discard_vect,prefix)
% Auto renumber files by creating symbolic links (default) or completely
% overwrite the original file (can be supplied as an argument)
% parse optional inputs
%       dicard_vect (optional): vector contains which file number to
%                               exclude from renumbering. The numbers will
%                               be kept consecutive. For example, for
%                               original files: {'a','b','c','d','e'}:
%                               If discard_vect = [3], or to discard the 
%                               3rd  file, or file 'c', the numbering will 
%                               become [1,2,3,4], which corresponds to the 
%                               original files {'a','b','d','e'}. Default
%                               empty [], which discards no files
if nargin<2 || isempty(num_len)
    num_len = 4;
end
if nargin<3 || isempty(target_dir)
    target_dir = fileparts(FILES{1});
end
% Default mode symbolic link
if nargin<4 || isempty(mode)
    mode = 'ln -s';
elseif isnumeric(mode)
    switch mode
        case 1
            mode = 'ln -s';
        case 2
            mode = 'mv';
        case 3
            mode = 'cp';
        case 4
            mode = 'cp -al';
    end
end
% default no discarding
if nargin<5
    discard_vect = [];
end
if nargin<6 || isempty(prefix)
    prefix = '';
end

% get a list of files to rename after accounting for discarded files
f_vect = setdiff(1:length(FILES),discard_vect);

% rename files
new_file_name = cell(1,length(f_vect));
for f = 1:length(f_vect)
    [~,~,EXT] = fileparts(FILES{f_vect(f)});
    new_file_name{f} = [prefix,sprintf(['%0',num2str(num_len),'.f'],f),EXT];
    eval(['!' mode, ' ',FILES{f_vect(f)},' ',...
        fullfile(target_dir,new_file_name{f})]);
end
end
%% 4D subset
function Q = FSL_4D_subset(P,subset,Q,fsldir)
% Get a subset of 4D images using FSL's function fslroi.
%   subset: logical array with 1s to keep and 0s to discard. Can also input
%           as indices to keep (if positive) or to discard (if negative);
%           positive indices and negative indices cannot coexist! Index
%           starts at 1.

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

function C = get_continuous_blocks(X)
% separting a vector of integers into continuous blocks
X = unique(X);% sort the vector
IND = [1,find(diff(X)>1)+1,numel(X)+1];
C = cell(1,numel(IND)-1);
for m = 1:length(C)
    C{m} = [X(IND(m)),IND(m+1)-IND(m)];
end
end

%% call FSL functions
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