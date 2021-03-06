% top level directory for subject beta images
subjectpath = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/trialwiseGLM/';
% directory of native space mask
mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR2/';
ROI_ext = {'_TR2_SNleft.nii','_TR2_STNleft.nii'};
% write resulte to
pathstr = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/RissmanConnectivity/';
% cell array of subject ID's
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
% Cue information
Events = {{'Cue_gain5','bf(1)'},{'Cue_gain1','bf(1)'},{'Cue_gain0','bf(1)'},...
    {'Cue_lose0','bf(1)'},{'Cue_lose1','bf(1)'},{'Cue_lose5','bf(1)'}};
% Apply Trim? 1 for yes 0 for no
trim = 0;
%set threshold for ROI data - values below the threshold are not included
%in the ROI
threshold = 0;
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/RissmanConnectivity/;
addspm8;
for n = 1:length(subjects)
    disp(subjects{n});
    %find location fo SPM file
    SPM_loc = [subjectpath,subjects{n},'/SPM.mat'];
    load(SPM_loc);
    for r = 1:length(ROI_ext)
        % the seed image - must be in the same space as beta images
        Seed_mask = fullfile(mask_dir, [subjects{n},ROI_ext{r}]);
        for k = 1:length(Events);
            [Cout, SE] = beta_series_correlation_nomars(SPM,Seed_mask,Events{k},trim,threshold);
            
            [foo,roiLabel,ext] = fileparts(Seed_mask);
            roiLabel = regexprep(roiLabel,subjects{n},'');
            % output R correlation results to image
            %corr_file = fullfile(pathstr,[subjects{n},'_Rcorr_',roiLabel,'_',Events{k}{1},'.nii']);
            %writeCorrelationImage(Cout,corr_file, SPM.xVol);
            
            % output R correlation results to image
            corr_file = fullfile(pathstr,[subjects{n},'_R2Z',roiLabel,'_',Events{k}{1},'.nii']);
            writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);
            
            % output Z correlation results to image
            corr_file = fullfile(pathstr,[subjects{n},'_Z_test',roiLabel,'_',Events{k}{1},'.nii']);
            writeCorrelationImage((atanh(Cout)/SE),corr_file, SPM.xVol);
        end
    end
end



subjectpath = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/trialwiseGLM_all_phases/';
pathstr = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/RissmanConnectivity_all_phases/';

for n = 1:length(subjects)
    disp(subjects{n});
    %find location fo SPM file
    SPM_loc = [subjectpath,subjects{n},'/SPM.mat'];
    load(SPM_loc);
    for r = 1:length(ROI_ext)
        % the seed image - must be in the same space as beta images
        Seed_mask = fullfile(mask_dir, [subjects{n},ROI_ext{r}]);
        for k = 1:length(Events);
            [Cout, SE] = beta_series_correlation_nomars(SPM,Seed_mask,Events{k},trim,threshold);
            
            [foo,roiLabel,ext] = fileparts(Seed_mask);
            roiLabel = regexprep(roiLabel,subjects{n},'');
            % output R correlation results to image
            %corr_file = fullfile(pathstr,[subjects{n},'_Rcorr_',roiLabel,'_',Events{k}{1},'.nii']);
            %writeCorrelationImage(Cout,corr_file, SPM.xVol);
            
            % output R correlation results to image
            corr_file = fullfile(pathstr,[subjects{n},'_R2Z',roiLabel,'_',Events{k}{1},'.nii']);
            writeCorrelationImage(atanh(Cout),corr_file, SPM.xVol);
            
            % output Z correlation results to image
            corr_file = fullfile(pathstr,[subjects{n},'_Z_test',roiLabel,'_',Events{k}{1},'.nii']);
            writeCorrelationImage((atanh(Cout)/SE),corr_file, SPM.xVol);
        end
    end
end