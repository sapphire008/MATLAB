%restoredefaultpath;addpath(matlabroot);clc;clear all;
addpath(genpath('/nfs/r21_gaba/reprocessing/image_reg3'));
base_dir = '/nfs/r21_gaba/reprocessing/subjects/';%preprocessing save dir
results_dir = '/nfs/r21_gaba/reprocessing/results/';%post processing save dir
subjects = {'DD_102010',...
    'VP014_12512','VP020_061212','VP080_020411','VP081_021111',...
    'VP085_032111','VP086_042511','VP087_052011','VP087_091211',...
    'VP088_061011','VP089_061711','VP090_081011','VP091_090611',...
    'VP092_100511','VP092_100711','VP093_101411','VP094_102811',...
    'VP095_112811','VP097_121611','VP098_122111','VP099_021214',...
    'VP100_021512','VP101_041312','VP102_042312','VP103_061112',...
    'VP104_082412','VP105_090712','VP106_100512','VP107_110112',...
    'VP108_111912','VP109_011013','VP110_020513',...
    'VP508_022112','VP541_030411','VP541_113010','VP543_041111',...
    'VP544_052011','VP544_060811','VP545_052711','VP546_010912',...
    'VP546_062411','VP547_070111','VP548_071511','VP549_090911',...
    'VP550_092311','VP551_120811','VP552_031212','VP553_031312',...
    'VP553_031912','VP554_050212','VP554_2_050912','VP555_072312',...
    'VP556_072712','VP557_051613','VP557_080712','VP558_081012',...
    'VP559_091812','VP560_092812','VP561_100812','VP562_120612',...
    'VP562_121812','VP563_121112','VP564_012513','VP565_043013',...
    'VP700_092011','VP700_122311','VP701_121911'};

% MPRAGE(1)=struct('subjects','',...
%     'v1_mprage',{''},'v1_runs',{''},'mfg_mprage',{''},'mfg_runs',{''});

%%
diary(fullfile(results_dir,'PostProcessing_MPRAGE_identification.txt'));
%%
for s = 12%:length(subjects)
    disp(subjects{s});
    % get all the folders
    current_dir = fullfile(base_dir,subjects{s},'movement');
    eval(['!rm -rf ',fullfile(current_dir,'mprage_corrected_figures')]);
    folders = dir(current_dir);
    IND = [folders.isdir];
    folders = {folders.name};
    IND = IND & ~strcmpi(folders,'archive');
    IND(1:2) = false;
    folders = folders(IND);
    
    % see if all the folders has the name 'analysis'
    parse_analysis=cellfun(@(x) regexpi(x,'analysis'),folders,'un',0);
    parse_analysis=cellfun(@isempty,parse_analysis);
    
%     if any(parse_analysis)
%         for n = find(parse_analysis)
%             warning('%s is not correctly named. Correct it and come back later.',folders{n});
%         end
%         continue;%skip this run
%     end
    
    
    % see how many mprage runs there are
    parse_mprage = ~cellfun(@isempty,regexpi(folders,'mprage'));
    old_runs = ~cellfun(@isempty,regexpi(folders,'mprage_corrected'));
    parse_mprage(old_runs)=0;
    mprage_IND = find(parse_mprage);
    mprage_folders = folders(parse_mprage);
    run_folders = folders(~parse_mprage);
    output={subjects{s},mprage_folders,run_folders,current_dir};
    
    if length(mprage_folders)>1
        
        for n = 1:length(mprage_folders)
            disp([num2str(n),':',mprage_folders{n}]);
        end
        disp('---------------------------------');
        for n = 1:length(run_folders)
            disp([num2str(n),':',run_folders{n}]);
        end
        ref_vect = input('Enter a reference vector: ');
    else
        ref_vect = ones(1,length(run_folders));
    end
    
    postproc_main_batch(subjects{s},mprage_folders,run_folders,current_dir,ref_vect);
    
    
    clc;
    close all force;
    
end
diary off;