function IEX_binthresh2double(mprage_dir)
%IEX_binthresh2double(mprage_dir)
%change the binary threshold value to double

current_dir=pwd;%take a note of current directory
cd(mprage_dir);%chagne to mprage directory
load short_workspace.mat;

%change bin_thresh to double
if ischar(params.bin_thresh) 
    if strcmp(params.bin_thresh,'auto')
        params.bin_thresh=0.25;
    else
        params.bin_thresh=num2str(params.bin_thresh);
    end
end

%save work space
save('short_workspace.mat','params','rotational','total_time',...
    'translational');
cd(current_dir);%change back to current directory
end