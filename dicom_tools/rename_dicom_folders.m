function rename_dicom_folders(dicom_folder)
% append a name to the dicom folder with SeriesDescription field
% USAGE:
%   rename_dicom_folders(dicom_folder)
% where dicom_folder is the folder contains all the dicom files

%get dicom description from the first dicom file
tmp_dicom = dir(fullfile(dicom_folder,'*.dcm'));
appendix_name = dicominfo(fullfile(dicom_folder,tmp_dicom(1).name));
appendix_name = regexprep(appendix_name.SeriesDescription,'(\W+)',' ');
%remove any potential trailing spaces and replace others with underscore
appendix_name = regexprep(strtrim(appendix_name),'(\s+)','_');

%make a new folder name by appending the description
[PATHSTR,NAME,~] = fileparts(dicom_folder);
if isempty(PATHSTR)
    % if did not specify path, use present working directory
    PATHSTR = pwd;
end
appended_dicom_folder = fullfile(PATHSTR,[NAME,'_',appendix_name]);
%rename the folder
eval(['!mv ',dicom_folder,' ',appended_dicom_folder]);
end