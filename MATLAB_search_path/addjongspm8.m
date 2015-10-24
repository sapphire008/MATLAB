function addjongspm8(varargin)
%add the path of SPM8
%
%   Options:
%       'Default': or no argument, add all spm packages to the search
%                  directory
%       'NoConflicts': If there are packages under spm8 that is in conflict
%                       with MATALB's own functions, this option will put
%                       MATLAB's own functions at the top of the priority
%       'Except': user need to input a list of directories not to be added
%                 to the search directory, concatenated by colon (:); Use
%                 genpath if needed recursively

% record original search paths at the beginning of addspm8
original_paths = matlabpath;
% add spm8
addpath(genpath('/usr/local/pkg64/matlabpackages/jong_spm8'));
% parse inputs
if nargin<1
    OPTION = 'Default';
else
    OPTION = varargin{1};
end
% remove or overwrite depending on OPTION
switch lower(OPTION)
    case {'noconflicts'}
        % add original paths back
        addpath(original_paths);
    case {'except'}
        % remove desired paths
        rmpath(varargin{2});
    case {'default'};
        return;
    otherwise
        error('Case not recognized');
end
end