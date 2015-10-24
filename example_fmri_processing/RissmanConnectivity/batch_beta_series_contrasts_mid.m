clear;clc
addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/RissmanConnectivity/;
subject_dir='/hsgs/projects/jhyoon1/midbrain_pilots/mid/analysis/RissmanConnectivity/';
subject_list={'JY_052413_haldol','MM_051013_haldol','MP021_051713',...
    'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
    'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
    'MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};

source_files = 'w%s*R2Z*.nii'; %'w%s*Z_test*.nii'
save_target = '%s_R2Z_%s.nii';%%s_R2Z_%s.nii' %subject_R2Z_ContrastName.nii
% list contrasts
% against null
positive_cons{1} = {'SNleft_Cue_gain5'};
negative_cons{1} = {'null'};
name(1) = {'SNleft_Cue_gain5-null'};
positive_cons(2:6) = cellfun(@(x) regexprep(positive_cons{1},'Cue_gain5',x),{'Cue_gain1','Cue_gain0','Cue_lose0','Cue_lose1','Cue_lose5'},'un',0);
negative_cons(2:6) = repmat(negative_cons(1),1,5);
name(2:6) = cellfun(@(x) regexprep(name{1},'Cue_gain5',x),{'Cue_gain1','Cue_gain0','Cue_lose0','Cue_lose1','Cue_lose5'},'un',0);
% sums
positive_cons{7} = {'SNleft_Cue_gain5','SNleft_Cue_gain1','SNleft_Cue_gain0'};
negative_cons{7} = {'null'};
name(7) = {'SNleft_Cue_gain5+gain1+gain0-null'};
positive_cons{8} = {'SNleft_Cue_lose0','SNleft_Cue_lose1','SNleft_Cue_lose5'};
negative_cons{8} = {'null'};
name(8) = {'SNleft_Cue_lose0+lose1+lose5-null'};
positive_cons{9} = {'SNleft_Cue_gain5'};
negative_cons{9} = {'SNleft_Cue_gain0'};
name{9} = 'SNleft_Cue_gain5-gain0';
positive_cons{10} = {'SNleft_Cue_lose5'};
negative_cons{10} = {'SNleft_Cue_lose0'};
name{10} = 'SNleft_Cue_lose5-lose0';
positive_cons{11} = {'SNleft_Cue_gain1'};
negative_cons{11} = {'SNleft_Cue_gain0'};
name{11} = 'SNleft_Cue_gain1-gain0';
positive_cons{12} = {'SNleft_Cue_lose1'};
negative_cons{12} = {'SNleft_Cue_lose0'};
name{12} = 'SNleft_Cue_lose1-lose0';
positive_cons{13} = {'SNleft_Cue_gain5','SNleft_Cue_lose5'};
negative_cons{13} = {'SNleft_Cue_gain0','SNleft_Cue_lose0'};
name{13} = 'SNleft_Cue_gain5+lose5-gain0-lose0';
positive_cons{14} = {'SNleft_Cue_gain1','SNleft_Cue_lose1'};
negative_cons{14} = {'SNleft_Cue_gain0','SNleft_Cue_lose0'};
name{14} = 'SNleft_Cue_gain1+lose1-gain0-lose0';
positive_cons{15} = {'SNleft_Cue_gain5','SNleft_Cue_lose5','SNleft_Cue_gain1','SNleft_Cue_gain1'};
negative_cons{15} = {'SNleft_Cue_gain0','SNleft_Cue_lose0'};
name{15} = 'SNleft_Cue_gain+lose-zero';
% repeate for STN
positive_cons(16:30) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(1:15),'un',0);
negative_cons(16:30) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),negative_cons(1:15),'un',0);
name(16:30) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),name(1:15),'un',0);
% SN-STN
positive_cons(31:41) = positive_cons([1:6,7:8,13:15]);
negative_cons(31:41) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(31:41),'un',0);
name(31:41) = name([1:6,7:8,13:15]);
name(31:41) = cellfun(@(x) regexprep(x,'SNleft','SNleft-STNleft'),name(31:41),'un',0);
name(31:41) = cellfun(@(x) regexprep(x,'-null',''),name(31:41),'un',0);


%subject level contrasts
for s = 1:length(subject_list)
    disp(subject_list{s});
    [file_list,N] = SearchFiles(fullfile(subject_dir,subject_list{s}),...
        sprintf(source_files,subject_list{s}));
    if isempty(file_list)
        fprintf('%s does not exist\n',subject_list{s});
        continue;
    end
    contrasts = make_contrasts_riss_conn(N,positive_cons,negative_cons,name,true);
    for c = 1:length(contrasts)
        beta_series_contrasts(file_list,contrasts(c).con,fullfile(...
            subject_dir,subject_list{s},sprintf(save_target,subject_list{s},contrasts(c).name)));
    end
end
fprintf('Done\n');

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