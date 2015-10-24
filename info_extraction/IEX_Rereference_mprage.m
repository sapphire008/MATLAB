function IEX_Rereference_mprage(borrowed_name,mprage_dir)
%IEX_Rereference_mprage(borrowed_name,mprage_dir)
%designed specifically for preprocessed movement data short workspace
%used in case there is no mprage runs available

current_dir=pwd;%take a note of current directory
cd(mprage_dir);%change to mprage directory
load short_workspace.mat;%load work space
satisfied_flag=0;%flag to check if the user like the result.
while satisfied_flag ~= 1
    if ~exist('borrowed_name','var') %check if the borrowed name specified
        borrowed_name=input('What run name should be replaced?');
    end 
    %Change all necessary params to make the current run mprage
    params.project_name=strrep(params.project_name,borrowed_name,'mprage')
    params.dir_name=strrep(params.dir_name,borrowed_name,'mprage')
    params.proj_dir=strrep(params.proj_dir,borrowed_name,'mprage')
    params.im_dir=strrep(params.im_dir,borrowed_name,'mprage')
    clear borrowed_name;
    satisfied_flag=input('Is this okay? 1=Yes, 0=No');
end
     
%save work space
save('short_workspace.mat','params','rotational','total_time',...
    'translational');

cd(current_dir);%change back to current working directory
end
