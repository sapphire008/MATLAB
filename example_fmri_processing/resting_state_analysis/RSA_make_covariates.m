function RSA_make_covariates(subject_func_dir, subjects, movement_dir, ...
    cov_mask_dir, cov_mask_list, predictor_mask_dir, predictor_mask_list,...
    save_dir, save_name, pca_reduce, separate_predictor, centered)
% make model covariates
% addspm8('NoConflicts');addmatlabpkg('NIFTI');
% addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/resting_state_analysis/');
% subject_func_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/subjects/funcs/';
% movement_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/movement/RestingState/';
% cov_mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR3/';
% cov_mask_list = {'*TR3_mask.nii'};%
% predictor_mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR3/';
% predictor_mask_list = {'*TR3_SNleft.nii', '*TR3_STNleft.nii'};
% save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/model_covariates/';
% save_name = {'SNleft_pca_move_globalnorm.mat','STNleft_pca_move_globalnorm.mat'};
% subjects = {'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
%     'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
%     'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
%     'MP030_070313','MP031_071813','MP032_071013',...
%     'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
%     'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
%     'MP123_061713','MP124_062113','MP125_072413'};

if nargin<10
    pca_reduce = 99;
end
if nargin<11 || isempty(centered)
    separate_predictor = 1;
end
if nargin<12 || isempty(centered)
    centered = true;
end

for s = 1:length(subjects)
    % display progress
    disp(subjects{s});
    % import movement covariates
    tmp_path = dir(fullfile(movement_dir,[subjects{s},'*.txt']));
    % skip if cannot find movement file
    if isempty(tmp_path)
        fprintf('Movement file does not exist: %s\n',subjects{s});
        continue;
    end
    originalR = importdata(fullfile(movement_dir, tmp_path.name));
    % get a list of subject func files
    tmp_path = dir(fullfile(subject_func_dir,subjects{s},'2sresample_*.nii'));
    if isempty(tmp_path)
        fprintf('Func file does not exist: %s\n',subjects{s});
        continue;
    end
    P = char(cellfun(@(x) fullfile(subject_func_dir, subjects{s}, x),{tmp_path.name},'un',0));
    % extract time series of each covariant mask
    for m = 1:length(cov_mask_list)
        tmp_path = dir(fullfile(cov_mask_dir, [subjects{s},cov_mask_list{m}]));
        if isempty(tmp_path)
            fprintf('Mask file does not exist: %s, %s\n',subjects{s},cov_mask_list{m});
            continue;
        elseif length(tmp_path)>1
            fprintf('Multiple mask files: %s, %s\n',subjects{s},cov_mask_list{m});
            continue;
        end
        originalR = [originalR,RSA_ROI_timeseries(P,fullfile(cov_mask_dir,tmp_path.name))];
    end
    % PCA separate the covariates
    if ~isempty(pca_reduce) && pca_reduce>0
        [~, SCORE, ~, ~, EXPLAINED] = pca(originalR,'Centered',centered);
        originalR = SCORE(:,1:find(cumsum(EXPLAINED)>pca_reduce,1));% cut off 99% variance explaination power
    end
    % extract time series of each predictor mask
    for m = 1:length(predictor_mask_list)
        if (separate_predictor) || (~separate_predictor && m==1)
            R = originalR;
        end
        tmp_path = dir(fullfile(predictor_mask_dir, [subjects{s},predictor_mask_list{m}]));
        if isempty(tmp_path)
            fprintf('Mask file does not exist: %s, %s\n',subjects{s},predictor_mask_list{m});
            continue;
        elseif length(tmp_path)>1
            fprintf('Multiple mask files: %s, %s\n',subjects{s},predictor_mask_list{m});
            continue;
        end
        R = [R,RSA_ROI_timeseries(P,fullfile(predictor_mask_dir,tmp_path.name),'zeromean',centered)];
        if separate_predictor
            save(fullfile(save_dir,[subjects{s},'_',save_name{m}]),'R');
        end
    end
    if ~separate_predictor
        save(fullfile(save_dir,[subjects{s},'_',save_name]),'R');
    end
    
    clear R tmp_path P;
end
end

% GLMs = {'GLM_SNleft_move_globalnorm','GLM_SNleft_pca_move_globalnorm',...
%     'GLM_STNleft_move_globalnorm','GLM_STNleft_pca_move_globalnorm'};
% for n = 1:length(GLMs)
%     for s = 1:length(subjects)
%         eval(['!mkdir -p ', fullfile(pwd,GLMs{n},subjects{s})]);
%     end
% end






