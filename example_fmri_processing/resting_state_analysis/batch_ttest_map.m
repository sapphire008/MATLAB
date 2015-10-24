%addmatlabpkg('spm8','no_conflict',1);
%addmatlabpkg('NIFTI','no_conflict',1);
clear all;clc;
base_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/analysis/Seeded_Correlation_Maps/normalized_EPI_template_space/';
save_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/analysis/Seeded_Correlation_Maps/nEPI_ttest_map/';
target_file = '_2s_Pearson_R_map.nii';
ROIs = {'_TR3_SNleft','_TR3_STNleft','_TR3_RNleft','_TR3_CC','_TR3_CSF'};

C = {'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP033_071213','MP034_072213'};
SZ = {'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};


for r = 1:length(ROIs)
    disp(ROIs{r}(2:end));
    % get a list of files for current ROI
    P = dir(fullfile(base_dir,['*',ROIs{r},target_file]));
    P = cellfun(@(x) fullfile(base_dir,x),{P.name},'un',0);
    % get subjects from each group
    P1 = cellfun(@(x) regexp(P,x),C,'un',0);
    P1 = cellfun(@(x) find(~cellfun(@isempty,x)),P1);
    P1 = char(P(P1));% controls
    P2 = cellfun(@(x) regexp(P,x),SZ,'un',0);
    P2 = cellfun(@(x) find(~cellfun(@isempty,x)),P2);
    P2 = char(P(P2));% patients
    % get save names
    T_name = fullfile(save_dir,['MP_RestingState',ROIs{r},'_EPI_corr_t_value_map_C_SZ_left.nii']);
    P_name = fullfile(save_dir,['MP_RestingState',ROIs{r},'_EPI_corr_p_value_map_C_SZ_left.nii']);
    
    % calculate the map
    RSA_ttest(P1,P2,T_name,P_name,[],'left');
        
end

