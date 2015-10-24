%addmatlabpkg('spm8','no_conflict',1);
%addmatlabpkg('NIFTI','no_conflict',1);
clear all;clc;
base_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/subjects/funcs/';
save_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/analysis/Seeded_Correlation_Maps/';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/';
Mask_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/';

target_file = '2sresample_*.nii';
Name_Appendix = '_2s_Pearson_R_map.nii';
ROIs = {'_TR3_RNleft.nii','_TR3_CC.nii','_TR3_CSF.nii'};
target_mask = '_average_TR3_mask.nii';

% subjects = {'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
%     'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
%     'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
%     'MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
%     'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
%     'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
%     'MP124_062113','MP125_072413'};
subjects = {'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
    'MP022_051713','MP023_052013','MP024_052913','MP033_071213',...
    'MP034_072213','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};


% ROI = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/MP021_051713_TR3_SNleft.nii';
% P_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/subjects/funcs/MP021_051713/';
% P=dir([P_dir,'2sresample_*.nii']);
% P=cellfun(@(x) [P_dir,x],{P.name},'un',0);
% P=char(P);
% Mask = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/MP021_051713_average_TR3_mask.nii';
% save_name = '/nfs/jong_exp/midbrain_pilots/scripts/resting_state_analysis/corr_V.nii';


for s = 1:length(subjects)
    % report progress
    disp(subjects{s});
    % get a list of file for current subject
    P = dir(fullfile(base_dir,subjects{s},target_file));
    P=cellfun(@(x) fullfile(base_dir,subjects{s},x),{P.name},'un',0);
    P=char(P);
    % get mask for current subject
    Mask = fullfile(Mask_dir,[subjects{s},target_mask]);
    % for each ROI
    for r = 1:length(ROIs)
        % get current ROI
        ROI = fullfile(ROI_dir,[subjects{s},ROIs{r}]);
        % get save_name
        save_name = fullfile(save_dir,[subjects{s},regexprep(ROIs{r},'.nii',Name_Appendix)]);
        % do the map
        [V_out,K] = RSA_seed_based_correlation(P,ROI,save_name,Mask);
        
        % convert to z score here
        V_zscore_out = V_out;
        V_zscore_out.fname = fullfile(save_dir,[subjects{s},regexprep(ROIs{r},'.nii','_2s_ZScore_map.nii')]);%change the save directory and file name
        V_zscore_out = spm_create_vol(V_zscore_out);%create the file
        V_zscore_out = spm_write_vol(V_zscore_out,atanh(K));
        clear ROI save_name V_out K;
    end
    clear P Mask;
end