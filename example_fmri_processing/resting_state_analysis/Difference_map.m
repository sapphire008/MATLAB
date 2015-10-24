% calculate difference between ROI maps
base_dir = '/nfs/jong_exp/midbrain_pilots/RestingState/analysis/Seeded_Correlation_Maps/native_space/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP033_071213','MP034_072213','MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};

target_file = '_2s_ZScore_map.nii';
positive_rois = {'_TR3_SNleft','_TR3_STNleft'};
negative_rois = repmat({{'_TR3_RNleft','_TR3_CC','_TR3_CSF'}},1,length(positive_rois));

for s = 1:length(subjects)
    for r = 1:length(positive_rois)
        % load positives
        K = load_untouch_nii(fullfile(base_dir,[subjects{s},positive_rois{r},target_file]));
        % load negatives
        N = zeros(size(K.img));
        for kk = 1:length(negative_rois{r})
            tmp = load_untouch_nii(fullfile(base_dir,[subjects{s},negative_rois{r}{kk},target_file]));
            N = N+tmp.img;
            clear tmp;
        end
        
        K.img = K.img-(N/length(negative_rois{r}));
        K = rmfield(K,'untouch');
        save_nii(K,fullfile(base_dir,[subjects{s},positive_rois{r},'_diff_map',target_file]));
    end
end
