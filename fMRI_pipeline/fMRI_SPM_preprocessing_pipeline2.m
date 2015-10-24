%addmatlabpkg('dicom_tools');
PIPE_dir = addmatlabpkg('fMRI_pipeline');
%addspm8;
%spm_jobman('initcfg');

base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/';
subjects = {'M3038_CNI_022414'};
tasks = {'RestingState','stop_signal','mid'};
blocks = {{''},{'block1','block2'},{'block1','block2','block3'}};
% list of folders
DIRS.funcs = 'subjects/funcs';
DIRS.movement = 'movement/raw';
DIRS.rois = 'ROIs';
DIRS.jobs.preproc = 'jobfiles/preprocessing';
DIRS.jobs.average = 'jobfiles/average';
DIRS.jobs.smooth = 'jobfiles/smooth';
DIRS.jobs.diary = 'jobfiles/processing_notes';


diary(fullfile(base_dir,DIRS.jobs.diary,['preprocessing',datestr(now,'mm-dd-yyyy_HH-MM-SS'),'.txt']));
for n = 1
% %% renumber files and make 4D movies
% for s = 1:length(subjects)
%     for t= 1:length(tasks)
%         for b = 1:length(blocks{t})
%             PATH = fullfile(base_dir,tasks{t},DIRS.funcs,subjects{s},blocks{t}{b});
%             %renumber_files(fullfile(PATH,'*.nii'));
%             % Search for renumbered files
%             P = SearchFiles(PATH,'0*.nii');
%             % make a 4D movie
%             spm_file_merge(char(P),'4D.nii',0);
%             clear P;
%         end
%     end
% end
%
% %% slice timing
% TR = {2,2,2};%of each task
% numslices = {25,25,25};% per stack of each task 
% numstacks = {3,3,3};%of each task
% type = {'mux','mux','mux'};%of each task: 'reg' | 'mux'
% mode = 'both';%['separated'|'concatenated'|'both'] for spatial realignment
% 
% BATCH = [];
% 
% for s = 1:length(subjects)
%     % report progress
%     fprintf('%s\n',subjects{s});
%     % place holder for all the jobs to be run for current subject
%     BATCH = [];
%     % place holding for output files
%     Q = cell(length(tasks),max(cellfun(@length,blocks)));
%     % for each task
%     for t= 1:length(tasks)
%         % only for regular sequence
%         if strcmpi(type{t},'reg')
%             % load slice timing job template
%             load(fullfile(PIPE_dir,'jobfiles','slicetiming.mat'));
%             % modify slice timing correction
%             matlabbatch{1,1}.spm.temporal.st.nslices = numslices{t};
%             matlabbatch{1,1}.spm.temporal.st.ta = TR{t}-(TR{t}/numslices{t});
%             matlabbatch{1,1}.spm.temporal.st.so = slice_order_calculator(numslices{t});
%             matlabbatch{1,1}.spm.temporal.st.tr = TR{t};
%             matlabbatch{1,1}.spm.temporal.st.refslice = matlabbatch{1,1}.spm.temporal.st.so(:,1);
%             matlabbatch{1,1}.spm.temporal.st.prefix = 'a';
%         end
%         
%         % Specifying scans for each block
%         for b = 1:length(blocks{t})
%             % get current path
%             PATH = fullfile(base_dir,tasks{t},DIRS.funcs,subjects{s},blocks{t}{b});
%             % get a list of files to be processed
%             [P,N] = SearchFiles(PATH,'0*.nii');
%             % parse output files
%             Q{t,b} = cellfun(@(x) fullfile(PATH,['a',x]),N,'un',0);
%             clear N;
%             % check if empty
%             if isempty(P)
%                 fprintf('%s is empty! Skipped. \n',PATH);
%                 continue;
%             end
%             % slice timing based on type of input data
%             switch type{t}
%                 case 'reg'
%                     % slice timing files
%                     matlabbatch{1,1}.spm.temporal.st.scans{b} = cellstr(P);
%                 case 'mux'
%                     sliceorder = slice_order_calculator(numslices{t},numstacks{t});
%                     spm_slice_timing_mux(char(P),sliceorder,sliceorder(:,1)',...
%                         [TR{t}/numslices{t},TR{t}/numslices{t}],'a');
%             end
%             
%             clear PATH;
%         end %block
%         if exist('matlabbatch','var') && ~isempty(matlabbatch)
%             BATCH = [BATCH,matlabbatch];clear matlabbatch;
%         end
%     end %task
%     % if to do 'separated' spatial alignment for each task
%     if any(strcmpi(mode,{'separated','both'}))
%         load(fullfile(PIPE_dir,'jobfiles','spatialrealign.mat'));
%         matlabbatch = repmat(matlabbatch,1,length(tasks));
%         for t = 1:length(tasks)
%             matlabbatch{1, t}.spm.spatial.realign.estwrite.data = Q(t,find(~cellfun(@isempty,Q(t,:))));
%         end
%         BATCH = [BATCH,matlabbatch]; clear matlabbatch;
%     end
%     
%     % save and run all the jobs first
%     matlabbatch = BATCH; clear BATCH;
%     save(fullfile(base_dir,DIRS.jobs.preproc,[subjects{s},'_preproc.mat']),'matlabbatch');
%     spm_jobman('run',matlabbatch);
%     
%     % move all the movement files to the designated folders
%      for t = 1:length(tasks)
%         for b = 1:length(blocks{t})
%             [P,V] = SearchFiles(fullfile(base_dir,tasks{t},...
%                 DIRS.funcs,subjects{s},blocks{t}{b}),'*.txt');
%             eval(['!cp ',char(P),' ',fullfile(base_dir,DIRS.movement,tasks{t},...
%                 [subjects{s},'_',tasks{t},'_',blocks{t}{b},'_',char(V)])]);
%         end
%      end
%     
%      % if to do 'concatenated' spatial alignment for each task
%      if any(strcmpi(mode,{'concatenated','both'}))
%          load(fullfile(PIPE_dir,'jobfiles','spatialrealign.mat'));
%          Q = Q';
%          Q = Q(:);
%          matlabbatch{1, 1}.spm.spatial.realign.estwrite.data = Q(~cellfun(@isempty,Q'));
%          save(fullfile(base_dir,DIRS.jobs.preproc,[subjects{s},'_concat_spatial.mat']),'matlabbatch');
%          spm_jobman('run',matlabbatch);
%      end
% end%subject
% 
end

% %% convert from 4D to 3D after 4D TimeSapce realignment
% for s = 1:length(subjects)
%     for t = 2:length(tasks)
%         for b = 1:length(blocks{t})
%             P = char(SearchFiles(fullfile(base_dir,tasks{t},DIRS.funcs,subjects{s},blocks{t}{b}),'ra*.nii'));
%             if isempty(P)
%                 fprintf('%s,%s,%s isempty, skipped\n',subjects{s},tasks{t},blocks{t}{b});
%                 continue;
%             end
%             FSL_archive_nii('split',P,[],[],'basename','ra');
%             % remove source to avoid conflicts later
%             delete(P);
%         end
%     end
% end
% %% Aveages
% task2include = {{'stop_signal','mid'}};
% average_names = {'stopsignal_mid'};%{'TR2' , 'TR3'}
% spm_jobman('initcfg');
% for s = 1:length(subjects)
%     % load average job file
%     load(fullfile(PIPE_dir,'jobfiles','average.mat'));
%     % repeat to number of tasks to average
%     matlabbatch = repmat(matlabbatch,1,length(task2include));
%     for mm = 1:length(task2include)
%         % find which task matches the target for averaging
%         IND = sort(cell2mat(cellfun(@(x) find(ismember(tasks,x)),task2include{mm},'un',0)));
%         matlabbatch{1, mm}.spm.util.imcalc.input = [];
%         for t = 1:length(IND)%tasks
%             for b = 1:length(blocks{IND(t)})
%                 matlabbatch{1, mm}.spm.util.imcalc.input = ...
%                     [matlabbatch{1, mm}.spm.util.imcalc.input;
%                     SearchFiles(fullfile(base_dir,tasks{IND(t)},...
%                     DIRS.funcs,subjects{s},blocks{IND(t)}{b}),'ra*.nii')'];
%             end
%         end
%         % set other parameters
%         matlabbatch{1, mm}.spm.util.imcalc.outdir = {fullfile(base_dir,DIRS.rois,average_names{mm})};
%         matlabbatch{1, mm}.spm.util.imcalc.output = [subjects{s},'_',average_names{mm},'_average.nii'];
%         EXPRESSION = '(';
%         K = length(matlabbatch{1, mm}.spm.util.imcalc.input);
%         for m = 1:K-1
%             EXPRESSION = [EXPRESSION,sprintf('i%d+',m)];
%         end
%         EXPRESSION = [EXPRESSION,'i',num2str(K),')/',num2str(K)];
%         matlabbatch{1, mm}.spm.util.imcalc.expression = EXPRESSION;
%         clear EXPRESSION;
%     end
%     save(fullfile(base_dir,DIRS.jobs.average,[subjects{s},'_average.mat']),'matlabbatch');
%     spm_jobman('run',matlabbatch);
%     AVG = cellfun(@(x) fullfile(x.spm.util.imcalc.outdir{1},...
%         x.spm.util.imcalc.output),matlabbatch,'un',0);
%     % make a copy of the average files
%     FileFun('sub_copy_files',AVG,[],{'Original_','front'},false,2);
%     clear AVG;
% end
% 
% %% ACPC alignment and reorientation (Pause here, done by visual inspection)
% % should write something that loads the images directly in display, and
% % prompts the user to reorient the images
% disp('ACPC alignment');
% % spm_image('display',IMAGE_PATH);
% % spm_check_registration(IMAGES{:});
% return;
%% reslice, resample, and smooth
average_names = {''};% for each task
smooth_kernel = {[2,2,2]};%for each variant of smoothing

%add tools for reslice
nifti_package_dir = addmatlabpkg('NIFTI');
for s = 1:length(subjects)
    % get a list of file to reslice and resample
    P = [];
    % funcs
    for t = 1:length(tasks)
        for b = 1:length(blocks)
            tmp = SearchFiles(fullfile(base_dir,tasks{t},DIRS.funcs,...
                subjects{s},blocks{b}),'ra*.nii');
            if isempty(tmp)
                continue;
            else
                P = [P;tmp(:)];
            end
            clear tmp;
        end
    end
    % averages
    for m = 1:length(average_names)
        % add the average files to the list of files to be resliced and
        % resampled
        P = [P;SearchFiles(fullfile(base_dir,DIRS.rois,average_names{m}),...
            sprintf('%s*%s*.nii',subjects{s},'average'))];
    end
    
    % remove repeats if any
    P = unique(P);
    % reslice
    disp('reslicing...');
    P = FileFun(@reslice_nii,P,[],{'r','front'},false,[],false);
    % resample
    disp('resampling...');
    P = FileFun(@resample_nii,P,[],{'resample_','front'},true);
    % separating average and non-average images
    [~,NAME,~] = cellfun(@fileparts,P,'un',0);
    Q = P(~cellfun(@isempty, regexp(NAME,'average')));
    P = P(cellfun(@isempty, regexp(NAME,'average')));
    clear NAME;
    % Do skull stripping for each averaged images
    disp('skull stripping...');
    cellfun(@(x) FSL_Bet_skull_stripping(x),Q);
    clear Q;
    % load smoothing job file
    load(fullfile(PIPE_dir,'jobfiles','smoothing.mat'));
    matlabbatch = repmat(matlabbatch,1,numel(smooth_kernel));
    for n = 1:numel(smooth_kernel)
        matlabbatch{n}.spm.spatial.smooth.data = P(:);
        matlabbatch{n}.spm.spatial.smooth.fwhm = smooth_kernel{n};
        matlabbatch{n}.spm.spatial.smooth.prefix = ...
            sprintf('%ds',smooth_kernel{n}(1));
    end
    % save jobs
    save(fullfile(base_dir,DIRS.jobs.smooth,[subjects{s},'_smooth.mat']),'matlabbatch');
    FILEPATH = unique(cellfun(@fileparts,P,'un',0));
    clear P;
    spm_jobman('run',matlabbatch);
    
    % archive the resampled images
    disp('archiving unsmoothed ...');
    for k = 1:length(FILEPATH)
        files = SearchFiles(FILEPATH{k},'resample_r*.nii');
        tar(fullfile(FILEPATH{k},'resample_rra.nii.tgz'),files);
        delete(fullfile(FILEPATH{k},'resample_r*.nii'));
    end
    clear FILEPATH;
end
% detach NIFTI package for now
rmpath(genpath(nifti_package_dir));
