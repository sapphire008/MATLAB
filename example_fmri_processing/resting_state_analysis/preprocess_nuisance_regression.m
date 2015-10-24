%%%% WHOLEBRAIN_REGRESSION %%%%
%
% WHOLEBRAIN_REGRESSION(A,B,C,D) regresses the effect of one or more
% covariate(s) [B] from a 4-dimensional nifti [A C]. This is currently used
% in Dr. Michael Greicius's lab to regress noise (i.e., cerebral spinal
% fluid, white matter, movement, heart rate, and respiration) from fMRI
% data.
%
% [A] = input_4D_dir_list = Directory pathway to where the original 4D
% nifti input is located. The output for this script (4D fMRI data with
% [B] covariate regressed) will be saved to this same pathway, co-located
% with the original input.
%
%    Example: subjectlist.txt -->
%                [/directory/participant1/subdirectory.feat/;
%                /directory/participant2/subdirectory.feat/; ... ;
%                /directory/participantN/subdirectory.feat/]
%
% [B] = regressors_list = 1x4 matrix that indicates which timeseries
% should be regressed from the 4D fMRI data. This script currently supports
% four different regressors: Cerebral Spinal Fluid (CSF), White Matter
% (WM), Movement, and Global Signal. To specify which timeseries are
% regressed from the data, mark the variables in the REGRESSORS section of
% this configuration file with a 'Yes' (to regress out the effect of the
% listed noise covariate), or 'No' (to not regress out the effect of the
% listed noise covariate).
%
%    Example: regress_CSF = 'Yes'; % The CSF timeseries will be regressed
%             regress_WM = 'Yes'; % The WM timeseries will be regressed
%             regress_Movement = 'Yes'; % The MVMT timeseries regressed
%             regress_GS = 'No'; % The GS timeseries regressed
%             regress_OB = 'No'; % The Outside-Brain timeseries regressed
%
% [C] = input_4D_nii_name = Name of the original 4D nifti from which the
% noise covariates are being regressed.
%
%    Example: input_4D.nii
%
% [D] = output_4D_nii_name = Name of the 4D data output, from which the
% noise covariates have been regressed.
%
%    Example: output_4D.nii
%
% William Shirer - 14 May 2012
%---------------------------------------
%%
function output_nii = preprocess_nuisance_regression(input_4D_dir_list,regressors_list,input_4D_nii_name,output_4D_nii_name,fsl)

%% Batch loop
input_4D_dir = input_4D_dir_list;

switch fsl.mni;
case '2mm'
    mm = 1;
case '3mm'
    mm = 2;
end

