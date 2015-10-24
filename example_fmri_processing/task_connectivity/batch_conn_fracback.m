clc;
addmatlabpkg('conn');
addspm8;
addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/task_connectivity/;
func_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/subjects/funcs/';
struct_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/structural/';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR3/';
cov_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/movement/frac_back/';
behav_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/behav/';
mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/timeseries_Connectivity_conn/sources/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/timeseries_Connectivity_conn/';

func_target = '2sresample_rra*.nii';
blocks = {'block1','block2','block3'};
struct_target = '*_mprage_structural.nii';
ROI_target = {'*_TR3_SNleft.nii','*_TR3_STNleft.nii'};
ROI_names = {'SNleft','STNleft'};
cov_target = '*.txt';
behav_target = 'block(\d*)_vectors.mat';
bin_mask_target = 'resample_r*_average_TR3_brain_mask.nii';
grey_mask_target = 'c1resample_*_average_TR3.nii';
white_mask_target = 'c2resample_*_average_TR3.nii';
csf_mask_target = 'c3resample_*_average_TR3.nii';

% subjects = {'JY_052413_haldol','MM_051013_haldol',...
%     'MP021_051713','MP022_051713',...
%     'MP023_052013','MP024_052913','MP026_062613','MP027_062713',...
%     'MP028_062813','MP029_070213','MP030_070313',...
%     'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
%     'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
%     'MP123_061713','MP124_062113','MP125_072413'};
% subjects = {'MP020_050613'};
subjects = {'MP025_061013'};

% flags
flag.TR = 3;
flag.filter = [1/128,Inf];
flag.detrend = true;
flag.despike = true;
flag.conn_type = 2;
flag.ana_type = 2;
flag.acq = 1;
flag.weight = 2;
flag.num = 1;
flag.proc_order = {'Setup','Preprocessing','Analysis'};
flag.done_order = [1,1,1];
flag.overwrite_order = [1,1,1];


%% 
for s = 1:length(subjects)
    % make job folder
    eval(['!mkdir -p ',fullfile(save_dir,subjects{s})]);
    
    % display and store progress
    subj = subjects{s};
    diary(fullfile(save_dir,subj,[subj,'_',date,'_connectivity.txt']));
    disp(subj);
    
    % functional
    P = cell(1,length(blocks));
    for b = 1:length(blocks)
        disp('unarchiving ...');
        cwd = pwd;
        cd(fullfile(func_dir,subj,blocks{b}));
        eval(['!tar -zxf ',char(SearchFiles(fullfile(func_dir,subj,blocks{b}),'2sresample*.nii.tgz'))]);
        P{b} = char(SearchFiles(fullfile(func_dir,subj,blocks{b}),func_target));
        cd(cwd);
    end
    
    % structural
    S = char(SearchFiles(struct_dir,regexprep(struct_target,'\*',['*',subj,'*'])));
    
    %Binary mask
    M.Bin.files = char(SearchFiles(mask_dir,regexprep(bin_mask_target,'\*',['*',subj,'*'])));
    M.Bin.res = 3;
    
    %Tissue mask
    M.Grey.files = SearchFiles(mask_dir,regexprep(grey_mask_target,'\*',['*',subj,'*']));
    M.Grey.dimensions = 1;
    M.Grey.cutoff = 1;
    M.White.files = SearchFiles(mask_dir,regexprep(white_mask_target,'\*',['*',subj,'*']));
    M.White.dimensions = 16;
    M.White.cutoff = 6;
    M.CSF.files = SearchFiles(mask_dir,regexprep(csf_mask_target,'\*',['*',subj,'*']));
    M.CSF.dimensions = 16;
    M.CSF.cutoff = 6;
    
    % ROI
    ROI.names = ROI_names;
    for r = 1:length(ROI_target)
        ROI.files{r} = char(SearchFiles(ROI_dir,regexprep(ROI_target{r},'\*',['*',subj,'*'])));
    end
    
    % covariates
    R.names = {'movement'};
    R.files{1}{1} = SearchFiles(cov_dir,regexprep(cov_target,'\*',['*',subj,'*']));% one covariates, one subject, n sessions
    R.dimensions = {1};
    R.deriv = {0};
    clear tmp;
    
    % behave vectors
    V = SearchFiles(fullfile(behav_dir,subj),behav_target);
    
    % save directory
    save_conn = fullfile(save_dir,subj,['conn_',subj,'.mat']);
    
    % get batch
    BATCH = native_connectivity(P,S,M,ROI,R,V,save_conn,'TR',flag.TR,...
        'filter',flag.filter,'detrend',flag.detrend,'despike',flag.despike,...
        'conn_type',flag.conn_type,'ana_type',flag.ana_type,'num',flag.num,...
        'overwrite',flag.overwrite_order,'done',flag.done_order);
    
    % save batch
    save(fullfile(save_dir,subj,[subj,'_setup.mat']),'subj','BATCH','P',...
        'S','M','R','ROI','save_conn','flag');
    
    % run batch
    conn_batch(BATCH);
    
    % remove the source, since it has been archived
    for b = 1:length(blocks)
        cellfun(@delete,cellstr(P{b}));
    end
    
    diary off;
end