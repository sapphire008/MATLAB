function rename_dicom_folders(dicom_folder)
% append a name to the dicom folder with SeriesDescription field
folder_name_cell = regexp(dicom_folder,'/','split');
folder_name_cell = folder_name_cell(~cellfun(@isempty,folder_name_cell));
folder_name = folder_name_cell{end};
%get dicom description from the first dicom file
tmp_dicom = dir(fullfile(dicom_folder,'*.dcm'));
appendix = dicominfo(fullfile(dicom_folder,tmp_dicom(1).name));
appendix = regexprep(appendix.SeriesDescription,' ','_');
%make a new folder name by appending the description
folder_name_cell{end} = [folder_name,'_',appendix];
if ~regexpi(folder_name_cell{1},'/')
    folder_name_cell = [{'/'},folder_name_cell];
end
appended_dicom_folder = fullfile(folder_name_cell{:});
%rename the folder
eval(['!mv ',dicom_folder,' ',appended_dicom_folder]);
end