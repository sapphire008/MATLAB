clear all;clc
addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/task_connectivity/;
subject_dir='/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/timeseries_Connectivity_conn/';
sub_dir = 'conn_%s/results/firstlevel/ANALYSIS_01/';
subject_list={'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
    'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
    'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
    'MP030_070313','MP032_071013','MP033_071213','MP034_072213',...
    'MP035_072613','MP036_072913','MP037_080613','MP120_060513',...
    'MP121_060713','MP122_061213','MP123_061713','MP124_062113',...
    'MP125_072413'};

source_files = 'wcorr*%s*%s*%s*.nii'; %'w%s*Z_test*.nii'
save_target = 'corr_%s_%s.nii';%%s_R2Z_%s.nii' %subject_R2Z_ContrastName.nii

% list contrasts
% against null
positive_cons{1} = {'Fixation_SNleft'};
negative_cons{1} = {'null'};
name(1) = {'SNleft_Fixation-null'};
positive_cons(2:4) = cellfun(@(x) regexprep(positive_cons{1},'Fixation',x),{'ZeroBack','OneBack','TwoBack'},'un',0);
negative_cons(2:4) = repmat(negative_cons(1),1,3);
name(2:4) = cellfun(@(x) regexprep(name{1},'Fixation',x),{'ZeroBack','OneBack','TwoBack'},'un',0);
positive_cons(5:8) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(1:4),'un',0);
negative_cons(5:8) = negative_cons(1:4);
name(5:8) = regexprep(name(1:4),'SNleft','STNleft');
% SN-STN
positive_cons{9} = {'Fixation_SNleft'};
negative_cons{9} = {'Fixation_STNleft'};
name(9) = {'Fixation_SNleft-STNleft'};
positive_cons(10:12) = cellfun(@(x) regexprep(positive_cons{9},'Fixation',x),{'ZeroBack','OneBack','TwoBack'},'un',0);
negative_cons(10:12) = cellfun(@(x) regexprep(negative_cons{9},'Fixation',x),{'ZeroBack','OneBack','TwoBack'},'un',0);
name(10:12) = cellfun(@(x) regexprep(name{9},'Fixation',x),{'ZeroBack','OneBack','TwoBack'},'un',0);
% against fixation
positive_cons{13} = {'ZeroBack_SNleft'};
negative_cons{13} = {'Fixation_SNleft'};
name(13) = {'SNleft_ZeroBack-Fixation'};
positive_cons(14:15) = cellfun(@(x) regexprep(positive_cons{13},'ZeroBack',x),{'OneBack','TwoBack'},'un',0);
negative_cons(14:15) = repmat(negative_cons(13),1,2);
name(14:15) = cellfun(@(x) regexprep(name{13},'ZeroBack',x),{'OneBack','TwoBack'},'un',0);
positive_cons(16:18) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(13:15),'un',0);
negative_cons(16:18) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),negative_cons(13:15),'un',0);
name(16:18) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),name(13:15),'un',0);
% sums
positive_cons{19} = {'ZeroBack_SNleft','OneBack_SNleft','TwoBack_SNleft'};
negative_cons{19} = {'null'};
name(19) = {'SNleft_ZeroBack+OneBack+TwoBack-null'};
positive_cons{20} = {'ZeroBack_SNleft','OneBack_SNleft','TwoBack_SNleft'};
negative_cons{20} = {'Fixation_SNleft'};
name(20) = {'SNleft_ZeroBack+OneBack+TwoBack-Fixation'};
positive_cons(21:22) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(19:20),'un',0);
negative_cons(21:22) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),negative_cons(19:20),'un',0);
name(21:22) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),name(19:20),'un',0);
positive_cons{23} = {'ZeroBack_SNleft','OneBack_SNleft','TwoBack_SNleft'};
negative_cons{23} = {'STNleft_ZeroBack','STNleft_OneBack','TwoBack_STNleft'};
name{23} = 'SNleft-STNleft_All_task_blocks';

positive_cons{24} = {'TwoBack_SNleft'};
negative_cons{24} = {'OneBack_SNleft'};
name(24) = {'SNleft_TwoBack-OneBack'};
positive_cons{25} = {'OneBack_SNleft'};
negative_cons{25} = {'ZeroBack_SNleft'};
name(25) = {'SNleft_OneBack-ZeroBack'};
positive_cons{26} = {'TwoBack_SNleft'};
negative_cons{26} = {'ZeroBack_SNleft'};
name(26) = {'SNleft_TwoBack-ZeroBack'};
positive_cons(27:29) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(24:26),'un',0);
negative_cons(27:29) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),negative_cons(24:26),'un',0);
name(27:29) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),name(24:26),'un',0);
positive_cons{30} = {'TwoBack_SNleft','STNleft_OneBack'};
negative_cons{30} = {'OneBack_SNleft','TwoBack_STNleft'};
name(30) = {'SNleft-STNleft_TwoBack-OneBack'};
positive_cons{31} = {'OneBack_SNleft','STNleft_ZeroBack'};
negative_cons{31} = {'ZeroBack_SNleft','STNleft_OneBack'};
name(31) = {'SNleft-STNleft_OneBack-ZeroBack'};
positive_cons{32} = {'TwoBack_SNleft','STNleft_ZeroBack'};
negative_cons{32} = {'ZeroBack_SNleft','TwoBack_STNleft'};
name(32) = {'SNleft-STNleft_TwoBack-ZeroBack'};


