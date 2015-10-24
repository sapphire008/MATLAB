%answer key to phantom dicom
% 1). Foot to Head, Descending
% 2). Foot to Head, Ascending
% 3). Head to Foot, Ascending
% 4). Head to Foot, Descending
% 5). Head to Foot, Interleaved
% 6). Foot to Head, Interleaved
clear all;
close all;
clc;
base_dir = '/nfs/jong_exp/PFC_basalganglia/subjects/dicoms/';
forbbiden_dicoms = {'localizer','mprage','true','svs','mpr'};
target_file = '0001.dcm';

%list all the directories and subdirectories in the current base_dir
[PATH,FILES] = subdir(base_dir);

%locate all the target files within listed directories
file_status = {};
diary orientation_check_log.txt
for n = 1:length(PATH)
    %check if path contains target files
    if ~any(ismember(FILES{n},target_file))
        continue;%if not, skip
    end
    %check if path contains forbidden words
    if any(cell2mat(cellfun(@(x) strfind(...
            lower(PATH{n}),lower(x))>0,forbbiden_dicoms,'un',0)))
        continue;%if so, skip
    end
    
    %%%%%%The following code examines the file%%%%%%%
    %examining current dicom file
    file_status{end+1,1} = get_ucmode(fullfile(PATH{n},target_file));
    current_row = size(file_status,1);
    disp(file_status{current_row});
    %plot inline
    clear tmp_dicom;
    tmp_dicom = dicomread(dicominfo(fullfile(PATH{n},target_file)));
    colormap('gray');
    imagesc(tmp_dicom);
    title(fullfile(PATH{n},target_file));
    
    file_status{current_row,2} = input(...
        'What is the current inline? FH or HF or NA?','s');
    close all;
end
diary off;
save('Orientation_check.mat','file_status');