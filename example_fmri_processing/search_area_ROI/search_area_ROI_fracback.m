%Finds the voxel with the maximum T value within a search space ROI%
clear all;
%directory of GLM
subject_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/GLM_combined/';
subjects = {'M3126_CNI_042514'};
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/ROIs/TR3/';
ROI_name = {'_TR3_SNleft','_TR3_STNleft'};
worksheet_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/ROI_peak_T_voxel/';
results_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/ROI_peak_T_voxel/peak_T_ROIs_Nback-null/';
results_dir2 = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/ROI_peak_T_voxel/marked_ROIs_Nback-null/';
results_dir3 = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/frac_back/analysis/ROI_peak_T_voxel/adjacent1_peak_ROIs_Nback-null/';
%spmT = 'spmT_0004';%use which contrast to determine ROI peak T value
target_con_name = 'ZeroBack_OneBack_TwoBack-null';
tolerate_names = '';
%select a color coding for the peak voxel
peak_color = 'Green';
worksheet_header = {'Subject','ROI','Peak_T_Value','Voxel_Locale',...
    'Coord_X','Coord_Y','Coord_Z'};
top_N = 3;%find top N peak voxels
peakAdjacent = 1;%number of adjacent voxels to include
% (peakAdjacent*2+1)^3-1 voxels, including corners, but not voxels outside of
% the ROIs

% ------------------------ DO NOT EDIT BELOW ----------------------------
addspm8('NoConflicts');
addmatlabpkg('NIFTI');
addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/midbrain_Stanford_3T/scripts/search_area_ROI;

%ITK-snap color coding
ColorDictionary = {...
    'ClearLabel', 0;
    'Red',1;
    'Green',2;
    'Blue',3;
    'Yellow',4;
    'Cyan',5;
    'Magenta',6};
ColorDictionary = cell2struct(ColorDictionary(:,2),ColorDictionary(:,1));
worksheet(1,:) = worksheet_header;


%%
for n = 1:length(subjects);
    clear SPM_loc spmT_loc beta_loc CON_IMG IMG_NAME;
    %display subject name
    disp(subjects{n});
    %locate SPM file
    SPM_loc = [subject_dir subjects{n} '/SPM.mat'];
    %load SPM as a variable to MATLAB workspace
    load(SPM_loc);
    %locate spmT file with specified contrast
    [CON_IMG,IMG_NAME]=search_contrasts(SPM,target_con_name,tolerate_names);
    spmT_loc = fullfile(subject_dir,subjects{n},CON_IMG);
    
    %for each ROI
    for r = 1:length(ROI_name)
        clear ROI XYZ t_values maxNum maxIndex coordinate new_roi ...
            native_roi data;
        ROI = char(SearchFiles(ROI_dir,[subjects{n},'*',ROI_name{r},'.nii']));
        XYZ = roi_find_index_no_mat(ROI);
        
        %spmT values%
        t_values = spm_get_data(spmT_loc, XYZ);
        
        %prints out voxel with the maximum value within the search space and
        %prints out the coordinates of that voxel% 
        for ff = 1:top_N
            maxNum = max(t_values);
            maxIndex = find(t_values==maxNum);%can be multiple max
            coordinate = XYZ(:,maxIndex);
            % write information to worksheet
            worksheet{ff+1,1} = subjects{n};
            worksheet{ff+1,2} = [regexprep(ROI_name{r},'([_-]*)',''),'_',num2str(ff)];
            worksheet{ff+1,3} = maxNum;
            worksheet{ff+1,4} = [];
            for mm = 1:length(maxIndex)
                worksheet{ff+1,4} = [worksheet{ff+1,4},PointLocation(coordinate(:,mm),XYZ)];
                if mm<length(maxIndex)
                    worksheet{ff+1,4} = [worksheet{ff+1,4},','];
                end
            end
            worksheet(ff+1,5:7) = num2cell(coordinate);
            t_values = t_values(t_values ~= maxNum);
            
            %peak single voxel ROI
            if ff==1
                new_roi = load_nii(ROI);
                new_roi.img = zeros(size(new_roi.img),'single');
                new_roi.img(coordinate(1,:), coordinate(2,:), coordinate(3,:))=1;
                %save single voxel ROI
                save_nii(new_roi,[results_dir subjects{n} ROI_name{r} '_peakvoxel.nii']);
                clear new_roi;
                
                %locate the peak voxel within the native space of the ROI
                native_roi = load_nii(ROI);
                native_roi.img(coordinate(1,:),coordinate(2,:),coordinate(3,:))=...
                    ColorDictionary.(peak_color);
                save_nii(native_roi,fullfile(results_dir2,[subjects{n},ROI_name{r},'_marked.nii']));
                clear native_roi;
                
                % get peak voxels adjacent
                ind_shift_perms = unique(nchoosek(repmat(...
                    [-1:-1:-peakAdjacent,1:peakAdjacent,0],1,3),3),'rows');
                % get all the adjacent voxel coordinates
                adjXYZ = bsxfun(@plus,ind_shift_perms',coordinate);
                % keep only the voxels within the ROI
                adjXYZ = intersect(XYZ',adjXYZ','rows')';
                new_roi = load_nii(ROI);
                new_roi.img = zeros(size(new_roi.img),'single');
                new_roi.img(coordinate(1,:),coordinate(2,:),coordinate(3,:)) = 1;
                save_nii(new_roi,[results_dir3,subjects{n},ROI_name{r},...
                    '_peak_adjacent',num2str(peakAdjacent),'.nii']);
            end
        end
        
    end
end
cell2csv(fullfile(worksheet_dir,...
    sprintf('search_ROI_summary_top%d_%s.csv',top_N,target_con_name)),...
    worksheet,',','a+');
    