function make_folders(base_dir,tasks, sub_dirs,subjects,blocks, Replace)
% batch make directories
% batch_make_folders(base_dir, tasks, sub_dirs, subjects,blocks)
%
% assuming the following strcuture
% 'base_dir'/{tasks}/'sub_directory'/{subjects}/{blocks}
%
% base_dir: base directory, which contains all the tasks and all the
%           subjects
%
% tasks: cellstr of task names, {'frac_back','mid','stop_signal'}
%
% sub_dirs:  folder names under tasks; must be string or cellstr. If
%                 if string, the function will apply that to all tasks; if
%                 cellstr, must be the same length as tasks
%
% subjects: subject names, cellstr
%
% blocks: allowing two formats
%       Format 1: {'block',[3 2 3]};
%               This means, for each task, the function will construct
%               block names as 'block1', 'block2','block3', etc.
%               The vector indicates how many blocks to construct for each
%               task. In this example, 3 blocks for task 1, 2 blocks for
%               task 2, and 3 blocks for task 3. This must follow the order
%               specified in task. If entered zero for a corresponding
%               task, then it will not make any folder.
%
%       Format 2:
%       {{'block1','block2','block3'},{'block1','block2'},{'block1','block2',block3'}}
%       This is equivalent to the above format, but more specific. Again,
%       the order must match the order specified in tasks
%
% Replace: 0 | 1, whether or not replace the original folder (that is,
%                 cleanse the old folders and recreate them. 
%                   Use with caution.

% base_dir = '/nfs/jong_exp/midbrain_pilots/';
% subjects = {'MP032_071013'};
% sub_dirs = 'subjects/funcs/';
% tasks = {'RestingState','fullhead','frac_back','mid','stop_signal'};
% blocks = {'block',[0 0 3 2 3]};


% inspect sub_dirs
if ischar(sub_dirs)% in case of a single string, apply the sub_dirs to all tasks
    sub_dirs = cellstr(repmat(sub_dirs,length(tasks),1));
elseif iscellstr(sub_dirs) && length(sub_dirs) == 1%in case only one input, apply all sub_dirs to all tasks
    sub_dirs = cellstr(repmat(sub_dirs{1},length(tasks),1));
end

% inspect dirs
if ischar(blocks{1}) && isnumeric(blocks{2}) %input format 1
    %convert to format2
    blocks = arrayfun(@(x) cellstr([repmat(blocks{1},x,1),...
        strrep(num2str(1:x),' ','')']),blocks{2},'un',0);
end

% inspect replacement tag
if nargin<6
    Replace = false; %default: no replacement
end
% make directories
for t = 1:length(tasks)
    for s = 1:length(subjects)
        %for each block (if there is no block, or length(block)=0, skip)
        for b = 1:length(blocks{t})
            %get the directory of current folder
            this_folder = fullfile(base_dir, tasks{t},sub_dirs{t},...
                subjects{s},blocks{t}{b});
            %check if replacement is necessary
            if Replace && exist(this_folder)
                flag = input([this_folder,...
                    ': already existed. Replace?(Y/N)'],'s');
                %check if to remove the current folder
                if strcmpi(flag,'Y')
                    eval(['!rm -r ', this_folder]);
                end
            end
            eval(['!mkdir -pv ', this_folder]);
        end
    end
end

end