for p = 1:size(input_4D_dir(:,1));
   % display (input_4D_dir(p,:));
    %% Upload covariate list and 4D data
    exst = exist(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name,'.gz'));
    if(exst ~= 0);
     %   display('Unzipping data...');
        gunzip(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name,'.gz'));
    
    end
    %display ('Uploading data...');
    input_nii = cbiReadNifti(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name));
    delete(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name));
    
    dim = size(input_nii); d=dim(1)*dim(2)*dim(3); %dimensions of 4D data
    
    %% Calculate regressor timeseries
    should_i_regress_CSF = strcmp(regressors_list(1),'Yes');
    should_i_regress_WM = strcmp(regressors_list(2),'Yes');
    should_i_regress_Movement = strcmp(regressors_list(3),'Yes');
    should_i_regress_GS = strcmp(regressors_list(4),'Yes');
    should_i_regress_OB = strcmp(regressors_list(5),'Yes');
    
    regressor_matrix = [];
    if(should_i_regress_CSF == 1);
      %  display ('Calculating timeseries for Cerebral Spinal Fluid');
      fprintf('Cerebrospinal fluid, ');
        if mm==1;
            calculate_timeseries_CSF = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs/noise_csf.nii'];
        elseif mm==2;
            calculate_timeseries_CSF = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs_3mm/noise_csf_3mm.nii'];
      
        end

      [x,raw_timeseries_CSF] = unix(calculate_timeseries_CSF);
        raw_timeseries_CSF = str2num(raw_timeseries_CSF);
        save(strcat(deblank(input_4D_dir(p,:)),'noise_timeseries_CSF.mat'),'raw_timeseries_CSF');
        [processed_timeseries_CSF]=demean_detrend(raw_timeseries_CSF);
        processed_timeseries_CSF_phaseshift_forward(2:size(processed_timeseries_CSF,1),:) = processed_timeseries_CSF(1:(size(processed_timeseries_CSF,1)-1),:);
        processed_timeseries_CSF_phaseshift_forward(1,:) = processed_timeseries_CSF(1,:);
        processed_timeseries_CSF_phaseshift_back = processed_timeseries_CSF(2:size(processed_timeseries_CSF,1),:);
        processed_timeseries_CSF_phaseshift_back(size(processed_timeseries_CSF,1),:) = processed_timeseries_CSF(size(processed_timeseries_CSF,1),:);
        regressor_matrix = [regressor_matrix processed_timeseries_CSF processed_timeseries_CSF_phaseshift_forward processed_timeseries_CSF_phaseshift_back];
    end
    if(should_i_regress_WM == 1);
        fprintf('White matter, ');
        if mm==1;
            calculate_timeseries_WM = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs/noise_wm.nii'];
        elseif mm==2;
            calculate_timeseries_WM = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs_3mm/noise_wm_3mm.nii'];
        end

       % display ('Calculating timeseries for White Matter');
        [x,raw_timeseries_WM] = unix(calculate_timeseries_WM);
        raw_timeseries_WM = str2num(raw_timeseries_WM);
        save(strcat(deblank(input_4D_dir(p,:)),'noise_timeseries_WM.mat'),'raw_timeseries_WM');
        [processed_timeseries_WM]=demean_detrend(raw_timeseries_WM);
        processed_timeseries_WM_phaseshift_forward(2:size(processed_timeseries_WM,1),:) = processed_timeseries_WM(1:(size(processed_timeseries_WM,1)-1),:);
        processed_timeseries_WM_phaseshift_forward(1,:) = processed_timeseries_WM(1,:);
        processed_timeseries_WM_phaseshift_back = processed_timeseries_WM(2:size(processed_timeseries_WM,1),:);
        processed_timeseries_WM_phaseshift_back(size(processed_timeseries_WM,1),:) = processed_timeseries_WM(size(processed_timeseries_WM,1),:);
        regressor_matrix = [regressor_matrix processed_timeseries_WM processed_timeseries_WM_phaseshift_forward processed_timeseries_WM_phaseshift_back];
    end
    if(should_i_regress_Movement == 1);
        fprintf('Movement, ');
        %display ('Calculating timeseries for Movement');
        movement_file = strcat(deblank(input_4D_dir(p,:)),'mc/prefiltered_func_data_mcf.par');
        raw_timeseries_Movement = read_flist(movement_file);
        raw_timeseries_Movement = str2num(raw_timeseries_Movement);
        save(strcat(deblank(input_4D_dir(p,:)),'noise_timeseries_Movement.mat'),'raw_timeseries_Movement');
        [processed_timeseries_Movement]=demean_detrend(raw_timeseries_Movement);
        processed_timeseries_Movement_phaseshift_forward(2:size(processed_timeseries_Movement,1),:) = processed_timeseries_Movement(1:(size(processed_timeseries_Movement,1)-1),:);
        processed_timeseries_Movement_phaseshift_forward(1,:) = processed_timeseries_Movement(1,:);
        processed_timeseries_Movement_phaseshift_back = processed_timeseries_Movement(2:size(processed_timeseries_Movement,1),:);
        processed_timeseries_Movement_phaseshift_back(size(processed_timeseries_Movement,1),:) = processed_timeseries_Movement(size(processed_timeseries_Movement,1),:);
        regressor_matrix = [regressor_matrix processed_timeseries_Movement processed_timeseries_Movement_phaseshift_forward processed_timeseries_Movement_phaseshift_back];
    end
    if(should_i_regress_GS == 1);
        fprintf('Global signal, ');
        %display ('Calculating timeseries for Global Signal');
        if mm==1;
            calculate_timeseries_GS = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs/noise_gs.nii'];
        elseif mm==2;
            calculate_timeseries_GS = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs_3mm/noise_gs_3mm.nii'];
        end
        [x,raw_timeseries_GS] = unix(calculate_timeseries_GS);
        raw_timeseries_GS = str2num(raw_timeseries_GS);
        save(strcat(deblank(input_4D_dir(p,:)),'noise_timeseries_GS.mat'),'raw_timeseries_GS');
        [processed_timeseries_GS]=demean_detrend(raw_timeseries_GS);
        %processed_timeseries_GS_phaseshift_forward(2:size(processed_timeseries_GS,1),:) = processed_timeseries_GS(1:(size(processed_timeseries_GS,1)-1),:);
        %processed_timeseries_GS_phaseshift_forward(1,:) = processed_timeseries_GS(1,:);
        %processed_timeseries_GS_phaseshift_back = processed_timeseries_GS(2:size(processed_timeseries_GS,1),:);
        %processed_timeseries_GS_phaseshift_back(size(processed_timeseries_GS,1),:) = processed_timeseries_GS(size(processed_timeseries_GS,1),:);
        %regressor_matrix = [regressor_matrix processed_timeseries_GS processed_timeseries_GS_phaseshift_forward processed_timeseries_GS_phaseshift_back];
        regressor_matrix = [regressor_matrix processed_timeseries_GS];
    end
    if(should_i_regress_OB == 1);
        fprintf('Outside brain');
        %display ('Calculating timeseries for Outside Brain');
        if mm==1;
            calculate_timeseries_OB = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs/noise_ob.nii'];
        elseif mm==2;
            calculate_timeseries_OB = ['/usr/local/fsl/bin/fslmeants -i',' ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),' -m /home/fmri/fmrihome/fsl_scripts/ICA/scripts/parcellation/noise_ROIs_3mm/noise_ob_3mm.nii'];
        end
        [x,raw_timeseries_OB] = unix(calculate_timeseries_OB);
        raw_timeseries_OB = str2num(raw_timeseries_OB);
        save(strcat(deblank(input_4D_dir(p,:)),'noise_timeseries_OB.mat'),'raw_timeseries_OB');
        [processed_timeseries_OB]=demean_detrend(raw_timeseries_OB);
        %processed_timeseries_OB_phaseshift_forward(2:size(processed_timeseries_OB,1),:) = processed_timeseries_OB(1:(size(processed_timeseries_OB,1)-1),:);
        %processed_timeseries_OB_phaseshift_forward(1,:) = processed_timeseries_OB(1,:);
        %processed_timeseries_OB_phaseshift_back = processed_timeseries_OB(2:size(processed_timeseries_OB,1),:);
        %processed_timeseries_OB_phaseshift_back(size(processed_timeseries_OB,1),:) = processed_timeseries_OB(size(processed_timeseries_OB,1),:);
        %regressor_matrix = [regressor_matrix processed_timeseries_OB processed_timeseries_OB_phaseshift_forward processed_timeseries_OB_phaseshift_back];
        regressor_matrix = [regressor_matrix processed_timeseries_OB];
    end
    fprintf('\n');
    clear processed_timeseries*
    clear raw_timeserimes*
    
    %% Reshape, demean, and detrend original data, and regress noise covariates
    if(size(regressor_matrix,1)>=1);
        input_nii = reshape(input_nii,d,dim(4))';
    %    y1=zeros(dim(4),d);
       % display ('Data reshape...');
      %  for z = 1:dim(4);
     %       y1(z,:) = y(:,:,z);
       % end
        
       % display ('Data detrend and demean...');
        
        stored_means = mean(input_nii,1);
        input_nii = detrend(input_nii);
        
        %display ('Regressing noise from data...');
        beta1 = regressor_matrix\input_nii;
        input_nii = input_nii - regressor_matrix*beta1;       % ROI time-series with noise covariates regressed out
        clear beta1
        %display ('Data reshape...');
        
        input_nii = input_nii + repmat(stored_means,size(input_nii,1),1);
        output_nii = reshape(input_nii',[dim(1) dim(2) dim(3) dim(4)]);
        clear input_nii
    else
        output_nii = input_nii;
    end
    %% Output data to new nifti, and reformat to be 2mm
    %display ('Write data to nifti...');
    fprintf('Writing to NIFTI:\t');

    output_name = strcat(deblank(input_4D_dir(p,:)),output_4D_nii_name);
        gunzip(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name,'.gz'));
    cbiWriteNifti(output_name,output_nii);
    [output_2mm] = reformat_data_1mm_to_2mm(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name),output_name,output_name);
    
        delete(strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name));
    %display('Zipping input data...');
    zip_file = ['gzip ',strcat(deblank(input_4D_dir(p,:)),input_4D_nii_name)];
    unix(zip_file);
    
    fprintf('done\n');
    %display('Zipping output data...');
    %zip_file2 = ['gzip ',strcat(deblank(input_4D_dir(p,:)),output_4D_nii_name)];
    %unix(zip_file2);
end
end

%% Demean, and detrend noise covariates
function [timeseries_demean_detrend] = demean_detrend(regressor_timeseries);
timeseries_dimensions = size(regressor_timeseries);
for col = 1:timeseries_dimensions(2);
    regressor_timeseries(:,col) = regressor_timeseries(:,col) - mean(regressor_timeseries(:,col));
    regressor_timeseries(:,col) = detrend(regressor_timeseries(:,col));
    timeseries_demean_detrend(:,col) = regressor_timeseries(:,col);
end
end
