%batch get unseparated time series
%addspm8('NoConflicts');
%addmatlabpkg('NIFTI');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/EffectiveConnectivity/;
source_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/subjects/funcs/';
source_image = '2sresample_*.nii';
source_image_archive = '2sresample_rra.nii.tgz';
blocks = 'block(\d*)';
ROI_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/EffectiveConnectivity/';
ROIs = {'*_SNleft.nii','*_ACC.nii','*_CaudateHeadLeft.nii','*_CaudateHeadRight.nii'};
ROI_labels = {'SNleft','ACC','CaudateHeadLeft','CaudateHeadRight'};
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/EffectiveConnectivity/';
behav_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/behav/';
behav_target = '*b*.csv';
vect_col = {'TR','trial','trialtype','hit','Drew_cue_onset',...
    'Drew_delay_onset','Drew_target_onset','Drew_feedback_onset',};
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};

% sort columns: MID
sortcolumns = {'block','TR','trial','phases','onsets','trialtype',...
    'conditions','hit','SNleft','ACC','CaudateHeadLeft','CaudateHeadRight'};

ERR_LOG = cell(1,length(subjects));

%% extract raw time series
for s = 1:length(subjects)
%     try
        disp(subjects{s});
        % get a list of images
        P = SearchFiles(fullfile(source_dir,subjects{s}),fullfile(blocks,source_image));
        if isempty(P)%maybe the images are archived
            archived = true;
            P = SearchFiles(fullfile(source_dir,subjects{s}),fullfile(blocks,source_image_archive));
            for m = 1:length(P)
                disp('unarchiving ...');
                eval(['!tar -zxf ',P{m},' -C ',fileparts(P{m})]);
            end
            P = SearchFiles(fullfile(source_dir,subjects{s}),fullfile(blocks,source_image));
        else
            archived = false;
        end
        Data = struct;%initialize the data structure
        % get the index of the blocks
        [~,IFIRST,Data.block] = unique(char(cellfun(@fileparts,P,'un',0)),'rows','first');
        IFIRST = [IFIRST(:);numel(P)+1];
        Data.TR = [];
        for m = 2:numel(IFIRST)%starts at 2
            Data.TR = [Data.TR;[1:(IFIRST(m)-IFIRST(m-1))]'];
        end
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
        if archived,cellfun(@delete,P);end
        
        %% extract behave data: MID
        if any(strcmpi(subjects{s},{'MM_051013_haldol','MP020_050613','MP122_061213','MP124_062113'}))
            continue;
        end
        F = SearchFiles(fullfile(behav_dir,subjects{s}),behav_target);
        for k = 1:length(vect_col),Data.(vect_col{k})=[];end;
        for f = 1:length(F)
            C = ReadTable(F{f});
            for k = 1:length(vect_col)
                clear addendum;
                % lead-in / lead-out
                switch vect_col{k}
                    case 'TR'
                        addendum = {[1:6]',[1:4]'};
                    case 'trial'
                        addendum = {zeros(6,1),zeros(4,1)};
                    otherwise %case {'trialtype','hit'}
                        addendum = {-1*ones(6,1),-1*ones(4,1)};
                end
                Data.(vect_col{k}) = [Data.(vect_col{k});addendum{1};...
                    cell2mat(C(2:end,find(strcmpi(C(1,:),vect_col{k}))));...
                    addendum{2}];
            end
        end
        clear k f C F;
        % translate the trialtype into words
        Data.phases = cell(numel(P),1);
        Data.conditions = cell(numel(P),1);
        Data.onsets = zeros(numel(P),1);
        for n = 1:numel(P)
            if Data.trial(n) == 0
                TR= 0;
            else
                TR = Data.TR(n);
            end
                
            switch TR
                case 0
                    Data.phases{n} = 'Fixation';
                    if n == 1
                        Data.onsets(n) = 0;
                    elseif strcmpi(Data.phases{n-1},'ITI')
                        Data.onsets(n) = Data.onsets(n-1)+2;
                    elseif strcmpi(Data.phases{n-1},'Fixation')
                        Data.onsets(n) = Data.onsets(n-1);
                    end
                case 1
                    Data.phases{n} = 'Cue';
                    Data.onsets(n) = Data.Drew_cue_onset(n);
                case 2
                    Data.phases{n} = 'Delay';
                    Data.onsets(n) = Data.Drew_delay_onset(n);
                    
                case 3
                    Data.phases{n} = 'Target';
                    Data.onsets(n) = Data.Drew_target_onset(n);
                case 4
                    Data.phases{n} = 'Feedback';
                    Data.onsets(n) = Data.Drew_feedback_onset(n);
                otherwise
                    Data.phases{n} = 'ITI';
                    Data.onsets(n) = Data.Drew_feedback_onset(n)+2;
            end
            
            switch Data.trialtype(n)
                case -1
                    if n == 1
                        Data.conditions{n} = 'leadin';
                    elseif strcmpi(Data.phases{n-1},'ITI')
                        Data.conditions{n} = 'leadout';
                    elseif strcmpi(Data.phases{n-1},'Fixation')
                        Data.conditions{n} = Data.conditions{n-1};
                    end
                case 1
                    Data.conditions{n} = 'lose0';
                case 2
                    Data.conditions{n} = 'lose1';
                case 3
                    Data.conditions{n} = 'lose5';
                case 4
                    Data.conditions{n} = 'gain0';
                case 5
                    Data.conditions{n} = 'gain1';
                case 6
                    Data.conditions{n} = 'gain5';
            end
        end
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
            else
                worksheet(2:end,n) = Data.(F{n});
            end
        end
        
        % sort columns
        IND = cell2mat(cellfun(@find,cellfun(@(x) ismember(...
            worksheet(1,:),x),sortcolumns,'un',0),'un',0));
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
    























