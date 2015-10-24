%Finds the voxel with the maximum T value within a search space ROI%
clear all;
%directory of GLM
subject_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/GLM/';
subjects = {'MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613','MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113','MP125_072413'};
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
ROI_name = {'_TR2_SNleft','_TR2_STNleft'};
worksheet_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/ROI_peak_T_voxel/';
results_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/ROI_peak_T_voxel/peak_T_ROIs/';
results_dir2 = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/ROI_peak_T_voxel/marked_ROIs/';
%spmT = 'spmT_0004';%use which contrast to determine ROI peak T value
target_con_name = 'StopInhibit+StopRespond-Go';
tolerate_names = '';
%only being used to create a new ROI, so long as this beta image is the same space as the ROI
template_img = 'beta_0001.img';
%select a color coding for the peak voxel
peak_color = 'Green';
worksheet_header = {'Subject','ROI','Peak_T_Value','Voxel_Locale',...
    'Coord_X','Coord_Y','Coord_Z'};
top_N = 3;%find top N peak voxels

% ------------------------ DO NOT EDIT BELOW ----------------------------
%addspm8;
%addpath /nfs/pkg64/contrib/nifti/;
%addpath /nfs/jong_exp/midbrain_pilots/scripts/search_area_ROI/;

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
ind = 2;
%%
for n = 1:length(subjects);
    clear SPM_loc spmT_loc beta_loc CON_IMG IMG_NAME;
    %display subject name
    disp(subjects{n});
    %locate SPM file
    SPM_loc = [subject_dir subjects{n} '/SPM.mat'];
    %locate template image file
    beta_loc = [subject_dir subjects{n} '/' template_img]; 
    %load SPM as a variable to MATLAB workspace
    load(SPM_loc);
    %locate spmT file with specified contrast
    [CON_IMG,IMG_NAME]=search_contrasts(SPM,target_con_name,tolerate_names);
    spmT_loc = fullfile(subject_dir,subjects{n},CON_IMG);
    
    %for each ROI
    for r = 1:length(ROI_name)
        clear ROI XYZ t_values maxNum maxIndex coordinate new_roi ...
            native_roi data;
        ROI = [ROI_dir subjects{n} ROI_name{r} '.nii'];
        XYZ = roi_find_index_no_mat(ROI);
        
        %spmT values%
        t_values = spm_get_data(spmT_loc, XYZ);
        
        %prints out voxel with the maximum value within the search space and
        %prints out the coordinates of that voxel%
        tmp_t_values = t_values;

        
        for ff = 1:top_N
            maxNum = max(tmp_t_values);
            maxIndex = find(tmp_t_values == maxNum);
            %[maxNum, maxIndex] = max(t_values);
            coordinate = XYZ(:,maxIndex);
	
            % write information to worksheet
            worksheet{end+1,1} = subjects{n};
            worksheet{ind,2} = [regexprep(ROI_name{r},'([_-]*)',''),'_',num2str(ff)];
            worksheet{ind,3} = maxNum;
            for mm = 1:length(maxIndex)
                worksheet{ind,4}(mm) = PointLocation(coordinate(:,mm),XYZ);
            end
            worksheet{ind,5} = coordinate(1,:);
            worksheet{ind,6} = coordinate(2,:);
            worksheet{ind,7} = coordinate(3,:);
            
            ind = ind+1;
            tmp_t_values = tmp_t_values(tmp_t_values ~= maxNum);
        end
        
        if top_N ~= 1
            % write out ROI
            %peak single voxel ROI
            new_roi = load_nii(beta_loc);
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
        end
        
        %%Surrounding 27 voxels%%
        %     x=(coordinate(1)-1):(coordinate(1)+1);
        %     y=(coordinate(2)-1):(coordinate(2)+1);
        %     z=(coordinate(3)-1):(coordinate(3)+1);
        %
        %     new_roi.img(x,y,z)=1;
        %
        %     %intersection between new roi and original search space roi
        %     search_space_roi = load_nii(ROI);
        %
        %     idx1 = find(new_roi.img);
        %     idx2 = find(search_space_roi.img);
        %     common = intersect(idx1,idx2);
        %
        %     new_roi2 = load_nii(beta_loc);
        %     foo=size(new_roi2.img);
        %     new_roi2.img = zeros([foo(1),foo(2),foo(3)]);
        %     new_roi2.img(common)=1;
        %
        %     save_nii(new_roi2,[results_dir subjects{n} '_' ROI_name '.nii']);
        %
        %     ROI2 = [results_dir subjects{n} '_' ROI_name '.nii'];
        %     XYZ2 = roi_find_index(ROI2);
        %     t_values2 = spm_get_data(spmT_loc, XYZ2);
        %
        %     %write data for surroud 27 voxels data
        %     data{1}.header='tvalues';
        %     data{1}.col=t_values;
        %     data{2}.header='x_cord';
        %     data{2}.col=XYZ2(1,:);
        %     data{3}.header='y_cord';
        %     data{3}.col=XYZ2(2,:);
        %     data{4}.header='z_cord';
        %     data{4}.col=XYZ2(3,:);
        %     data{5}.header='Max';
        %     data{5}.col=maxNum;
        %     data{6}.header='Mean';
        %     data{6}.col=mean;
        
        
%         data{1}.header = 't_values';
%         data{1}.col = t_values;
%         data{2}.header = 'X-Coord';
%         data{2}.col = XYZ(1,:);
%         data{3}.header = 'Y-Coord';
%         data{3}.col = XYZ(2,:);
%         data{4}.header = 'Z-Coord';
%         data{4}.col = XYZ(3,:);
%         write_struct(data,[results_dir subjects{n} ROI_name{r} '.csv']);       
        
    end
end
cell2csv(fullfile(worksheet_dir,['search_ROI_summary_top',num2str(top_N),'.csv']),worksheet,',');
    