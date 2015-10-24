% This script was made for simple soft-linking of contrast images made
% during connectivity analyses into an output directory.
% - Andrew Westphal

% Subject List
%subjects = {'epc03', 'epc04', 'epc05', 'epc06', 'epc08', 'epc11', 'epc17', 'epc18', 'epc19', 'epc21', 'epc22', 'epc24', 'epc26', 'epc28', 'epc30', 'epc31', 'epc32', 'epc34', 'epc39', 'epc41', 'epc42', 'epc49', 'epc56', 'epc58', 'epc60', 'epc61', 'epc63', 'epc64', 'epc66', 'epc67', 'epc70', 'epc71', 'epc72', 'epc73', 'epc74', 'epc80', 'epc89', 'epc100', 'epc102', 'epc103', 'epc105', 'epc106', 'epc109', 'epc112'};
subjects = {'epc03', 'epc04', 'epc05', 'epc11', 'epc17', 'epc19', 'epc20', 'epc21', 'epc22', 'epc24', 'epc25', 'epc26', 'epc28', 'epc34', 'epc39', 'epc45', 'epc46', 'epc48', 'epc56', 'epc58', 'epc60', 'epc61', 'epc63', 'epc64', 'epc66', 'epc67', 'epc70', 'epc74', 'epc79', 'epc89', 'epc93', 'epc94', 'epc95', 'epc98', 'epc99', 'epc100', 'epc102', 'epc103', 'epc105', 'epc106', 'epc107', 'epc109', 'epc111', 'epc112', 'epc113', 'epc114', 'epc115', 'epc118', 'epc120', 'epc123', 'epp02', 'epp13', 'epp15', 'epp20', 'epp21', 'epp39', 'epp40', 'epp58', 'epp70', 'epp81', 'epp88', 'epp119', 'epp128', 'epp130', 'epp132', 'epp139', 'epp145', 'epp149', 'epp153', 'epp158', 'epp172', 'epp173', 'epp177', 'epp181', 'epp193', 'epp203', 'epp205', 'epp209', 'epp213', 'epp214', 'epp215', 'epp217', 'epp222', 'epp228', 'epp234', 'epp241', 'epp244', 'epp251', 'epp255', 'epp258', 'epp263'};
%subjects = {'epc04', 'epc05', 'epc08', 'epc11', 'epc18', 'epc26', 'epc28', 'epc30', 'epc31', 'epc39', 'epc41', 'epc58', 'epc61', 'epc64', 'epc70', 'epc72', 'epc73', 'epc74', 'epc80', 'epc100', 'epc109'};

subject_directory = ('/nfs/uhr08/conn_analysis_01_2009/subjects/');

% Image Prefix (This should be enough information AT THE BEGININNING of your image title to
% specify that image only)

image_prefix1 = ('R_atanh_corr_rDLPFC_L_7Vox_Jong_xyz_bin_LEFT_CueB-CueA_contrast');
%image_prefix2 = ('SN_Project_R_atanh_corr_15_Voxel_SN_CorrectProbe_SZ-C_-8_-16_-12ProbeBX');
%image_prefix3 = ('SN_Project_R_atanh_corr_15_Voxel_SN_CorrectProbe_SZ-C_-8_-16_-12_ProbeBX-ProbeAX');
%image_prefix4 = ('SN_Project_Rcorr_15_Voxel_SN_CorrectProbe_SZ-C_-8_-16_-12ProbeAX');
%image_prefix5 = ('SN_Project_Rcorr_15_Voxel_SN_CorrectProbe_SZ-C_-8_-16_-12ProbeBX');
%image_prefix6 = ('SN_Project_Rcorr_15_Voxel_SN_CorrectProbe_SZ-C_-8_-16_-12_ProbeBX-ProbeAX');

output_directory = ('/nfs/uhr08/conn_analysis_01_2009/group_11_10_Blood_Sample/con_pointers/');

% Link Output Name (Your output link will be named
% (subject_id+image_prefix) so if your subject_id is epc03 and your
% image_prefix is CueB-CueARcorr your link will be called
% "epc03_CueB-CueARcorr"

% Depending on how many image types you have, comment out the
% image_prefixes and code lines that are unnecessary)

% WARNING: This script will delete all contents of the output_directory

eval(['!rm ' output_directory '/*'])

for i = 1:length(subjects)
    eval(['!ln -s ' subject_directory subjects{i} '/' image_prefix1 '* ' output_directory subjects{i} '_' image_prefix1 '.nii'])
   % eval(['!ln -s ' subject_directory subjects{i} '/' image_prefix2 '* ' output_directory subjects{i} '_' image_prefix2 '.nii'])
    %eval(['!ln -s ' subject_directory subjects{i} '/' image_prefix3 '* ' output_directory subjects{i} '_' image_prefix3 '.nii'])
    %eval(['!ln -s ' subject_directory subjects{i} '/' image_prefix4 '* ' output_directory subjects{i} '_' image_prefix4 '.nii'])
    %eval(['!ln -s ' subject_directory subjects{i} '/' image_prefix5 '* ' output_directory subjects{i} '_' image_prefix5 '.nii'])
    %eval(['!ln -s ' subject_directory subjects{i} '/' image_prefix6 '* ' output_directory subjects{i} '_' image_prefix6 '.nii'])
end