% Batch extract FIR betas for fast event related design
% Set up running parameters
base_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/FIR_GLM_with_GO_ONLY/';
ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
save_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/analysis/FIR_beta_series/';
ROI_suffix = {'_TR2_STNleft.nii','_TR2_SNleft.nii'};
%getnerate 6 basis functions
basis_func = cellstr([repmat('bf(',6,1),strrep(num2str(1:6),' ','')',...
       repmat(')',6,1)]); %whwere 6 is the number of basis funcs

subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',...
   'MP024_052913',...%'MP025_061013',
   'MP120_060513'};%,'MP121_060713','MP122_061213''MP123_061713','MP124_062113'};


clear all;
addspm8;
addpath('/nfs/jong_exp/midbrain_pilots/scripts/FIR_model/');
for s = 1:length(subjects)
    %display which subject is being processed
    disp(subjects{s});
    
    clear SPM BetaData all_cond basis_vect tmp_cond cond_vect;
    %make a directory for the current subject
    mkdir(fullfile(save_dir,subjects{s}));
    %log all data in the BetaData Structure
    BetaData = struct();
    BetaData.subject = subjects{s};%save subject information
    
   % load SPM for each subject
   load(fullfile(base_dir, subjects{s},'SPM.mat'));
   % list all conditions of the current subject
   all_cond = {SPM.xCon.name};
   % find vectors for based on basis functions, ignoring conditions
   basis_vect = SearchCellStr(all_cond, basis_func,1);
   % find vectors based on conditions, disregarding basis functions
   tmp_cond = string_replace(all_cond,'*bf\((\d*)\)','');%remove basis func
   cond_vect = SearchCellStr(tmp_cond, unique(tmp_cond),1);%search conds

   % extracting betas for each ROI
   % get current ROI_loc
   ROI_loc = cellfun(@(x) [ROI_dir, subjects{s}, x], ROI_suffix,'un',0);
   
   % place hold a matrix for the data of current ROI
   % whose size is NxM, where N is the number of conditions, and M is
   % the number of basis functions / time points
   BetaData.betaseries = cell(length(cond_vect), length(basis_vect));
   %store the extracted betas from each ROI inside this matrix
   for M = 1:length(cond_vect)
       for N = 1:length(basis_func)
           clear Images;
           % get con image name
           Images = arrayfun(@(x) x.Vcon.fname, ...
               SPM.xCon(cond_vect(M).index & basis_vect(N).index),...
               'UniformOutput',false);
           % prepend directories to image names as well
           Images = cellfun(@(x) fullfile(SPM.swd,x), Images,'un',0);
           % extract beta values for both ROIs
           BetaData.betaseries{M,N} = extract_roi_betas(Images,ROI_loc,1);
           BetaData.betaseries{M,N}.cond = cond_vect(M).search_name;
           BetaData.betaseries{M,N}.basis = basis_vect(N).search_name;
       end
   end
   
   %get the mean betas of each ROI from the BetaData.betaseries field
   for r = 1:length(ROI_loc)
       clear worksheet col_titles row_titles;
        BetaData.betameans.(['ROI',num2str(r)]) = ...
            cellfun(@(x) x.(['ROI',num2str(r)]).mean, BetaData.betaseries);
        %write each betas as .cvs file to its directory
        col_titles = cellfun(@(x) x.basis, BetaData.betaseries(1,:),'un',0);
        row_titles = cellfun(@(x) x.cond, BetaData.betaseries(:,1),'un',0);
        worksheet = cell(1+length(row_titles), 1+length(col_titles));
        worksheet(1,2:end) = col_titles;
        worksheet(2:end,1) = row_titles;
        worksheet(2:end, 2:end) = num2cell(BetaData.betameans.(['ROI',num2str(r)]));
        cell2csv(fullfile(save_dir, subjects{s},...
            [subjects{s}, ROI_suffix{r},'.csv']), worksheet, ',');
        
   end
   
   % save data for current subject
   save(fullfile(save_dir, subjects{s},[subjects{s},...
       '_extracted_FIR_betas.mat']),'BetaData');
end

