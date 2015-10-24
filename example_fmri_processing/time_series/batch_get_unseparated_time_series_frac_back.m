%batch get unseparated time series
%addspm8('NoConflicts');
%addmatlabpkg('NIFTI');
base_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/subjects/funcs/';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/';
save_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/analysis/ROI_timeseries/unseparated_timeseries/';
subjects = {'JY_052413_haldol','MM_051013_haldol',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
blocks = {'block1','block2','block3'};
source_image = '2sresample_*.nii';
ROIs = {'_TR3_SNleft.nii','_TR3_STNleft.nii'};
ROI_labels = {'SNleft','STNleft'};

%%
for s = 1:length(subjects)
    disp(subjects{s});
    %load ROI
    ROI_ind = cell(1,length(ROIs));
    for r = 1:length(ROIs)
        ROI_img = load_nii(fullfile(ROI_dir,[subjects{s},ROIs{r}]));
        [X,Y,Z] = ind2sub(size(ROI_img.img),find(ROI_img.img));
        ROI_ind{r} = [X(:)';Y(:)';Z(:)'];
        clear ROI_img X Y Z;
    end
    % get time series from each set
    worksheet = cell(4,length(ROIs)*length(blocks));
    counter = 1;%reset counter for worksheet
    for b = 1:length(blocks)
        disp(blocks{b});
        clear IMAGES V;
        IMAGES = dir(fullfile(base_dir,subjects{s},blocks{b},source_image));
        IMAGES =char(cellfun(@(x) fullfile(base_dir,subjects{s},blocks{b},x),{IMAGES.name},'un',0));
        V = spm_vol(IMAGES);
        for r = 1:length(ROIs)
            worksheet(1:3,counter) = {subjects{s};ROI_labels{r};blocks{b}};
            worksheet{4,counter} = mean(spm_get_data(V,ROI_ind{r}),2);
            counter = counter + 1;
        end
    end
    worksheet = [worksheet(1:3,:);num2cell(cell2mat(worksheet(4,:)))]';
    worksheet = sortrows(worksheet,2);
    cell2csv(fullfile(save_dir,[subjects{s},'_timeseries.csv']),worksheet,',');
end

%% average all the subjects
worksheet = [{'Subjects','ROIs','Blocks'},cellfun(@(x) ['TR',num2str(x)],num2cell(1:114),'un',0)];

BIG_MATRIX.C = zeros(6,114,16);
count_c = 1;
for s = 3:18
    clear tmp;
    tmp = importdata(fullfile(save_dir,[subjects{s},'_timeseries.csv']));
    BIG_MATRIX.C(:,:,count_c)= tmp.data;
    count_c = count_c + 1;
    worksheet = [worksheet;ReadTable(fullfile(save_dir,[subjects{s},'_timeseries.csv']),'delimiter',',')];
end

BIG_MATRIX.SZ = zeros(6,114,6);
count_sz = 1;
for s = 19:24
    clear tmp;
    tmp = importdata(fullfile(save_dir,[subjects{s},'_timeseries.csv']));
    BIG_MATRIX.SZ(:,:,count_c)= tmp.data;
    count_sz = count_sz + 1;
    worksheet = [worksheet;ReadTable(fullfile(save_dir,[subjects{s},'_timeseries.csv']),'delimiter',',')];
end

Data.C.mean = mean(BIG_MATRIX.C,3);
Data.C.std = std(BIG_MATRIX.C,[],3);
Data.C.se = Data.C.std/sqrt(size(BIG_MATRIX.C,3));

Data.SZ.mean = mean(BIG_MATRIX.SZ,3);
Data.SZ.std = std(BIG_MATRIX.SZ,[],3);
Data.SZ.se = Data.SZ.std/sqrt(size(BIG_MATRIX.SZ,3));

Data.C = structfun(@num2cell,Data.C,'un',0);
Data.SZ = structfun(@num2cell,Data.SZ,'un',0);

cell2csv(fullfile(save_dir,'concatenated_worksheet.csv'),worksheet,',');

cell2csv(fullfile(save_dir,'control_mean.csv'),Data.C.mean,',');
cell2csv(fullfile(save_dir,'control_std.csv'),Data.C.std,',');
cell2csv(fullfile(save_dir,'control_se.csv'),Data.C.se,',');

cell2csv(fullfile(save_dir,'patient_mean.csv'),Data.SZ.mean,',');
cell2csv(fullfile(save_dir,'patient_std.csv'),Data.SZ.std,',');
cell2csv(fullfile(save_dir,'patient_se.csv'),Data.SZ.se,',');

%% remove baseline
MATRIX = cell2mat(worksheet(2:end,4:end));
ROW_MEAN = mean(MATRIX,2);
K = ROW_MEAN * ones(1,size(MATRIX,2));
MATRIX_rmbase = (MATRIX./K-1)*100;

worksheet_rmbase = worksheet;
worksheet_rmbase(2:end,4:end) = num2cell(MATRIX_rmbase);

cell2csv(fullfile(save_dir,'baselined','baselined_concatenated_worksheet.csv'),worksheet_rmbase,',');

worksheet_rmbase(:,2) = strrep(worksheet_rmbase(:,2),'SNleft','1');
worksheet_rmbase(:,2) = regexprep(worksheet_rmbase(:,2),'STNleft','2');
worksheet_rmbase(:,3) = regexprep(worksheet_rmbase(:,3),'block1','1');
worksheet_rmbase(:,3) = regexprep(worksheet_rmbase(:,3),'block2','2');
worksheet_rmbase(:,3) = regexprep(worksheet_rmbase(:,3),'block3','3');
worksheet_rmbase(2:end,2:3) = cellfun(@str2num,worksheet_rmbase(2:end,2:3),'un',0);

worksheet_new = [worksheet_rmbase(:,1),cell(size(worksheet_rmbase,1),1),...
    worksheet_rmbase(:,2:end)];
worksheet_new{1,2} = 'Groups';
worksheet_new(2:97,2) = {'C'};
worksheet_new(98:end,2) = {'SZ'};



MATRIX2 = accumarray(cell2mat(worksheet_new(2:end,2:4)),...
    cell2mat(worksheet_new(2:end,5)));























