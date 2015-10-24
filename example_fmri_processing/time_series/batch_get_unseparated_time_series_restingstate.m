%batch get unseparated time series
%addspm8('NoConflicts');
%addmatlabpkg('NIFTI');
%addmatlabpkg('ReadNWrite');
clear
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/time_series/
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/subjects/funcs/';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/ROIs/TR3/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/haldol/RestingState/analysis/time_series_filtered/';
subjects = {'JY_052413_haldol','MM_051013_haldol','TMS100','TMS200'};
blocks = {''};
source_image = '2sresample_*.nii';
source_archive_image = '2sresample_rra0001_4D.*';
%ROIs = {'_MID_ACC.nii','_MID_CaudateHeadLeft.nii','_MID_CaudateHeadRight.nii','_MID_CaudateHead.nii'};
%ROIs = {'MM_haldol_vs_unmed_CaudateHeadLeft_Plac-Haldol_RProbe_T2p5.nii'};
ROIs = {'_TR3_SNleft.nii','_TR3_STNleft.nii'};
%ROI_labels = {'ACC','CaudateHeadLeft','CaudateHeadRight','CaudateHead'};
%ROI_labels = {'CaudateHead_4POP'};
ROI_labels = {'SNleft','STNleft'};
Wn = [0.008,0.1]; % filter frequency Hz
TR = 3;

%% extract time series for each block
for s = 1:length(subjects)
    disp(subjects{s});
    %load ROI
    ROI_ind = cell(1,length(ROIs));
    for r = 1:length(ROIs)
        ROI_img = load_nii(fullfile(ROI_dir,[subjects{s},ROIs{r}]));
        %ROI_img = load_nii(fullfile(ROI_dir,ROIs{r}));
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
        current_dir = fullfile(base_dir,subjects{s},blocks{b});
        P = SearchFiles(current_dir,source_image);
        isarchived = isempty(P);
        if isarchived
            P = char(SearchFiles(current_dir,source_archive_image));
            if isempty(P),continue;end
            P = FSL_archive_nii('split',P,[],[],'basename','2sresample_rra');
        end
        V = spm_vol(char(P));
        for r = 1:length(ROIs)
            worksheet(1:3,counter) = {subjects{s};ROI_labels{r};blocks{b}};
            TS = mean(spm_get_data(V,ROI_ind{r}),2);
            if exist('Wn','var') && ~isempty(Wn)
                TS_mean = mean(TS(:));%take the mean
                filtered_TS = [TS(:)-TS_mean;zeros(2^(nextpow2(length(TS))+1)-length(TS),1)]';
                [B,A] = butter(3, Wn*(TR*2));
                filtered_TS = filtfilt(B,A,filtered_TS);
                TS = filtered_TS(1:length(TS))+TS_mean;
                clear filtered_TS B A TS_mean;
            end
            worksheet{4,counter} = TS(:);
            counter = counter + 1;
            % plot time series
            figure('Position',[500,500,1000,300],'visible','off');
            plot(linspace(0,(length(TS)-1)*TR,length(TS)),TS);
            title_strs = regexprep([subjects{s},' ',blocks{b},' ',ROI_labels{r}],'  ',' ');
            title_strs = regexprep(title_strs,'_','\\_');
            title(title_strs);
            xlabel('time (s)');
            ylabel('BOLD time series');
            title_strs = regexprep(title_strs,'\\_','_');
            title_strs = regexprep(title_strs,' ','_');
            set(gcf, 'PaperUnits', 'Inches', 'PaperSize', [10, 5],...
                'PaperPosition', [0 0 9 3])
            saveas(gcf,fullfile(save_dir,[title_strs,'.tif']));
            close all;
        end
        %if isarchived,cellfun(@delete,P);end
    end
    worksheet = [worksheet(1:3,:);num2cell(cell2mat(worksheet(4,:)))]';
    worksheet = sortrows(worksheet,2);
    cell2csv(fullfile(save_dir,[subjects{s},'_timeseries_',...
        strjoin(ROI_labels,'_'),'.csv']),worksheet,',');
end

