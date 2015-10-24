function [file_list,num_file]=IEX_getFileName(dir,code_name,file_ext)
%[file_list,num_file]=IEX_getFileName(dir,code_name,file_ext)
%Output a list of files stored in cell array, and number of files
%All inputs are required:
%dir:       directory that contains the file of interest;insert "pwd" if 
%           the file of interet is at the current working directory
%code_name: the file initial, or project code name
%file_ext:  file extension, specifying the type of the file of interest

FList=ls(dir);%list files in the directory
%find index of chars that are not white space \t, \f, \r, \n,..., etc
notWhiteSpaceChar_ind=regexp(FList,'\S');
FList=FList(notWhiteSpaceChar_ind);%Take out white space
code_name_ind=strfind(FList,code_name)';%find file's initial / code name
FExt_ind=strfind(FList,file_ext)';%find the index of file extension
num_file=length(FExt_ind);%number of files

file_list=cell(num_file,1);%place holding file list
for i = 1:num_file %much easier to do
    file_list{i,1}=FList(code_name_ind(i):FExt_ind(i)+length(file_ext)-1);
end
% %the begining and the ending index of each file name
% alpha_omega=num2cell([code_name_ind FExt_ind+length(file_ext) ...
%     FExt_ind-code_name_ind+1+length(file_ext)]);
% %list of file name char index of each file
% File_ind=cellfun(@linspace,alpha_omega(:,1),alpha_omega(:,2),...
%     alpha_omega(:,3),'UniformOutput', false);    
end