function PATHSTR = addmatlabpkg(PACKAGENAME,varargin)
% adds the specified pacakge_name to the search path of MATLAB. Place this
% function in the package directory
%
% PATHSTR = ADDMATLABPKG(PACKAGENAME,OPTION1,VALUE1,...)
%
% INPUTS:
%
%    PACKAGENAME(class:char | cellstr): list of pacakge names to be
%                installed in the default ~/script/ folder.
%                 Enter a cell array to add a list of pacakges.
% OPTION:
%
%   'alt_path': specify an alternative path if not the default path where
%               this function resides. Pass [] to PACKAGENAME to query the
%               alternative path
%   'only': restore MATLAB's default search path first, then add the
%           package path
%   'no_conflicts': avoid duplicate functions to be added. Default false,
%                   that is, to give the function in the newly added
%                   package the highest search path priority
%
% OUTPUT:
%    PATHSTR (class: char | cellstr): ful path of added packages.
%             Used to check if the correct pacakges have been added.
%
% To list the available pacakges at default path where this
% function resides, simply type in the function in the command window
% without any input and output.
%
% To list packages in another path, supply 'alt_path'
%
% If output PATHSTR is supplied with no input, instead of listing all the
% packages, the function will return the path of package directory.
%
% Make sure the spelling of package names match exactly to the folder
% names. The function will not add mis-spelled packages.
%
% Example:
%   1). Add 'dicom_tools' package: addmatlabpath('dicom_tools')
%   2). Add 'beta_series' inside 'fmri_processing_tools':
%        addmatlabpath('beta_series','alt_path','~/fmri_processing_tools/')

%get install path of the ~/scripts/ folder
file_path = mfilename('fullpath');
file_path = file_path(1:(end-length(mfilename)));
%get current search path
original_path = matlabpath;

% inspect whether an alternative path is specified
flag = L_InspectVarargin(varargin,...
    {'alt_path','only','no_conflicts','item'},{[],0,false,[]});

if ~isempty(flag.alt_path)
    file_path = flag.alt_path;
end

% get a list of available packages
package_list = get_package_list(file_path);

%check input
if nargin<1 || isempty(PACKAGENAME)
    if nargout>0
        PATHSTR = file_path;
    else
        disp(package_list(:));
    end
    return;
else%convert single input into cellstring
    try
        package_name = cellstr(PACKAGENAME);
    catch tmp
        error('package name must be a cell array of strings');
    end
    clear tmp;
end

%check if package name matches the ones entered
package_error = package_name(~ismember(package_name,package_list));
package_name = package_name(ismember(package_name,package_list));

%purge other package paths and restore to MATLAB default search path
if flag.only
    restoredefaultpath;
    if RESTOREDEFAULTPATH_EXECUTED
        disp('Successfully restored default MATLAB search path');
    else
        warning(['MATLAB search path not cleared.',...
            'The function will add package paths regardless.']);
    end
end

%add listed package path
PATHSTR = cell(1,length(package_name));
for n = 1:length(package_name)
    PATHSTR{n} = fullfile(file_path,package_name{n});
    addpath(genpath(PATHSTR{n}));
    specialGlobalOfPackage(package_name{n});
end

% return as char if only 1 path to add
if length(PATHSTR) == 1
    PATHSTR = char(PATHSTR);
end

%if requested, demote any function path that are duplicate with functions
%already existed
if flag.no_conflicts
    addpath(original_path);
end

% display warning for not added packages
if ~isempty(package_error)
    S = warning('QUERY','BACKTRACE');
    warning off BACKTRACE;
    warning('Unrecognized Package Names--The following packages are not added: ');
    warning(S.state,'BACKTRACE');
    disp(package_error(:));
end
end

function package_list = get_package_list(PATHSTR)
% list all items in current path
package_list = dir(PATHSTR);
% retain only folders
package_list = package_list(cell2mat({package_list.isdir}));
% exclude . and ..
IDX = arrayfun(@(x) strncmpi(x.name,'.',1),package_list) | ...
    arrayfun(@(x) strcmpi(x.name,'..'),package_list);
package_list = package_list(~IDX);
% return pacakge_list as a cellstr
package_list = {package_list.name};
end

function flag=L_InspectVarargin(search_varargin_cell,keyword,default_value)
% flag = InspectVarargin(search_varargin_cell,keyword, default_value)
%Inspect whether there is a keyword input in varargin, else return default.
%if search for multiple keywords, input both keyword and default_value as a
%cell array of the same length
%if length(keyword)>1, return flag as a structure
%else, return the value of flag without forming a structure
if length(keyword)~=length(default_value)%flag imbalanced input
    error('keyword and default_value must be the same length');
end

%convert everything into cell array if single input
if ~iscell(keyword)
    keyword={keyword};
end
if ~iscell(default_value)
    default_value={default_value};
end

flag=struct();%place holding
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),search_varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=search_varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_value{n};
    end
end

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end

end

function specialGlobalOfPackage(pkg)
switch lower(pkg)
    case 'generic'
        global tableau10;
        tableau10 = {[31,119,180]/256;
                     [255,127,14]/256;
                     [44,160,44]/256;
                     [214,39,40]/256;
                     [148,103,190]/256;
                     [140,86,75]/256;
                     [227,119,194]/256;
                     [127,127,127]/256;
                     [188,189,34]/256;
                     [23,190,207]/256};

end
end
