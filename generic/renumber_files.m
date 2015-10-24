function renumber_files(source_file,num_len,target_dir,mode,...
    discard_vect,verbose)
% Auto renumber files by creating symbolic links (default) or completely
% overwrite the original file (can be supplied as an argument)
%
% renumber_files(source_file,num_len,target_dir,mode,discard_vect,verbose)
%
% Inputs:
%       source_file:         full directory of the source files. If only
%                            specified as a directory, the funciton will
%                            rename all the files under the directory.
%                            Optionally, use source/directory/*.nii,  
%                            for example, to rename all the .nii files.
%       num_len (optional):  number length (will pad zeros before the 
%                            number to achieve desired length). Default 4.
%       target_dir(optional):select a different directory than the source
%                            directory to write the file created
%       mode (optional):     type of methods for renaming the files
%               1). ln -s  --> symbolic links (Default)
%               2). mv     --> rename and move the file
%               3). cp     --> copy the file
%       dicard_vect (optional): vector contains which file number to
%                               exclude from renumbering. The numbers will
%                               be kept consecutive. For example, for
%                               original files: {'a','b','c','d','e'}:
%                               If discard_vect = [3], or to discard the 
%                               3rd  file, or file 'c', the numbering will 
%                               become [1,2,3,4], which corresponds to the 
%                               original files {'a','b','d','e'}. Default
%                               empty [], which discards no files
%       verbose (optional): [true|false] Display mapping between original 
%                           file and renumbered files. Default is false.

% parse optional inputs
if nargin<2 || isempty(num_len)
    num_len = 4;
end
% parse the source directory
[PATHSTR,NAME,EXT]=fileparts(source_file);
if nargin<3 || isempty(target_dir)
    target_dir = PATHSTR;
end
% Default mode symbolic link
if nargin<4 || isempty(mode)
    mode = 'ln -s';
elseif isnumeric(mode)
    switch mode
        case 1
            mode = 'ln -s';
        case 2
            mode = 'mv';
        case 3
            mode = 'cp';
    end
end
% default no discarding
if nargin<5
    discard_vect = [];
end
% default do not display mapping
if nargin<6 || isempty(verbose)
    verbose = false;
end

% get a list of files
FILES = dir(source_file);
if isempty(NAME)
    % get rid of . and ..
    IDX = arrayfun(@(x) strcmpi(x.name,'.'),FILES) | ...
        arrayfun(@(x) strcmpi(x.name,'..'),FILES) ;
    FILES = FILES(~IDX);
end

% get a list of files to rename after accounting for discarded files
f_vect = setdiff(1:length(FILES),discard_vect);

% rename files
for f = 1:length(f_vect)
    new_file_name = [repmat('0',1,num_len-length(num2str(f))),...
        num2str(f),EXT];
    eval(['!' mode, ' ', fullfile(PATHSTR,FILES(f_vect(f)).name),' ',...
        fullfile(target_dir,new_file_name)]);
    if verbose
        fprintf('%s : %s\n',new_file_name,FILES(f_vect(f)).name);
    end
end
end