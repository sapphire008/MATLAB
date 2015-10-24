function [jobfiles,Q] = fMRI_preprocessing(base_dir,subject,Tasks,Mode,Dirs,varargin)
% Preprocessing of fMRI data. 
%
% [jobfiles, Q] = fMRI_preprocessing(base_dir,subejct,tasks,Mode,task_order)
%
% Assuming the follwoing data structure
%   functional images:
%       {base_dir}/{tasks_name}/{Dirs.func}/{subject}/{block#}
%   job_files to save:
%       {base_dir}/{Dirs.jobs.preproc}/{'jobfile.mat'}
%   movement files to move to:
%       {base_Dir}/{Dirs.movement}/{tasks_name}
%
% Inputs:
%
%   base_dir: directory where the project is
%
%   subject: subject ID (character array)
%
%   Tasks: a structure array that contains task information. Keep the
%          order of the input of each field in the order of tasks 
%          administered. This is important when spatial
%          realigning all the tasks by concatenation (see Mode).
%          The strucutre has the fields below:
%       .name: task name
%       .blocks: select block numbers for each task. If empty, will process
%                all the blocks with corresponding parameters. By default,
%                the function search for up to 8 blocks, but will also work
%                with tasks without block strcutures (input as 0).
%       .TR: task TR
%       .numslices: number of slices per stack
%       .numstacks: number of multiplex. If 1, treated as regular EPI, if
%               greater than 1, treated as multiplex
%       .slicemode: slice acquisition order; either 'interleaved' or 
%               'sequential'. Leaving  this field blankd will use default
%               value 'interleaved'
%       .positionmode: ['h2f'|'f2h'] slice numbering direction; either head 
%                 to foot, 'h2f' (default), or foot to head 'f2h'
%       .acqorder: ['ascend'|'descend'] slice acquisition direction.
%           'ascend': 1:1:numslices (default)
%           'descend': numslices:-1:1
%       .oddfirst: whether or not odd number slice is the first. Only
%               relevant when specifying slicemode as 'interleaved'. 
%               Leaving this field blankd will use default value
%               0: even first
%               1: odd first (default)
%               2: depends on number of slice, if even, start with even; 
%                  if odd, start with odd
%       .type: names of the types of images of different parameters. This
%              should correspond to the folder names inside the [Dirs.roi]
%              directory
%
%       For instance:
%           Tasks.name = {'frac_back','stop_signal','RestingState','mid','mid','4POP','RestingState'};
%           Tasks.blocks = {1:3,1:2,1,1:2,3:4,1:4,2};%select blocks to process
%           Tasks.TR = [3,2,3,2,2,2,2];
%           Tasks.numslices = [41,25,41,25,30,25,30];
%           Tasks.numstacks = [1,1,1,1,2,1,2];
%           Tasks.tasks.slicemode = {'i','i','i','i','i','i','i'};%acquisition order, either i for interleaved and s for sequential
%           Tasks.positionmode = {'h2f','h2f','h2f','h2f','f2h','h2f','f2h'};%acquisition direction
%           Tasks.acqmode = {'a','a','a','a','a','a','a'};
%           Tasks.oddfirst = num2cell(1*ones(1,7));
%           Tasks.type = {'TR3','TR2','TR3','TR2','mux','TR2','mux'}
%
%   Mode (optional): ['separated'|'concatenated'|'all'|'category']:
%           'separated': do alignment separately
%           'concatenated': concatednate all tasks. see 'task_order' for
%                   specifying the concatenation order
%           'all': do separated estimation first, then coregister all 
%                   images to a template specified in 'ref' parameter
%           'category': (Default) First do separted estimation to get 
%                   movement parameters, then spatial realign the images 
%                   with the same TR, numslices, and numstacks. Then, take
%                   an aveage for images of the same parameters. Finally, 
%                   coregister all images into a template specified in 
%                   'ref' parameter
%
%   Dirs(optional): structure that maps the dirctory of the corresponding 
%                   folders relative to the base_dir. See directory 
%                   structure assumption above. Dirs has the following
%                   fields:
%           .func: Default 'subejects/funcs'
%           .movement: Default 'movement'
%           .jobs.preproc: Default 'jobfiles/preproc'
%
% Additional Parameters
%
%   'block_prefix' (optiona): default 'block', i.e. searching for 'block1', 
%                   'block2', etc. Can be changed to, for example, 'run', 
%                   so that the function search for 'run1','run2', etc
%   'ref': Required for inter-task regitration! reference image for 
%          inter-task registration when selecting 'all' or 'category' Mode
%
%   'verbose': [true|false] print detailed messages. Default is false.
%
% Output:
%
%   jobfiles: paths to resulting jobfiles
%   Q: files found and processed
%
%
% Edward Cui: May 10, 2014
%

DEBUG = false;% print more info
DEBUG_spatial_realign  = false; %bypass running the slice timing
DEBUG_concat_realign = false;% bypass both slice timing and separate estimation
% sanity check for Tasks information
if range(cellfun(@(x) numel(Tasks.(x)),{'name','TR','numslices','numstacks'}))>0
    error('Not all fields in Tasks input has equal length!');
end
% Parse inputs
%parse varargin and other defaults
flag = parse_varargin(varargin,{'slicemode','interleaved'},...
    {'positionmode','h2f'},{'acqorder','ascending'},{'oddfirst',1},...
    {'block_prefix','block'},{'verbose',false},{'ref',''});
%check reference image when using 'all' or 'category' mode of registration
if any(strcmpi({'all','category'},Mode))
    if isempty(flag.ref)
        error('''ref'' parameter cannot be empty when selecting %s Mode\n',Mode);
    elseif ~exist(flag.ref,'file')
        error('specified reference image \n   %s\ndoes not exist!\n',flag.ref);
    end
end
if nargin<4 ||isempty(Mode),Mode = 'category';end
if nargin<5 ||isempty(Dirs)
    Dirs.funcs = 'subjects/funcs';
    Dirs.movement = 'movement';
    Dirs.jobs.preproc = 'jobfiles/preproc';
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
% report progress
fprintf('%s\n',subject);
% print task order
if flag.verbose
    cellfun(@(x,y) fprintf('Task %d: %s\n',x,char(y)),...
        num2cell(1:length(Tasks.name)),Tasks.name,'un',0);
end
jobfiles = [];
%% PART I: Slice Timing
% place holder for all the jobs to be run for current subject
BATCH = [];
% place holding for output files
Q = cell(size(Blocks));
% if any mux, record slice order
if any(Tasks.numstacks>1),Tasks.sliceorder = cell(1,length(Tasks.numstacks));end
% for each task
for t = 1:length(Tasks.name)
    % calcualte slice order
    switch_var({'slicemode','positionmode','acqorder','oddfirst'},Tasks,flag,t);
    sliceorder = slice_order_calculator(Tasks.numslices(t),...
        Tasks.numstacks(t),slicemode,positionmode,acqorder,oddfirst);
    % definitely save a copy of the slice order for mux
    if Tasks.numstacks(t)>1,Tasks.sliceorder{t} = sliceorder;end
    % only for regular sequence
    if Tasks.numstacks(t)==1
        % modify slice timing correction
        matlabbatch{1,1}.spm.temporal.st.nslices = Tasks.numslices(t);
        matlabbatch{1,1}.spm.temporal.st.ta = Tasks.TR(t)-(Tasks.TR(t)/Tasks.numslices(t));
        matlabbatch{1,1}.spm.temporal.st.so = sliceorder;
        matlabbatch{1,1}.spm.temporal.st.tr = Tasks.TR(t);
        matlabbatch{1,1}.spm.temporal.st.refslice = sliceorder(:,1);
        matlabbatch{1,1}.spm.temporal.st.prefix = 'a';
    end
    
    % Specifying scans for each block
    for b = 1:length(Blocks(t,:))
        if strcmpi(Blocks{t,b},'empty'),continue;end
        % get current path
        PATH = fullfile(base_dir,Tasks.name{t},Dirs.funcs,subject,Blocks{t,b});
        % get a list of files to be processed
        [P,N] = SearchFiles(PATH,'0*.nii');
        % parse output files
        Q{t,b} = cellfun(@(x) fullfile(PATH,['a',x]),N,'un',0)';
        Q{t,b} = Q{t,b}(:);
        clear N;
        % check if empty
        if isempty(P)
            if flag.verbose && DEBUG,fprintf('%s is empty! Skipped. \n',PATH);end
            continue;
        end
        % slice timing based on type of input data
        switch Tasks.numstacks(t)
            case 1
                % slice timing files
                matlabbatch{1,1}.spm.temporal.st.scans{b} = cellstr(P);
            otherwise
                if flag.verbose
                    fprintf('Multiplex slice timing\nmux slice order ...\n');
                    disp(sliceorder);
                end
                %requires modified spm_slice_timing function for multiplex
                if ~DEBUG_spatial_realign && ~DEBUG_concat_realign
                    spm_slice_timing_mux(char(P),sliceorder,sliceorder(:,1)',...
                        Tasks.TR(t)/Tasks.numslices(t)*ones(1,2),'a');%%%%##bypass
                end
        end
        clear PATH;
    end %block
    % put in matlabbatch files for later run
    if exist('matlabbatch','var') && ~isempty(matlabbatch) && ...
            isfield(matlabbatch{1}.spm.temporal.st,'scans') && ...
            ~isempty(matlabbatch{1}.spm.temporal.st.scans)
        matlabbatch{1,1}.spm.temporal.st.scans = ...
                    matlabbatch{1,1}.spm.temporal.st.scans(~cellfun(...
                    @isempty,matlabbatch{1,1}.spm.temporal.st.scans));
        BATCH = [BATCH,matlabbatch];clear matlabbatch;
    end
end %task
% save and run all the jobs
if ~DEBUG_spatial_realign && ~DEBUG_concat_realign
    jobfiles = [jobfiles,{run_job_files(BATCH,base_dir,subject,Dirs,...
        '_preproc_slicetime.mat')}];%%%%##bypass
    if any(Tasks.numstacks>1)
        save(fullfile(base_dir,Dirs.jobs.preproc,[subject,'_mux_slice_order.mat']),'Tasks');
    end
end

%% PART II: Spatial Realignment
BATCH = [];
switch Mode
    case {'separated'}
        clear matlabbatch;
        matlabbatch = SPM_realign_estwrite();
        for t = 1:length(Tasks.name)
            % get rid of empty tasks
            matlabbatch{1}.spm.spatial.realign.estwrite.data = Q(t,find(~cellfun(@isempty,Q(t,:))));
            if ~isempty(matlabbatch{1}.spm.spatial.realign.estwrite.data)
                BATCH = [BATCH,matlabbatch];
            end
        end
        % save and run all the jobs
        jobfiles = [jobfiles,{run_job_files(BATCH,base_dir,subject,Dirs,'_preproc_sep_realign_estwrite.mat')}];
        clear BATCH;
        % move all the movement files to the designated folders
        relocate_movement_parameter_files(base_dir,subject,Tasks,Blocks,Dirs,flag.verbose&DEBUG);
    case {'concatenated'}
        clear matlabbatch;
        matlabbatch = SPM_realign_estwrite();
        % organize list of directories
        V = Q';V = V(:);V = V(~cellfun(@isempty,V'));
        matlabbatch{1, 1}.spm.spatial.realign.estimate.data = V(:);
        % save and run job
        jobfiles = [jobfiles,{run_job_files(matlabbatch,base_dir,subject,Dirs,'_preproc_concat_realign_estwrite.mat')}];
        clear V matlabbatch;
        % move all the movement files to designated folders
        relocate_movement_parameter_files(base_dir,subject,Tasks,Blocks,Dirs,flag.verbose&DEBUG);
    case {'all','category'}
        if ~DEBUG_concat_realign
            % do separated spatial realignment to get the movement parameters
            clear matlabbatch;
            matlabbatch = SPM_realign_estimate();
            for t = 1:length(Tasks.name)
                % get rid of empty runs
                matlabbatch{1}.spm.spatial.realign.estimate.data = Q(t,find(~cellfun(@isempty,Q(t,:))));
                if ~isempty(matlabbatch{1}.spm.spatial.realign.estimate.data)
                    BATCH = [BATCH,matlabbatch];
                end
            end
            % save and run all the jobs
            jobfiles = [jobfiles,{run_job_files(BATCH,base_dir,subject,Dirs,'_preproc_sep_realign_est.mat')}];
            clear BATCH; BATCH = [];
            % move all the movement files to the designated folders
            relocate_movement_parameter_files(base_dir,subject,Tasks,Blocks,Dirs,flag.verbose&DEBUG);
        end
        switch Mode
            case {'all'}
                % coregister everything
                clear matlabbatch;
                matlabbatch = SPM_coreg_estwrite();
                % organize list of directories
                if isempty(flag.ref),error('reference image cannot be empty!');end
                matlabbatch{1, 1}.spm.spatial.coreg.estwrite.ref = {flag.ref};
                clear V;
                for t = 1:length(Tasks.name)
                    clear V;
                    V = Q(t,find(~cellfun(@isempty,Q(t,:))));
                    if isempty(V),continue;end
                    V = cellstr(char(cellfun(@char,V,'un',0)));
                    matlabbatch{1, 1}.spm.spatial.coreg.estwrite.source = V(1);
                    matlabbatch{1, 1}.spm.spatial.coreg.estwrite.other = V(2:end);%cellstr
                    BATCH = [BATCH,matlabbatch];
                end
                jobfiles = [jobfiles,{run_job_files(BATCH,base_dir,subject,Dirs,'_preproc_concat_coreg_estwrite.mat')}];
                clear matlabbatch BATCH;
            case {'category'}
                % get categories of the tasks
                IND = get_tasks_of_same_acq_params(Tasks);
                clear matlabbatch; BATCH = [];
                for c = 1:length(unique(IND))
                    % get list of images
                    V = Q(find(IND==c),:)';
                    V = V(~cellfun(@isempty,V(:)));
                    if isempty(V),continue;end
                    % parse average and coregistration inputs
                    W = cellstr(char(cellfun(@char,cellfun(@(x) add_prefix(x,'r'),V,'un',0),'un',0)));
                    % get average images name
                    group = Tasks.type{find(IND==c,1)};
                    average_fname = fullfile(base_dir,Dirs.rois,group,[subject,'_average_',group,'.nii']);
                    % initialize matlabbatch object
                    matlabbatch = [SPM_realign_estwrite(),SPM_image_calculator(W,average_fname,'same'),SPM_coreg_estimate()];
                    %spatial realign the images with same acquisition parameters
                    matlabbatch{1, 1}.spm.spatial.realign.estwrite.data = V;
                    %coregister to the reference
                    matlabbatch{1, 3}.spm.spatial.coreg.estimate.eoptions.sep = [4,2,1];
                    matlabbatch{1, 3}.spm.spatial.coreg.estimate.ref = {flag.ref};
                    matlabbatch{1, 3}.spm.spatial.coreg.estimate.source = {average_fname};
                    matlabbatch{1, 3}.spm.spatial.coreg.estimate.other = W;
                    BATCH = [BATCH,matlabbatch];
                    clear V W group average_fname;
                end
                % save and run job file
                jobfiles = [jobfiles,{run_job_files(BATCH,base_dir,subject,Dirs,'_preproc_category_concat.mat')}];
                clear matlabbatch;
                % save average only
                matlabbatch = BATCH(2:3:end);
                save(fullfile(base_dir,Dirs.jobs.average,[subject,'_average.mat']),'matlabbatch');
                clear matlabbatch BATCH;
        end
end
% add the prefix before returning
Q(~cellfun(@isempty,Q)) = cellfun(@(x) add_prefix(x,'r'),Q(~cellfun(@isempty,Q)),'un',0);

end
%% run jobfiles
function jobfile = run_job_files(matlabbatch,base_dir,subject,Dirs,suffix)
jobfile = fullfile(base_dir,Dirs.jobs.preproc,[subject,suffix]);
fprintf('saving job file %s ...\n',jobfile);
save(jobfile,'matlabbatch');
spm_jobman('run',matlabbatch);
end

%% find tasks of the same acquisition parameters
function IND = get_tasks_of_same_acq_params(Tasks)
% get index of tasks with the same TR, numslices, and numstacks.
[~,~,IND_TR] = unique(Tasks.TR);
[~,~,IND_numslices] = unique(Tasks.numslices);
[~,~,IND_numstacks] = unique(Tasks.numstacks);
[~,~,IND] = unique([IND_TR(:),IND_numslices(:),IND_numstacks(:)],'rows');
end
%% add prefix
function S = add_prefix(S,prefix)
[PATHS,NAME,EXT] = cellfun(@fileparts,S,'un',0);
S = cellfun(@(x,y,z) fullfile(x,[prefix,y,z]),PATHS,NAME,EXT,'un',0);
end
%% relocate movement files
function relocate_movement_parameter_files(base_dir,subject,Tasks,Blocks,Dirs,verbose)
if verbose,disp('relocating movement files ...');end
for t = 1:length(Tasks.name)
    for b = 1:length(Blocks(t,:))
        if strcmpi(Blocks{t,b},'empty'),continue;end
        [P,V] = SearchFiles(fullfile(base_dir,Tasks.name{t},...
            Dirs.funcs,subject,Blocks{t,b}),'*.txt');
        if isempty(P)
            if verbose
                fprintf('%s does not have movement files!\n',...
                    fullfile(base_dir,Tasks.name,Dirs.funcs,subject,Blocks{t,b}));
            end
            continue;
        end
        eval(['!cp ',char(P),' ',fullfile(base_dir,Dirs.movement,Tasks.name{t},...
            [subject,'_',Tasks.name{t},'_',Blocks{t,b},'_',char(V)])]);
    end
end
end

%% set different variables to caller
function switch_var(field_names,Tasks,flag,t)
for n = 1:length(field_names)
    if isfield(Tasks,field_names{n})
        out_var = Tasks.(field_names{n}){t};
    else
        out_var = flag.(field_names{n});
    end
    assignin('caller',field_names{n},out_var);
end
end

%% spatial estimate and write
function matlabbatch = SPM_realign_estwrite()
matlabbatch{1, 1}.spm.spatial.realign.estwrite.data = [];%cellstr
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.quality = 0.900;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.fwhm=5;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.wrap = [0,0,0];
matlabbatch{1, 1}.spm.spatial.realign.estwrite.eoptions.weight='';
matlabbatch{1, 1}.spm.spatial.realign.estwrite.roptions.which=[2,1];
matlabbatch{1, 1}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.roptions.wrap = [0,0,0];
matlabbatch{1, 1}.spm.spatial.realign.estwrite.roptions.mask = 0;
matlabbatch{1, 1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
end
%% spatial estimate
function matlabbatch = SPM_realign_estimate()
matlabbatch{1, 1}.spm.spatial.realign.estimate.data = [];%cellstr
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.quality = 0.9000;
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.sep = 4;
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.fwhm=5;
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.rtm=0;%register to first
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.interp=2;
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.wrap=[0,0,0];
matlabbatch{1, 1}.spm.spatial.realign.estimate.eoptions.weight='';
end

%% spatial write
function matlabbatch = SPM_realign_write()
matlabbatch{1, 1}.spm.spatial.realign.write.data = [];
matlabbatch{1, 1}.spm.spatial.realign.write.roptions.which=[2,1];
matlabbatch{1, 1}.spm.spatial.realign.write.roptions.interp=4;
matlabbatch{1, 1}.spm.spatial.realign.write.roptions.wrap=[0,0,0];
matlabbatch{1, 1}.spm.spatial.realign.write.roptions.mask = 0;% no masking
matlabbatch{1, 1}.spm.spatial.realign.write.roptions.prefix = 'r';
end

%% coreg estimate and write
function matlabbatch = SPM_coreg_estwrite()
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.ref = [];%cellstr
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.source = [];%cellstr
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.other = [];%cellstr
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';%normalized mutual information
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.eoptions.sep = [4,2];
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.0200000000000000,...
    0.0200000000000000,0.0200000000000000,0.00100000000000000,...
    0.00100000000000000,0.00100000000000000,0.0100000000000000,...
    0.0100000000000000,0.0100000000000000,0.00100000000000000,...
    0.00100000000000000,0.00100000000000000];
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7,7];
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.roptions.wrap = [0,0,0];
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{1, 1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
end

%% coreg estimate
function matlabbatch = SPM_coreg_estimate()
matlabbatch{1, 1}.spm.spatial.coreg.estimate.ref = [];%cellstr
matlabbatch{1, 1}.spm.spatial.coreg.estimate.source = [];%cellstr
matlabbatch{1, 1}.spm.spatial.coreg.estimate.other = [];%cellstr
matlabbatch{1, 1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';%normalized mutual information
matlabbatch{1, 1}.spm.spatial.coreg.estimate.eoptions.sep = [4,2];
matlabbatch{1, 1}.spm.spatial.coreg.estimate.eoptions.tol = [0.0200000000000000,...
    0.0200000000000000,0.0200000000000000,0.00100000000000000,...
    0.00100000000000000,0.00100000000000000,0.0100000000000000,...
    0.0100000000000000,0.0100000000000000,0.00100000000000000,...
    0.00100000000000000,0.00100000000000000];
matlabbatch{1, 1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7,7];
end

%% coreg write
function matlabbatch = SPM_coreg_write()
matlabbatch{1 ,1}.spm.spatial.coreg.write.ref = [];%cellstr
matlabbatch{1 ,1}.spm.spatial.coreg.write.source = [];%cellstr
matlabbatch{1 ,1}.spm.spatial.coreg.write.roptions.interp = 4;
matlabbatch{1 ,1}.spm.spatial.coreg.write.roptions.wrap = [0,0,0];
matlabbatch{1 ,1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1 ,1}.spm.spatial.coreg.write.roptions.prefix = 'r';
end

%% image calculator
function matlabbatch = SPM_image_calculator(P,fname,dt)
matlabbatch{1}.spm.util.imcalc.input = cellstr(P);
[outdir,output,ext] = spm_fileparts(fname);
matlabbatch{1}.spm.util.imcalc.output = [output,ext];
matlabbatch{1}.spm.util.imcalc.outdir = cellstr(outdir);
 % parse expression
f = sprintf('i%d+',1:numel(cellstr(P)));
f = ['(',f(1:end-1),')/',num2str(numel(cellstr(P)))];
matlabbatch{1}.spm.util.imcalc.expression = f;
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
% parse data type
if nargin>2 && ischar(dt) && strcmpi(dt,'same')
    tmp = spm_vol(matlabbatch{1}.spm.util.imcalc.input{1});
    dt = tmp.dt(1);
    clear tmp;
else
    dt = 4;
end
matlabbatch{1}.spm.util.imcalc.options.dtype = dt;
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

%% calculate slice order 
function seq = slice_order_calculator(numslices,numstacks,slicemode,positionmode,acqorder,oddfirst)
% Calcualte slice acquisition order
% seq = slice_order_calculator(numslices(t),numstacks,slicemode,positionmode,oddfirst);
% 
% Inputs:
%   numslices(t): number of slices
%   numstacks (optional): if multiplex, input a number greater than 1
%   slicemode (optional): order slices are acquired
%       'interleaved' (default)
%       'sequential'
%   positionmode(optional): the way slices are labeled
%       'f2h': foot to head (default)
%       'h2f': head to foot
%   acqorder (optional): slice acquisition order
%       'ascending': 1:1:numslices
%       'descending': numslices:-1:1
%   oddfirst (optional): whether or not odd number slice is the first. Only
%                       relevant when specifying slicemode as 'interleaved'
%       0: even first
%       1: odd first (default)
%       2: depends on number of slice, if even, start with even; if odd, 
%          start with odd

% parse optional inputs
if nargin<2 || isempty(numstacks) || numstacks<1
    numstacks = 1;
end
if nargin<3 || isempty(slicemode)
    slicemode = 'interleaved';
end
if strncmpi(slicemode,'s',1),slicemode = 'sequential';...
elseif strncmpi(slicemode,'i',1),slicemode = 'interleaved';end
if nargin<4 || isempty(positionmode)
    positionmode = 'f2h';
end
if strncmpi(positionmode,'f',1),positionmode = 'f2h';...
elseif strncmpi(positionmode,'h',1),positionmode = 'h2f';end
if nargin<5 || isempty(acqorder)
    acqorder = 'ascending';
end
if strncmpi(acqorder,'a',1),acqorder = 'ascending';...
elseif strncmpi(acqorder,'d',1),acqorder = 'descending';end
if nargin<6 || isempty(oddfirst)
    oddfirst = 1;
end

% slice acquisition order
switch slicemode
    case 'sequential'
        seq = 1:1:numslices;
    case 'interleaved'
        switch oddfirst
            case 0 %even first
                if ~strcmpi(positionmode,'h2f')
                    seq = [2:2:numslices, 1:2:numslices];
                else
                    seq = [1:2:numslices, 2:2:numslices];
                end
            case 2 %according to number of slices.
                %If even, start with even, if odd start with odd, unless in
                %'h2f' mode, keep as odd
                if mod(numslices,2) == 0 && ~strcmpi(positionmode,'h2f')
                    seq = [2:2:numslices, 1:2:numslices];
                else% even
                    seq = [1:2:numslices, 2:2:numslices];
                end
            otherwise %odd first, default
                seq = [1:2:numslices, 2:2:numslices];
        end
    otherwise
        error('unrecognized slice mode input');
end
% change slice order according to position mode (way to label slices)

switch positionmode
    case 'f2h' % foot to head, default
    case 'h2f' % head to foot, reverse the sequence order
        seq = numslices - seq + 1;
end
% change slice order according to acquisition mode (actual order of
% transversing the slices)

switch acqorder
    case 'ascending'
    case 'descending'
        seq = numslices - seq + 1;
end

% for the case with multiplex/multiplane acquisition
if numstacks > 1
    seq = bsxfun(@plus,max(seq(:))*(0:(numstacks-1))',seq);
end
end

%% Search Files
function [P,N] = SearchFiles(Path,Target)
% Routine to search for files with certain characteristic names. It does
% not search recursively. However, the function can search under multiple
% layers of sub-directories, when specifying Target variable in the format 
% *match1*/*match2*. Regular expression (regexp) is allowed.
%
% [P, N] = searchfiles(Path, Target)
%
% Inputs:
%       Path: path to search files in
%       Target: target file format, accept wildcards
% 
% Outputs:
%       P: cellstr of full paths of files found
%       N: cellstr of names (without the path) of files found

% get a list of target directories and subdirectories
original_targets = regexp(Target,'/','split');
% remove regular expression
counter = zeros(1,numel(original_targets));
targets = original_targets;
for n = 1:length(targets)
    while true
        x = regexp(targets{n},'('); y = regexp(targets{n},')');
        if isempty(x) || isempty(y),break;end
        targets{n} = strrep(targets{n},targets{n}(x(1):y(1)),'*');
        counter(n) = counter(n)+1;
        if numel(counter)>1000,error('maximum iteration exceeded!');end
        pause(0.01);
    end
end
% addively add the result directories to the output
P = cellstr(Path);
for t = 1:length(targets)
    try
        % get the list of directories
        [P,N] = cellfun(@dir_tree,P,repmat(targets(t),size(P)),'un',0);
        % unwrap the directories
        P = unwrap_cellstr(P);
        N = unwrap_cellstr(N);
        if counter(t)>0
            P = P(~cellfun(@isempty,regexp(N,original_targets{t})));
            N = N(~cellfun(@isempty,regexp(N,original_targets{t})));
        end
    catch ERR
        error('Cannot find the specified files\n');
    end
end
end

function [V,N] = dir_tree(P,T)
X = dir(fullfile(P,T));
if isempty(X)
    V = {};
    N = {};
    return;
end
N = {X.name};
clear X;
V = cellfun(@(x) fullfile(P,x),N,'un',0);
end

function C_out = unwrap_cellstr(C)
C_out = [];
for n = 1:length(C)
    if ischar(C{n})
        C_out = [C_out,C(n)];
    elseif iscellstr(C{n})
        C_out = [C_out,C{n}];
    else
        C_out = [C_out,C{n}];
    end
end
% check if everything is cellstr now
TEST = cellfun(@iscellstr,C_out);
if any(TEST)
    C_out = unwrap_cellstr(C_out);
end
end