%subject level contrasts
for s = 1:length(subject_list)
    % display progress
    disp(subject_list{s});
    % get current directory
    current_dir = fullfile(subject_dir,subject_list{s},sprintf(sub_dir,subject_list{s}));
    % Translate subject/condition/source labeling
    Conditions = readvarintxt(fullfile(current_dir,'_list_conditions.txt'));
    Sources = readvarintxt(fullfile(current_dir,'_list_sources.txt'));
    % get the list of files to be used during contrast
    [file_list,N] = SearchFiles(current_dir,strtok(source_files,'%'));
    contrasts = make_contrasts_task_conn(N,Conditions,Sources,positive_cons,negative_cons,name,true,true);
    for c = 1:length(contrasts)
        beta_series_contrasts(file_list,contrasts(c).con,fullfile(...
            subject_dir,subject_list{s},sprintf(save_target,subject_list{s},contrasts(c).name)));
    end
end

% group_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/group_averaged_maps/';
% average_target = '%s_Z_test_%s_average.nii';%Group_R2Z_ContrastName_average.nii
% group = [{'Haldol','Haldol'},repmat({'Control'},1,14),repmat({'Patient'},1,5)];
% group_mask = struct(...
%     'Haldol','/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/sources/Fracback_control_group_mask.nii',...
%     'Control','/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/sources/Fracback_control_group_mask.nii',...
%     'Patient','/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/sources/Fracback_patient_group_mask.nii');
% % group level averages
% [G,~,IB] = unique(group);
% for n = 1:length(G)
%     S = subject_list(IB==n);
%     for m = 1:length(name)
%         P = cellfun(@(x) SearchFiles(fullfile(subject_dir,x),...
%             sprintf(save_target,x,name{m})),S);
%         Vi = spm_vol(char(P));
%         Vo = struct(...
%             'fname',      fullfile(group_dir,'tmp.nii'), ...
%             'dim',        [Vi(1).dim], ...
%             'dt',         [16, 0], ...
%             'mat',        Vi(1).mat, ...
%             'descript',   [name{m},' contrast average']);
%         fstr = sprintf('i%d+',1:numel(Vi));
%         fstr = ['(',fstr(1:end-1),')/',num2str(numel(Vi))];
%         cwd = pwd;
%         % make the average
%         Vo   = spm_imcalc(Vi,Vo,fstr);    
%         % mask averaged image
%         if ~isempty(group_mask.(G{n})) || ~exist(group_mask.(G{n}),'file')
%             M = spm_vol(group_mask.(G{n}));
%             V = Vo;
%             V.fname = fullfile(group_dir,sprintf(average_target,G{n},name{m}));
%             V = spm_create_vol(V);
%             tmp = double(Vo.private.dat);
%             tmp(double(M.private.dat)==0) = 0;
%             V = spm_write_vol(V,tmp);
%             delete(fullfile(group_dir,'tmp.nii'));clear Vo;
%         else
%             fprintf('Warning: %s, %s not masked!\n',G{n},name{m});
%             eval(['!mv ',fullfile(group_dir,'tmp.nii'),' ',...
%                 fullfile(group_dir,sprintf(average_target,G{n},name{m}))]);
%         end
%     end
% end




% file_hint01='R_atanh_corr_SNleftCueGreen*';
% file_hint02='R_atanh_corr_SNleftCueRed*';
% contrast=[-1 1];
% outfile_name='R_atanh_corr_SNleftCueRed-Green.nii';
% 
% for n = 1:length(subject_list),
%     source_path=[subject_dir, subject_list{n}, '/'];
%     file01=dir([source_path, file_hint01]);
%     file02=dir([source_path, file_hint02]);
%     file_list{1} =[source_path file01(1).name]; 
%     file_list{2} =[source_path file02(1).name];
%     beta_series_contrasts(file_list,contrast,[source_path outfile_name]);
%     
%     clear file_list{1} file_list{2} file01 file02 source_path
% end

% subjects = {'AT10','AT11','AT13', 'AT14', 'AT15', 'AT17', 'AT22', 'AT23', 'AT24', 'AT26', 'AT29', 'AT30' 'AT31', 'AT32', 'AT33','AT36'};
% startingdir = '/nfs/sn_loc/analysis/beta_series_correlations/8mm/'
% targetdir = '/nfs/sn_loc/analysis/normalizations/8mm/'
% for n = 1:length(subjects)
%     eval(['!cp ' startingdir subjects{n} '/R_atanh_corr/*RN* ' targetdir subjects{n} '/multivariate/native_space/']);
% end