% %% average all the subjects
% worksheet = [{'Subjects','ROIs','Blocks'},cellfun(@(x) ['TR',num2str(x)],num2cell(1:114),'un',0)];
% 
% BIG_MATRIX.C = zeros(6,114,16);
% count_c = 1;
% for s = 3:18
%     clear tmp;
%     tmp = importdata(fullfile(save_dir,[subjects{s},'_timeseries.csv']));
%     BIG_MATRIX.C(:,:,count_c)= tmp.data;
%     count_c = count_c + 1;
%     worksheet = [worksheet;ReadTable(fullfile(save_dir,[subjects{s},'_timeseries.csv']),'delimiter',',')];
% end
% 
% BIG_MATRIX.SZ = zeros(6,114,6);
% count_sz = 1;
% for s = 19:24
%     clear tmp;
%     tmp = importdata(fullfile(save_dir,[subjects{s},'_timeseries.csv']));
%     BIG_MATRIX.SZ(:,:,count_c)= tmp.data;
%     count_sz = count_sz + 1;
%     worksheet = [worksheet;ReadTable(fullfile(save_dir,[subjects{s},'_timeseries.csv']),'delimiter',',')];
% end
% 
% Data.C.mean = mean(BIG_MATRIX.C,3);
% Data.C.std = std(BIG_MATRIX.C,[],3);
% Data.C.se = Data.C.std/sqrt(size(BIG_MATRIX.C,3));
% 
% Data.SZ.mean = mean(BIG_MATRIX.SZ,3);
% Data.SZ.std = std(BIG_MATRIX.SZ,[],3);
% Data.SZ.se = Data.SZ.std/sqrt(size(BIG_MATRIX.SZ,3));
% 
% Data.C = structfun(@num2cell,Data.C,'un',0);
% Data.SZ = structfun(@num2cell,Data.SZ,'un',0);
% 
% cell2csv(fullfile(save_dir,'concatenated_worksheet.csv'),worksheet,',');
% 
% cell2csv(fullfile(save_dir,'control_mean.csv'),Data.C.mean,',');
% cell2csv(fullfile(save_dir,'control_std.csv'),Data.C.std,',');
% cell2csv(fullfile(save_dir,'control_se.csv'),Data.C.se,',');
% 
% cell2csv(fullfile(save_dir,'patient_mean.csv'),Data.SZ.mean,',');
% cell2csv(fullfile(save_dir,'patient_std.csv'),Data.SZ.std,',');
% cell2csv(fullfile(save_dir,'patient_se.csv'),Data.SZ.se,',');
% 
% %% remove baseline
% MATRIX = cell2mat(worksheet(2:end,4:end));
% ROW_MEAN = mean(MATRIX,2);
% K = ROW_MEAN * ones(1,size(MATRIX,2));
% MATRIX_rmbase = (MATRIX./K-1)*100;
% 
% worksheet_rmbase = worksheet;
% worksheet_rmbase(2:end,4:end) = num2cell(MATRIX_rmbase);
% 
% cell2csv(fullfile(save_dir,'baselined','baselined_concatenated_worksheet.csv'),worksheet_rmbase,',');
% 
% worksheet_rmbase(:,2) = strrep(worksheet_rmbase(:,2),'SNleft','1');
% worksheet_rmbase(:,2) = regexprep(worksheet_rmbase(:,2),'STNleft','2');
% worksheet_rmbase(:,3) = regexprep(worksheet_rmbase(:,3),'block1','1');
% worksheet_rmbase(:,3) = regexprep(worksheet_rmbase(:,3),'block2','2');
% worksheet_rmbase(:,3) = regexprep(worksheet_rmbase(:,3),'block3','3');
% worksheet_rmbase(2:end,2:3) = cellfun(@str2num,worksheet_rmbase(2:end,2:3),'un',0);
% 
% worksheet_new = [worksheet_rmbase(:,1),cell(size(worksheet_rmbase,1),1),...
%     worksheet_rmbase(:,2:end)];
% worksheet_new{1,2} = 'Groups';
% worksheet_new(2:97,2) = {'C'};
% worksheet_new(98:end,2) = {'SZ'};
% 
% 
% 
% MATRIX2 = accumarray(cell2mat(worksheet_new(2:end,2:4)),...
%     cell2mat(worksheet_new(2:end,5)));
% 
% 





















