%USER DEFINED AREA
%pathstr = '/nfs/modafinil/dose3_btwn_grp_analysis/behav/data/'; % location of the csv files
subject_filter = 'AT10_2';  % set to filter subjects selected
vectpath = '/nfs/sn_loc/behav/vectors_nodelay/'; %specify where vectors are written
matpath = '/nfs/sn_loc/behav/csv/';
outname = 'vectors'; % specify name of file to be written
%END OF USER DEFINED AREA 

%creates the vectors
files = dir([matpath,subject_filter,'.mat']);


for k = 1:length(files),
    load([matpath,files(k).name]);

    [Vectors] = make_behav_vector_STN(data);
    
    [foo,name,ext,ver] = fileparts([matpath,files(k).name]);

    writemat_atomoxetine(vectpath,name,outname,Vectors);
    
    clear data Vectors name
end
clear all

