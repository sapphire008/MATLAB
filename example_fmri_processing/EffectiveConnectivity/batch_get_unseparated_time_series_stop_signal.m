%batch get unseparated time series
%addspm8('NoConflicts');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/EffectiveConnectivity/
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/subjects/funcs/';
source_image = '2sresample_*.nii';
source_image_archive = '2sresample_rra.nii.tgz';
blocks = 'block(\d*)';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/EffectiveConnectivity/';
ROIs = {'*_STNleft.nii','*_ACC.nii','*_SupTempLeft.nii','*_SupTempRight.nii'};
ROI_labels = {'STNleft','ACC','SupTempLeft','SupTempRight'};
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/EffectiveConnectivity/';
behav_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/behav/';
behav_target = '%s.csv';
vect_col = {'Block','TrialNumber','Cue_Onset','actualSSD','trial_type_name','Accuracy'};
subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};

% sort columns: StopSignal
sortcolumns =  {'Block','TrialNumber','Cue_Onset','actualSSD','trial_type_name','Accuracy',...
    'STNleft','ACC','SupTempLeft','SupTempRight'};

%ERR_LOG = cell(1,length(subjects));

%% extract raw time series
for s = 2:length(subjects)
    disp(subjects{s});
    Data = struct;%initialize the data structure
    %% extract behave data: StopSignal
    F = fullfile(behav_dir,subjects{s},sprintf(behav_target,subjects{s}));
    for k = 1:length(vect_col),Data.(vect_col{k})=[];end;
    C = ReadTable(F);
    for k = 1:length(vect_col)
        IND = find(strcmpi(C(1,:),vect_col{k}));
        switch vect_col{k}
            case 'trial_type_name'
                Data.(vect_col{k}) = C(2:end,IND);
            otherwise
                Data.(vect_col{k}) = sum(cell2mat(C(2:end,IND)),2);
        end
    end
    clear k F C;
    
    % organize data
    IND = Data.Block<3;
    Data = structfun(@(x) x(IND),Data,'un',0);
    clear IND;
    Data.TrialNumber = ceil(Data.TrialNumber/2);
    TR = ceil(Data.Cue_Onset/2);
    % find the index from 1:180,1:180 in which the element is the copy
    % of its previous
    K = diff([TR;1]);
    clear TR;
    K(K<0) = K(K<0) + 180;
    F = fieldnames(Data);
    for indv = 1:length(F)
        v = Data.(F{indv});
        if isnumeric(v)
            Data.(F{indv}) = cell2mat(cellfun(@(x,y) repmat(x,y,1),...
                num2cell(v),num2cell(K),'un',0));
        elseif iscellstr(v)
            tmp = cellfun(@(x,y) repmat(x,y,1),...
                num2cell(v),num2cell(K),'un',0);
            Data.(F{indv}) = cellstr(char(cellfun(@char,tmp,'un',0)));
            clear tmp;
        end
    end
    %     try
    %% extract ROI data
    % get a list of images
    P = SearchFiles(fullfile(source_dir,subjects{s}),fullfile(blocks,source_image));
    if isempty(P)%maybe the images are archived
        archived = true;
        P = SearchFiles(fullfile(source_dir,subjects{s}),fullfile(blocks,source_image_archive));
        P = P(cellfun(@isempty,cellfun(@(x) regexp(x,'block3'),P,'un',0)));
        for m = 1:length(P)
            disp('unarchiving ...');
            eval(['!tar -zxf ',P{m},' -C ',fileparts(P{m})]);
        end
        P = SearchFiles(fullfile(source_dir,subjects{s}),fullfile(blocks,source_image));
        P = P(cellfun(@isempty,cellfun(@(x) regexp(x,'block3'),P,'un',0)));
    else
        archived = false;
    end
    % get rid of block3
    Q = P; %keep original P
    P = P(cellfun(@isempty,cellfun(@(x) regexp(x,'block3'),P,'un',0)));
    if numel(P)>360
        fprintf('%s has more than 360 files\n',subejcts{s});
        continue;
    end
    
    % get the index of the blocks
%     [~,IFIRST,Data.block] = unique(char(cellfun(@fileparts,P,'un',0)),'rows','first');
%     IFIRST = [IFIRST(:);numel(P)+1];
%     Data.TR = [];
%     for m = 2:numel(IFIRST)%starts at 2
%         Data.TR = [Data.TR;[1:(IFIRST(m)-IFIRST(m-1))]'];
%     end
    % load images
    V = spm_vol(char(P));
    % extract the ROI data
    for r = 1:length(ROIs)
        % locate current ROI
        ROI = SearchFiles(fullfile(ROI_dir,subjects{s}),[subjects{s},ROIs{r}]);
        XYZ = get_roi_info(ROI);
        % get the roi time series
        Data.(ROI_labels{r}).voxel = spm_get_data(V,XYZ);
        Data.(ROI_labels{r}).mean = nanmean(Data.(ROI_labels{r}).voxel,2);
        clear XYZ ROI;
    end
    clear V r;
    save(fullfile(save_dir,subjects{s},[subjects{s},'_roi_data.mat']),'Data');
    
    % remove all the image files
    if archived,cellfun(@delete,Q);end
    
    %% write to a worksheet
    F = fieldnames(Data);
    worksheet = cell(numel(P)+1,numel(F));
    worksheet{1,1} = subjects{s};
    worksheet(1,:) = fieldnames(Data);
    
    for n = 1:numel(F)
        if isnumeric(Data.(F{n}))
            worksheet(2:end,n) = num2cell(Data.(F{n}));
        elseif any(strcmpi(F{n},ROI_labels))
            worksheet(2:end,n) = num2cell(Data.(F{n}).mean);
        else%strings
            worksheet(2:end,n) = Data.(F{n});
        end
    end
    
    % sort columns
    IND = cell2mat(cellfun(@find,cellfun(@(x) ismember(worksheet(1,:),x),sortcolumns,'un',0),'un',0));
    worksheet = worksheet(:,IND);
    
    % save everything
    save(fullfile(save_dir,subjects{s},[subjects{s},'_roi_data.mat']),'Data','worksheet');
    cell2csv(fullfile(save_dir,subjects{s},[subjects{s},'_timeseries_data.csv']),worksheet,',');
    %     catch ERR
    %         ERR_LOG{s} = ERR;
    %         disp(ERR.message);
    %         continue;
    %     end
end
    























