%batch extract FIR timecourse
clear;
base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/analysis/FIR/';
type_ROI = 'A1';

switch type_ROI
    case {'SN_STN'}
        ROI_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/TR2/';
        save_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/analysis/MarsBaR_FIR_time_series/SNleft_STNleft/';
        ROI_suffix = {'*_SNleft.nii','*_STNleft.nii'};
        ROI_names = {'_SNleft','_STNleft'};
    case {'A1'}
        ROI_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/analysis/A1_control/';
        save_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/analysis/MarsBaR_FIR_time_series/A1/';
        ROI_suffix = {'_A1left*spmT_0008.img','_A1right*spmT_0008.img'};
        ROI_name = {'_A1left','_A1right'};
end

% subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
%     'MP024_052913','MP025_061013','MP026_062613','MP027_062713',...
%     'MP028_062813','MP029_070213','MP030_070313','MP031_071813',...
%     'MP036_072913','MP037_080613',....
%     'MP032_071013','MP033_071213','MP034_072213','MP035_072613',...
%     'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
%     'MP124_062113','MP125_072413'};

subjects = {'M3039_CNI_052714','M3126_CNI_052314','M3128_CNI_060314','M3129_CNI_060814'};
addspm8;
addmatlabpkg('marsbar');
addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/FIR_model/');


%% time series extraction for each single ROI
for s = 1:length(subjects)
    %display which subject is being processed
    disp(subjects{s});
    clear SPM;
    % load SPM file
    load(fullfile(base_dir,subjects{s},'SPM.mat'));
    % for each ROI
    for r = 1:length(ROI_suffix)
        clear ROI_loc PSC;
        %get ROI location
        ROI_loc = fullfile(ROI_dir,[subjects{s},ROI_suffix{r}]);
        %in case the ROI_suffix contains wildcard
        ROI_loc = dir(ROI_loc);
        ROI_loc = {ROI_loc.name};
        if length(ROI_loc)>1
            error('ROI is not unqiue, check ROI_suffix');
        elseif isempty(ROI_loc)
            error('ROI does not exist.');
        else
            ROI_loc = fullfile(ROI_dir, ROI_loc{1});
        end
        % check to see if ROI is binary
        V = spm_vol(ROI_loc);
        V = unique(double(V.private.dat));
        if numel(V)>2
            error('ROI is not binary\n');
        end
        %get ROI name
        [~,ROI_name,~] = fileparts(ROI_loc);
        %calcaulte FIR percent signal change time course
        %try
        PSC = beta2psc(SPM,ROI_loc, 'marsbar',2,12);
%         catch ME
%             disp(['Error when extracting time seires.'])
%             disp(['Skipped: ', subjects{s}]);
%             continue;
%         end
        %save the result to .csv file
        cell2csv(fullfile(save_dir,[ROI_name,'.csv']),...
            vertcat(PSC.event_type_names,num2cell(PSC.fir_tc_averaged)),...
            ',');
    end
end

%% time series extraction for union ROI
if strcmpi(type_ROI,'A1')
for s = 1:length(subjects)
    %display which subject is being processed
    disp(subjects{s});
    clear SPM;
    % load SPM file
    load(fullfile(base_dir,subjects{s},'SPM.mat'));
    
    % create union ROI
    ROI_IND = cell(1,length(ROI_suffix));
    ROI_size = cell(1,length(ROI_suffix));
    for r = 1:length(ROI_suffix)
        clear ROI_loc PSC tmp;
        %get ROI location
        ROI_loc = fullfile(ROI_dir,[subjects{s},ROI_suffix{r}]);
        %in case the ROI_suffix contains wildcard
        ROI_loc = dir(ROI_loc);
        ROI_loc = {ROI_loc.name};
        if length(ROI_loc)>1
            error('ROI is not unqiue, check ROI_suffix');
        else
            ROI_loc = fullfile(ROI_dir, ROI_loc{1});
        end
        
        % create union ROI
        %have to add nifiti path everytime because some function above
        %remove this path for some reason.
        addmatlabpkg('NIFTI');
        tmp = load_nii(ROI_loc);
        ROI_size{r} = size(tmp.img);
        ROI_IND{r} = find(tmp.img);
    end
    %check if the two ROIs have the same size
    if ROI_size{1} ~= ROI_size{2}
        disp([subjects{s},' ROI map space size not the same, skipped']);
        continue;
    end
    %check if two ROIs are not identical ROIs
    if mean(ROI_IND{1}(:)) == mean(ROI_IND{2}(:))
        disp([subjects{s}, ' ROI overlaps. skipped']);
        continue;
    else
        union_ROI_IND = union(ROI_IND{1},ROI_IND{2});
    end
        

    %write union ROI
    tmp.img = zeros(size(tmp.img),'single');
    tmp.img(union_ROI_IND) = single(1);
    
    %check if there are really discrete ROIs
    [I,~,~] = ind2sub(size(tmp.img),find(tmp.img));
    [~,C,~,~]=kmeans(I,length(ROI_suffix),'Start','cluster',...
        'Distance','sqEuclidean','Replicates',5,'EmptyAction','drop');
    if length(C) ~= length(ROI_suffix) && abs(C(1)-C(2)) < 10
        disp([subjects{s},' does not really have ', ...
            num2str(length(ROI_suffix)), ' ROIs. Check ROI images']);
        disp('Current subject skipped.');
        continue;
    end
    
    % temporarily save the ROI
    save_nii(tmp,fullfile(ROI_dir,'tmp_union_ROI.nii'));
    %calcaulte FIR percent signal change time course
    PSC = beta2psc(SPM,fullfile(ROI_dir,'tmp_union_ROI.nii'), 'marsbar',2,12);
    %remove the temporary union ROI
    eval(['!rm -r ' fullfile(ROI_dir,'tmp_union_ROI.nii')]);
    %save the result to .csv file
    cell2csv(fullfile(save_dir,[subjects{s},'_A1_bilateral.csv']),...
        vertcat(PSC.event_type_names,num2cell(PSC.fir_tc_averaged)),',');
end
end