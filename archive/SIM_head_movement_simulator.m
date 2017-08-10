%define vectors of each movement parameters
%function SIM_head_movement_simulator(mprage_dir,thresh,movement_txt_file)
addpath('C:\Users\Edward\Documents\Assignments\packages\matlab_packages\NIFTI\');
mprage_dir='C:\Users\Edward\Documents\Assignments\Imaging Research Center\fMRI\brain_3D_print\Edward.nii';
thresh=100;%intensity threshold, anything below that will be noise


parameter_list={'X','Y','Z','ROW','PITCH','YAW'};
for n = 1:length(parameter_list)
    params.(parameter_list{n})=1;
end

%load generic head object
Head.me=load_nii(mprage_dir);
Head.me.img(Head.me.img<thresh)=0;%convert to binary
Head.me.img(Head.me.img>0)=1;%convert to binary
%find coordinates
[CORD_X,CORD_Y,CORD_Z]=ind2sub(size(Head.me.img),find(Head.me.img>0));