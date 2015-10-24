function [CON_IMG,IMG_NAME,STAT_TYPE]=search_contrasts(SPM,target_con_name,tolerate_names)
% [CON_IMG,IMG_NAME,STAT_TYPE]=search_contrasts(SPM,target_con_name,tolerate_names)
% dynamically search for a contrast with name specified.
% If there are more than 1 results returned, the function will prompt the
% user to select a proper image.
%
% Inputs:
%       SPM: SPM variable
%       target_con_name: a string specifying target contrast condition
%       tolerate_name: cellstr of tolerated names of conditions. 
%                      If these names are within the con_name string, 
%                      it is okay to include the found CON_IMG. This input
%                      is optional. Default is empty.
%
% Outputs:
%       CON_IMG: name of the contrast image. Class string.
%       IMG_NAME: name of the contrast specified in the SPM file. This
%                 allows user to check if the function has correctly
%                 identified the image. Class string.
%       STAT_TYPE: type of contrast image, whether a T contrast or F
%                  contrast. Class string.

if nargin<3
    tolerate_names = {};
else
    %make sure it is in cellstr
    tolerate_names = cellstr(tolerate_names);
end

%Initilization
CON_IMG = {};
STAT_TYPE = {};
IMG_NAME = {};

for n = 1:length(SPM.xCon)
    %remove bf(\d)
    tmp_con_name = regexprep(SPM.xCon(n).name,'*bf\((\d*)\)','');
    if ~isempty(tolerate_names) || ~all(strcmpi('',tolerate_names))
        %check if each tolerate_names has a sign before it
        IND = cell2mat(regexpi(tmp_con_name,tolerate_names));
        %assuming that if the tolerated names occurs at the first, there is no
        %sign. Remove the tolerated names
        tmp_con_name(IND(IND>1)-1) = '';
        %remove the tolerated names
        tmp_con_name = regexprep(tmp_con_name,tolerate_names,'','ignorecase');
    end
    %check if the tmp_con_name already matches the target_con_name
    if strcmpi(target_con_name,tmp_con_name)
        CON_IMG{end+1} = SPM.xCon(n).Vspm.fname;
        STAT_TYPE{end+1} = SPM.xCon(n).STAT;
        IMG_NAME{end+1} = SPM.xCon(n).name;
    end
end
%check if the found image is unique
if length(CON_IMG)>1
    warning('Con image found is not unique');
    disp('The following images are found');
    for k = 1:length(IMG_NAME)
        disp([num2str(k),':',IMG_NAME{k}]);
    end
    flag = input('Which image do you want to choose?');
    CON_IMG = CON_IMG{flag};
    STAT_TYPE = STAT_TYPE{flag};
    IMG_NAME = IMG_NAME{flag};
else
    %if there is only one result, return as a string
    CON_IMG = char(CON_IMG);
    STAT_TYPE = char(STAT_TYPE);
    IMG_NAME = char(IMG_NAME);
end
end