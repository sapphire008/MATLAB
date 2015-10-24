%% Aveage all normalized maps
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/AverageMaps/';
job_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/jobfiles/average/';
PIPE_dir = addmatlabpkg('fMRI_pipeline');
subjects = {'JY_052413_haldol','MM_051013_haldol','MP022_051713',...
    'MP023_052013','MP024_052913','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
    'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
    'MP036_072913','MP037_080613','MP120_060513','MP121_060713',...
    'MP123_061713','MP124_062113','MP125_072413','TMS100','TMS200'};
%weight of average, in the order specified in subject
W = [0,0,1,1,1,1,1,1,1,1,1,0.5,1,1,1,1,1,0,0,0,0,0,1,0.5];%control
%W = [0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,1,1,1,1,1,1,0];%patients
%W = [1,1,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0];%haldol

% get a list of files to be averaged
[P,N] = SearchFiles(base_dir,'*0*/conn*0*/resu*/first*/ANALYSIS*/w*.nii');
[N,~,IND] = unique(N);

load(fullfile(PIPE_dir,'jobfiles','average.mat'));
matlabbatch = repmat(matlabbatch,1,numel(unique(IND)));

for m = 1:numel(unique(IND))
    INPUT = P(IND==m);
    %make average expression
    EXPRESSION = '(';
    NEW_INPUT = {};
    count_input = 1;
    for n = 1:length(INPUT)
        % find the weight of current subject of current input
        tmp_W = W(~cellfun(@isempty,cellfun(@(x) regexp(INPUT{n},x),subjects,'un',0)));
        if tmp_W == 0
            %remove this image from the averaging
            continue;
        end
        
        NEW_INPUT{count_input} = INPUT{n};
        EXPRESSION = [EXPRESSION,sprintf('i%d*%.3f+',count_input,tmp_W)];
        count_input = count_input + 1;
    end
    EXPRESSION = EXPRESSION(1:end-1);
    EXPRESSION = [EXPRESSION,')/',num2str(sum(W(:)))];
    %putting in the parameters
    matlabbatch{1,m}.spm.util.imcalc.input = NEW_INPUT(:);
    matlabbatch{1,m}.spm.util.imcalc.output = ['average_',N{m}];
    matlabbatch{1,m}.spm.util.imcalc.outdir{1} = save_dir;
    matlabbatch{1,m}.spm.util.imcalc.expression = EXPRESSION;
end
save(fullfile(job_dir,'Resting_State_average_maps.mat'),'matlabbatch');

spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

%% Generate plots
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/AverageMaps/';
%maps
P = SearchFiles(base_dir,'average*.nii');
%template image
T = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/AverageMaps/wCopy_of_EPI.nii';

for n = 1:length(P)
    activationmap_mosaic(P{n},T,'axial',
end


















































