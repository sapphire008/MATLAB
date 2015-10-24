%batch separate ROIs
% subjects = {'JY_052413_haldol','MM_051013_haldol',...
%     'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
%     'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
%     'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
%     'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
%     'MP036_072913','MP037_080613',...
%     'MP120_060513','MP121_060713','MP122_061213',...
%     'MP123_061713','MP124_062113','MP125_072413'};

base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/';
subjects = {'M3039_CNI_052714','M3128_CNI_060314','M3129_CNI_060814'};
ROI_ext = {'SNleft','STNleft','RNleft','VTAleft','VTAleft_extended'};
ROI_color = {'Red','Yellow','Magenta','Violet','Azul'};
source_type = {'TR2','TR3'};
target_source = '*ACPC_SNleft_STNleft_RNleft_VTAleft.nii';

addmatlabpkg('NIFTI');
addmatlabpkg('fMRI_pipeline');
addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/search_area_ROI/');
for s = 2%1:length(subjects)
    for t = 1:length(source_type)
        disp(subjects{s});
        clear current_source ROI;
        current_source = char(SearchFiles(fullfile(...
            base_dir,source_type{t}),[subjects{s},target_source]));
        
        if isempty(current_source)
            disp(['Skipped ',subjects{s}, ' | ', source_type{t}]);
            continue;
        elseif size(current_source,1)>1
            disp(['Multiple ROI ',subjects{s}, ' | ', source_type{t}]);
            continue;
        end
        if isempty(source_type{t})
            with_underline = '';
        else
            with_underline = '_';
        end
        ROI = separating_ITKSNAP_ROI(current_source,ROI_ext,ROI_color,...
            fullfile(base_dir,source_type{t},[subjects{s},with_underline,source_type{t},'.nii']));
        for r = 1:length(ROI)
            disp(['name: ', ROI(r).cluster_name]);
            disp(['size: ', num2str(length(ROI(r).ind))]);
        end
    end
end