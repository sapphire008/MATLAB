% B.R. Geib (brgeib@ucdavis.edu)
% Winter 2012
% Beta_Master_OP.m
clc; clear all; addspm8;
fprintf('Beta_Master_EP.m is starting...\n');
addpath(genpath('/nfs/ep/code/Matlab_Scripts/'));
%
% Description:
% This function is designed to pull betas from numerous masks and subject
% groups. Grouping is necessary for summary measures. The contrast asked
% for are genearted based upon the first subject found e.g.
% subj{1}.data{1}, this subject should have the contrast of interest or the
% code will not be able to find the contrast. If you're using this code for
% your own purposes I'd suggest uncommenting the "Custom Code" section and
% completing the "New User Code' section. Don't worry about the extra
% variables in the custom code section either. It was made to make things
% easier but has nothing unique in it. The script also has functionality to
% output box plots. The box plots indicate the spread of the data and flag
% outliers. The outliers are returned within the command line interface and
% are also flagged in the output file. This isn't rigorous, but can be a
% helpful reference.
%
% Define Inputs:
    % Subject list  
        % subj_dir  => Where the subjects are located
        % sub       => Subject sub directory e.g. [subj_dir subj{1} sub]
        % sav_dir   => Where to save the output
    % Subjects Structure
        % subj{x}.name='name of group'
        % subj{x}.data={'subj1' 'subj2' etc.} 
    % Setup masks   
        % m_path    => Location of masks
        % m{x}      => Arrays of masks e.g m{1}=[m_path 'mask1.nii'];
    % Setup the data structures too, this requires a different command for
    % each group you have created. Detailed structures are below the modify
    % line.
%
% Required Scripts:
%   beta_save
%   beta_extractor
%   roi_find_index
%   coag_betas
%
% Suggested Scripts:
%   excel_reader
%
% Note: SNR functionality is identical to beta functionality - the
% difference is the images that are pulled. The extra script only reformats
% the data.
%
%==============================NEW USER CODE==============================%
% FOR BETA FUNCTIONALITY
	subj_dir='/subject_dir/';
	sub='/';
	sav_dir='/save/';
	fname=[sav_dir 'betas.csv'];
	subj{1}.data={'subj1' 'subj2'};
	subj{1}.name='group1';
	m{1}='mask1.nii';
	m{2}='mask2.nii';
