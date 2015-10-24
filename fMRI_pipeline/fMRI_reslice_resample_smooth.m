function fMRI_reslice_resample_smooth(base_dir,subject,Tasks,average_names,smooth_kernel,Dirs,varargin)
% Further process the images. reslice-->resample-->smooth
%   fMRI_reslice_resample_smooth(base_dir,subject,average_name,smooth_kernel,Dirs,...)
%
% Assuming the follwoing data structure
%   functional images:
%       {base_dir}/{tasks_name}/{Dirs.func}/{subject}/{block#}
%   job_files to save:
%       {base_dir}/{Dirs.jobs.smooth}/{'jobfile.mat'}
%
% Inputs:
%   base_dir: directory where the project is
%
%   subject: subject ID (character array)
%
%   average_names (optional): cellstr of sub-directories where the averages 
%                 are saved under Dirs.rois. Default {'TR2','TR3'}. If no
%                 directory structure under Dirs.rois, input ''
%
%   smooth_kernel: cell array of smoothing kernel to use. Default is
%                  {[2,2,2]}
%
%   Dirs(optional): structure that maps the dirctory of the corresponding 
%                   folders relative to the base_dir. See directory 
%                   structure assumption above. Dirs has the following
%                   fields:   
%               .func: where the functional images to be processed
%               .rois: where the averages files will be saved to
%               .jobs.smooth: where the smooth jobfiles will be saved
%
% Optaionl Parameters
%   
%   'archive': ['all'|'a'|'ra'|'resample'] archive unused images,
%              options include images processed in previous steps. 'all'
%              will archive all these images, otherwise, select images to
%              archive. Default is 'resample'. Input [] for not archiving.
%              Input as a cellstr to archive multiple types of images.
%
%   'block_prefix': default 'block', i.e. searching for 'block1', 'block2',
%                   etc. Can be changed to, for example, 'run', so that the
%                   function search for 'run1','run2', etc
%   'overwrite': [true|false] overwrite images that have been processed
%                previously. Default false
%
% Dependencies: FSL_Bet_skull_stripping which depends on FSL, FileFun, 
% SearchFiles, reslice_nii from Jimmy Shen's NIFTI toolbox, resample_nii 
% which depends on Convert3D from ITK-SNAP, SPM.

flag = parse_varargin(varargin,{'archive','resample'},...
    {'block_prefix','block'},{'overwrite',false});

if nargin<3 || isempty(average_names)
    average_names = {'TR2','TR3'};
elseif ischar(average_names)
    average_names = {average_names};
end
if nargin<4 || isempty(smooth_kernel)
    smooth_kernel = {[2,2,2]};
elseif isnumeric(smooth_kernel) && numel(smooth_kernel)==3
    smooth_kernel = {smooth_kernel};
elseif isnumeric(smooth_kernel) && numel(smooth_kernel)==1
    smooth_kernel = {smooth_kernel*ones(1,3)};
end
if nargin<5 || isempty(Dirs)
    Dirs.funcs = 'subjects/funcs';
    Dirs.rois = 'ROIs';
    Dirs.jobs.smooth = 'jobfiles/smooth'; 
end
% parse block
if ~isfield(Tasks,'blocks') || isempty(Tasks.blocks)
    Blocks = repmat([{''},cellfun(@(x) sprintf([flag.block_prefix,'%d'],x),...
        num2cell(1:8),'un',0)],length(Tasks.name),1);
else
    Blocks = cell(length(Tasks.name),max(cellfun(@length,Tasks.blocks)));
    Blocks(:) = {'empty'};
    for t = 1:numel(Tasks.blocks)
        if all(Tasks.blocks{t} > 0)
            Blocks(t,1:length(Tasks.blocks{t})) = cellfun(@(x) sprintf(...
                [flag.block_prefix,'%d'],x),num2cell(Tasks.blocks{t}),'un',0);
        else
            Blocks(t,1:length(Tasks.blocks{t})) = {''};
        end
    end
end

%add tools for reslice
nifti_package_dir = addmatlabpkg('NIFTI');

% get a list of file to reslice and resample
P = [];
% funcs
for t = 1:length(Tasks.name)
    blocks = Blocks(t,~strcmpi(Blocks(t,:),'empty'));
    for b = 1:length(blocks)
        tmp = SearchFiles(fullfile(base_dir,Tasks.name{t},Dirs.funcs,...
            subject,blocks{b}),'ra*.nii');
        if isempty(tmp)
            continue;
        else
            P = [P;tmp(:)];
        end
        clear tmp;
    end
    clear blocks;
end
% averages
for m = 1:length(average_names)
    % add the average files to the list of files to be resliced and
    % resampled
    P = [P;SearchFiles(fullfile(base_dir,Dirs.rois,average_names{m}),...
        sprintf('%s*%s*.nii',subject,'average'))'];
end

% remove repeats if any
P = unique(P);
% reslice
disp('reslicing and resampling...');
P = FileFun(@reslice_nii,P,[],{'resample_r','front'},false,flag.overwrite,[1,1,1],false);
% resample
%disp('resampling...');
%P = FileFun(@resample_nii,P,[],{'resample_','front'},true,flag.overwrite);

% separating average and non-average images
[~,NAME,~] = cellfun(@fileparts,P,'un',0);
Q = P(~cellfun(@isempty, regexp(NAME,'average')));
P = P(cellfun(@isempty, regexp(NAME,'average')));
% get rid of existing files
clear NAME;
% Do skull stripping for each averaged images
disp('skull stripping...');
cellfun(@(x) FSL_Bet_skull_stripping(x),Q,'un',0);
clear Q;
% load smoothing job file
matlabbatch = SPM_smooth();%initialize jobs
matlabbatch = repmat(matlabbatch,1,numel(smooth_kernel));
for n = 1:numel(smooth_kernel)
    if ~flag.overwrite
        [PATHS,NAME,EXT] = cellfun(@fileparts,P,'un',0);
        tmp_P = cellfun(@(x,y,z) fullfile(x,...
            [sprintf('%ds',smooth_kernel{n}(1)),y,z]),PATHS,NAME,EXT,'un',0);
        tmp_P = P((~cellfun(@exist,tmp_P))>0);
    else
        tmp_P = P(:);
    end
    matlabbatch{n}.spm.spatial.smooth.data = tmp_P(:);
    matlabbatch{n}.spm.spatial.smooth.fwhm = smooth_kernel{n};
    matlabbatch{n}.spm.spatial.smooth.prefix = sprintf('%ds',smooth_kernel{n}(1));
end
% run and save jobs
save(fullfile(base_dir,Dirs.jobs.smooth,[subject,'_smooth.mat']),'matlabbatch');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);
if ~flag.overwrite
    for n = 1:numel(smooth_kernel)
        matlabbatch{n}.spm.spatial.smooth.data = P(:);
    end
    save(fullfile(base_dir,Dirs.jobs.smooth,[subject,'_smooth.mat']),'matlabbatch');
end
clear matlabbatch;

% archive the unused images
if ~isempty(flag.archive)
    FILEPATH = unique(cellfun(@fileparts,P,'un',0));
    disp('archiving unused images ...');
end
if any(strcmpi(flag.archive,'all')),flag.archive = {'resample','a','ra'};end
if any(strcmpi(flag.archive,'resample'))
    archive_images(FILEPATH,'resample_r*.nii','resample_rra.nii.tgz');
end
if any(strcmpi(flag.archive,'a'))
    archive_images(FILEPATH,'a*.nii','a.nii.tgz');
end
if any(strcmpi(flag.archive,'ra'))
    archive_images(FILEPATH,'ra*.nii','ra.nii.tgz');
end
clear P FILEPATH;

% detach NIFTI package for now
rmpath(genpath(nifti_package_dir));
end

%% archive
function result_archive = archive_images(FILEPATH,target,save_name)
FILEPATH = cellstr(FILEPATH);
result_archive = cell(1,length(FILEPATH));
for k = 1:length(FILEPATH)
    files = SearchFiles(FILEPATH{k},target);
    result_archive{k} = fullfile(FILEPATH{k},save_name);
    tar(result_archive{k},files);
    delete(fullfile(FILEPATH{k},target));
end
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

%% smooth
function matlabbatch = SPM_smooth()
matlabbatch{1, 1}.spm.spatial.smooth.data = [];%cellstr
matlabbatch{1, 1}.spm.spatial.smooth.fwhm = [8,8,8];
matlabbatch{1, 1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1, 1}.spm.spatial.smooth.im = 0;
matlabbatch{1, 1}.spm.spatial.smooth.prefix = 's';
end