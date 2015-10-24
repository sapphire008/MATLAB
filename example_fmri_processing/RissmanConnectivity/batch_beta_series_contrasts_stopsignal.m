clear;clc
addmatlabpkg('fMRI_pipeline');
addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/RissmanConnectivity/;
subject_dir='/hsgs/projects/jhyoon1/midbrain_pilots/stop_signal/analysis/FIR_timeseries_Connectivity_AUC/';
subject_list={'MP020_050613','MP021_051713',...
    'MP022_051713','MP023_052013','MP024_052913','MP025_061013',...
    'MP026_062613','MP027_062713','MP028_062813','MP029_070213',...
    'MP030_070313','MP031_071813','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};

source_files = 'w%s*R2Z*.nii'; %'w%s*Z_test*.nii'
save_target = '%s_R2Z_%s.nii';%%s_R2Z_%s.nii' %subject_R2Z_ContrastName.nii
% list contrasts
positive_cons{1} = {'SNleft_GO'};
negative_cons{1} = {'null'};
name(1) = {'SNleft_GO-null'};
positive_cons{2} = {'SNleft_GO_ERROR'};
negative_cons{2} = {'null'};
name(2) = {'SNleft_GO_ERROR-null'};
positive_cons{3} = {'SNleft_StopInhibit'};
negative_cons{3} = {'null'};
name(3) = {'SNleft_StopInhibit-null'};
positive_cons{4} = {'SNleft_StopRespond'};
negative_cons{4} = {'null'};
name(4) = {'SNleft_StopRespond-null'};
positive_cons{5} = {'SNleft_StopInhibit'};
negative_cons{5} = {'SNleft_GO'};
name(5) = {'SNleft_StopInhibit-GO'};
positive_cons{6} = {'SNleft_StopRespond'};
negative_cons{6} = {'SNleft_GO'};
name(6) = {'SNleft_StopRespond-GO'};
positive_cons{7} = {'SNleft_StopInhibit','SNleft_StopRespond'};
negative_cons{7} = {'null'};
name(7) = {'SNleft_StopInhibit+StopRespond-null'};
positive_cons{8} = {'SNleft_StopInhibit','SNleft_StopRespond'};
negative_cons{8} = {'SNleft_GO'};
name(8) = {'SNleft_StopInhibit+StopRespond-GO'};
positive_cons{9} = {'SNleft_StopInhibit','SNleft_StopRespond','SNleft_GO','SNleft_GO_ERROR'};
negative_cons{9} = {'null'};
name(9) = {'SNleft_All_Conditions-null'};
positive_cons(10:18) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),positive_cons(1:9),'un',0);
negative_cons(10:18) = cellfun(@(x) regexprep(x,'SNleft','STNleft'),negative_cons(1:9),'un',0);
name(10:18) = regexprep(name(1:9),'SNleft','STNleft');

positive_cons{19} = {'STNleft_GO'};
negative_cons{19} = {'SNleft_GO'};
name(19) = {'STNleft-SNleft_GO'};
positive_cons{20} = {'STNleft_GO_ERROR'};
negative_cons{20} = {'SNleft_GO_ERROR'};
name(20) = {'STNleft-SNleft_GO_ERROR'};
positive_cons{21} = {'STNleft_StopInhibit'};
negative_cons{21} = {'SNleft_StopInhibit'};
name(21) = {'STNleft_-SNleft_StopInhibit'};
positive_cons{22} = {'STNleft_StopRespond'};
negative_cons{22} = {'SNleft_StopRespond'};
name(22) = {'STNleft_SNleft_StopRespond'};
positive_cons{23} = {'STNleft_StopInhibit','STNleft_StopRespond'};
negative_cons{23} = {'SNleft_StopInhibit','SNleft_StopRespond'};
name(23) = {'STNleft-SNleft_Stops'};
positive_cons{24} = {'STNleft_StopInhibit','STNleft_StopRespond','SNleft_GO'};
negative_cons{24} = {'SNleft_StopInhibit','SNleft_StopRespond','STNleft_GO'};
name(24) = {'STNleft-SNleft_with_Stops-Go'};
positive_cons{25} = {'STNleft_StopInhibit','STNleft_StopRespond','STNleft_GO','STNleft_GO_ERROR'};
negative_cons{25} = {'SNleft_StopInhibit','SNleft_StopRespond','SNleft_GO','SNleft_GO_ERROR'};
name(25) = {'STNleft-SNleft_with_sum_All_Conditions'};
positive_cons{26} = {'STNleft_StopInhibit','STNleft_StopRespond','STNleft_GO','SNleft_StopInhibit','SNleft_StopRespond','SNleft_GO'};
negative_cons{26} = {'null'};
name(26) = {'STNleft+SNleft_with_sum_All_Conditions_except_GO_ERROR'};
positive_cons{27} = {'STNleft_StopInhibit','STNleft_StopRespond','STNleft_GO','STNleft_GO_ERROR','SNleft_StopInhibit','SNleft_StopRespond','SNleft_GO','SNleft_GO_ERROR'};
negative_cons{27} = {'null'};
name(27) = {'STNleft+SNleft_with_sum_All_Conditions'};


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