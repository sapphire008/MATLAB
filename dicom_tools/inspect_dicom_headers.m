% inpsect dicom headers
base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/dicoms/M3020_CNI_011314/4_1_BOLD_mux3_17mm_2s/6093_4_1_dicoms/';
% list of important header names
important_headers = {'TriggerTime','SeriesNumber','AcquisitionNumber',...
    'AcquisitionTime','NumberOfAcquisitions',...
    'InstanceNumber','ImagesInAcquisition','NumberOfTemporalPositions',...
    'StackID','InStackPositionNumber','RepetitionTime'};

%NumberOfTemporalPositions: number of volums
%LocationsInAcquisition: number of slices
    
% get a list of folders
folders = dir(base_dir);
folders = {folders(5:end).name};
folders = cellfun(@(x) fullfile(base_dir,x),folders,'un',0);

% get a list of files for each folder
files = cellfun(@(x) dir(fullfile(x,'*.dcm')),folders,'un',0);
files = cellfun(@(x) char({x.name}),files,'un',0);
files = cellfun(@(x,y) [repmat([x,'/'],size(y,1),1),y],folders,files,'un',0);

for f = 1:length(files)
    clear tmp_files
    tmp_files = cellstr(files{f});
    tmp_file = tmp_files{1};
    dicom_headers = dicom_header_matlab(tmp_file,important_headers);
    disp(tmp_file);
    disp(dicom_headers.RepetitionTime);
    
    
%     ANRANGE=zeros(1,length(tmp_files));
%     for m = 1:length(tmp_files)
%         clear dicom_headers TF missing_fields;
%         dicom_headers=exiftool_matlab_dicom_header(tmp_files{m});
%         ANRANGE(m)=dicom_headers.AcquisitionNumber;
% %         TF = isfield(dicom_headers,important_headers);
% %         missing_fields = important_headers(~TF);
% %         if any(~TF)
% %             disp(tmp_files{m})
% %             disp(missing_fields(:));
% %             fprintf('\n\n');
% %         end
%     end
   % disp(range(ANRANGE));
end