%  fix_subj(#)
%		.ID
%		.sub
%		.subj_dir
%
% FOR SNR FUNCTIONALITY
%
% FOR CONCATENATE FUNCTIONALITY (all of the above +)
%	save_pre  => save string before month
%	save_post => save string after month
%  cat_by    => roi || time (determines dimension to cocatenate over)
%
%===============================CUSTOM CODE===============================%
wrk_dir='/nfs/ep/EP_Processing/';
m_path=[wrk_dir 'masks/']; mc=0;
% Pick Atlas
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B9B46_L_d0_1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B9B46_R_d0_1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B9B46_B_d0_1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B46_L_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B46_R_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B46_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B9_L_d0_1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B9_R_d0_1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/B9_B_d0_1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/AC_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/MedFG_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/CingAnt_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/CingMid_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/CingMid_B_d1.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/CingMid_SMA_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/SMA_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/Parietal_SupInf_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/InfParLob_R_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/InfParLob_B_d0.nii'];
% mc=mc+1; m{mc}=[m_path 'PickAtlas/InfParLob_L_d0.nii'];
mc=mc+1; m{mc}=[m_path 'PickAtlas/B9_L_d1.nii'];
mc=mc+1; m{mc}=[m_path 'PickAtlas/B9_R_d1.nii'];
mc=mc+1; m{mc}=[m_path 'PickAtlas/B9_B_d1.nii'];

% ROIs
% mc=mc+1; m{mc}=[m_path 'ROIs/rDLPFC_L_7Vox_Jong_xyz_bin_LEFT.nii'];
% mc=mc+1; m{mc}=[m_path 'ROIs/rDLPFC_L_7Vox_Jong_xyz_bin_RIGHT.nii'];
% mc=mc+1; m{mc}=[m_path 'ROIs/DLPFC_Jong_xyz_bin_BILAT.nii'];
% mc=mc+1; m{mc}='/nfs/uhr08/AX-Stroop_Analysis/Masks/ad_hoc_ACC_fsl2_roi_1.nii';
% mc=mc+1; m{mc}='/nfs/uhr08/AX-Stroop_Analysis/Masks/rad_hoc_ACC_fsl2_roi_1.nii';
% Analysis Specific
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/Cing_2_8_50_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/M1_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/M_Cing_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_IPL_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/R_IPL_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_BA3_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_Supp_Motor_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_BA9_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_Sup_Lobule_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_Thal_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_Insula_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/R_med_PFC_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/L_inf_Par_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/Post_Cing_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/LS_R_PFC_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/LS_L_PFC_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/LS_L_Par_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/IC_R_PFC_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/IC_L_PFC_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/IC_L_Par_r5.nii'];
% mc=mc+1; m{mc}=[m_path '061313_FIR_Pilot/IC_R_Par_r5.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/VMPFC5.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/PostCingulate.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/Ldlpfc_v1.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/Ldlpfc_v2.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/Rdlpfc_v1.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/Rdlpfc_v2.nii'];
% mc=mc+1; m{mc}=[m_path '121812_RT/AntCingulate.nii'];
% mc=mc+1; m{mc}=[m_path '020613_SN/f15vox_LSN_-8_-16_-12.nii']; % f for flipped
%mc=mc+1; m{mc}=[m_path '020413_Longitudinal/Cing_5.nii'];
% mc=mc+1; m{mc}=[m_path '020413_Longitudinal/Cing_HC34_SZ22_5.nii'];
% mc=mc+1; m{mc}=[m_path '020413_Longitudinal/Par_HC34_SZ22_5.nii'];
% mc=mc+1; m{mc}=[m_path '020413_Longitudinal/ACC_HC39_SZ22_5.nii'];
% mc=mc+1; m{mc}=[m_path '020413_Longitudinal/R_dlpfc_HC39_SZ22_5.nii'];
% mc=mc+1; m{mc}=[m_path '000012_ax-stroop/R_dlpfc_5.nii'];
% mc=mc+1; m{mc}=[m_path '000012_ax-stroop/R_inf_par_5.nii'];
% mc=mc+1; m{mc}=[m_path '000012_ax-stroop/L_dlpfc_5.nii'];
% Spheres
% mc=mc+1; m{mc}=[m_path 'Spheres/R50_36_36_44.nii'];
% mc=mc+1; m{mc}=[m_path 'Spheres/L_IPL_r5.nii'];
% mc=mc+1; m{mc}=[m_path 'Spheres/R_IPL_r5.nii'];
% Classification
% MNI_files=dir([m_path '/MNI_Stroop/MNI*']);
% for i=1:length(MNI_files)
% 	mc=mc+1; m{mc}=[m_path '/MNI_Stroop/' MNI_files(i).name];
% end

subject_group='061313_FIR_Pilot'; 
fix_subj=[];
con_base=[];

switch subject_group
	case '061313_FIR_Pilot'
		task='Stroop/'; month='00_MONTH/';
		G='LS';
		pre='func_an_SPM8_Nfsl2_MR'; 
		switch G
			case 'LS', subj_col={'F' 'G'}; subj_hed={'HC' 'SZ'};
						  analysis_name='/LS_HC36_SZ30_dilated/';
						  first='LS_MTU';				  
			case 'FIR',subj_col={'A' 'B'}; subj_hed={'HC' 'SZ'};
						  analysis_name='/FIR_HC49_SZ41/';
						  first='RTP1_FIR_L105_O7_MTU';
		end
		
	case '042513_IQ_Study'
		task='AX/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8/';
		subj_col={'A' 'B' 'C' 'D' 'E'};
		subj_hed={'EPC' 'EG1' 'EG2' 'UC0' 'UC1'};
		analysis_name='/';
		
    case '041313_CortThick'
		task='AX/'; month='00_MONTH/';
		first='MTC'; pre='func_an_SPM8/';
		subj_col={'A'}; subj_hed={'All'};
		analysis_name='/';
	case '000012_ax-stroop'
		task='Stroop/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8/';
		subj_col={'A' 'B'}; subj_hed={'HC' 'SZ'};
		analysis_name='032013/';
	case '051313_cytokine_betas'
		task='AX/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8/';
		subj_col={'A'}; subj_hed={'Subj'};
		analysis_name='/';
	case '020413_Longitudinal'
		task='Stroop/'; month='12_MONTH/';
		first='MTU'; pre='func_an_SPM8_Nfsl2_MR/';
		subj_col={'A' 'B'}; subj_hed={'HC' 'SZ'};
		
		switch month
			case '00_MONTH/'
				S=1;
				fix_subj(S).ID={'uhr01_conv'};
				fix_subj(S).subj_dir=[wrk_dir task '/first_levels/12_MONTH/'];
				fix_subj(S).sub=['/' first '/' pre '/']; S=S+1;
			case '12_MONTH/'
				S=1;
				fix_subj(S).ID={'epc20' 'epc31' 'epp69' 'epp88'};
				fix_subj(S).subj_dir=[wrk_dir task '/first_levels/06_MONTH/'];
				fix_subj(S).sub=['/' first '/' pre '/']; S=S+1;
				fix_subj(S).ID={'epc26' 'epc64' 'epc93' 'epc132' 'epp104' 'epp145' 'epp152' 'epp263' 'epp278' 'uhr01_conv'};
				fix_subj(S).subj_dir=[wrk_dir task '/first_levels/24_MONTH/'];
				fix_subj(S).sub=['/' first '/' pre '/']; S=S+1;
		end
		analysis_name='/HC33_SZ19/';
	case '013013_PPI_HC90_SZ82'
		task='AX/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8/';
		subj_col={'D'}; subj_hed={'Ug'};
		analysis_name='/';	
	case '101512_T1'
		task='Stroop/'; month='00_MONTH/';
		first='MTC'; pre='func_an_SPM8_fsl';
		subj_col={'A'}; subj_hed={'HC'}; 
		analysis_name='/';
	case '121812_RT'
		task='Stroop/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8';
		subj_col={'D' 'E'}; subj_hed={'HC' 'P'}; 
		analysis_name='test/';
	case '020613_SN'
		task='AX/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8_S2';
		subj_col={'A'}; subj_hed={'UHR'}; 
		analysis_name='/';
	case '999999_database';
		task='AX/'; month='00_MONTH/';
		first='MTU'; pre='func_an_SPM8';
		subj_col={'A'}; subj_hed={'All'}; 
		analysis_name='/';
end

%-------------------------------------------------------------------------%
%=========================================================================%
% DO NOT MODIFY
%=========================================================================%
%-------------------------------------------------------------------------%
snr=0; concatenate=2;

switch snr
	case 0
		subj_dir=[wrk_dir task '/first_levels/' month]; 
		sub=['/' first '/' pre '/'];
	case 1
		con_base={'snr_1.img' 'snr_2.img' 'snr_3.img' 'snr_4.img'};
		analysis_name='/SNR/';
		subj_dir=[wrk_dir task '/preprocessed/' month]; 
		sub=['/' pre '/'];
end

switch subject_group
	case '999999_database'
		subject_file=fullfile(wrk_dir,task,...
			'project_folders',subject_group,'AX_QOD.csv');
		save_dir=fullfile('/nfs/ep/EP_Processing/',task,...
			'project_folders',subject_group,month,'betas',first,pre,analysis_name);
	case '000012_ax-stroop'
		subject_file=fullfile(wrk_dir,...
			'project_folders',subject_group,'subject_list.csv');
		save_dir=fullfile(wrk_dir,...
			'project_folders',subject_group,task,month,'betas',first,pre,analysis_name);
	otherwise
		subject_file=fullfile(wrk_dir,task,...
			'project_folders',subject_group,'subject_list.csv');
		save_dir=fullfile('/nfs/ep/EP_Processing/',task,...
			'project_folders',subject_group,month,'betas',first,pre,analysis_name);
end

data=excel_reader(subject_file,subj_col,subj_hed);
for i=1:length(data)
	subj{i}.data=data{i}.col;
	subj{i}.name=subj_hed{i};
end

if concatenate==0
	beta_shell(subj_dir,sub,subj,month,m,save_dir,fix_subj,con_base);
end
%=========================================================================%
% Concatenate
%=========================================================================%
if concatenate~=0,
	switch concatenate
		case 1, cat_by='time';
		case 2, cat_by='roi';
	end
	save_pre=fullfile(wrk_dir,task,'project_folders',subject_group);
	save_post=fullfile('betas',first,pre,analysis_name);
	beta_cat(m,save_pre,save_post,cat_by)
end
%=========================================================================%
% SNR Functionality
%=========================================================================%
if snr==1, % Create a movement compatible SNR report
	beta_snr(save_dir,m)
end
%=========================================================================%	

