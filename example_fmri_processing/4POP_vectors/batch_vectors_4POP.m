%USER DEFINED AREA
clear all;
addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/4POP_vectors/');
behav_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/behav/'; % location of raw data
subjects = {'M3127_CNI_050214'};
vectpath = '/hsgs/projects/jhyoon1/midbrain_pilots/4POP/behav/'; %specify where vectors are written
outname = 'vectors'; % specify name of file to be written
%END OF USER DEFINED AREA 


for s = 1:length(subjects)
    %convert to csv files first
    %first check if csv file already existed
    %if ~exist(fullfile(vectpath,subjects{s},[subjects{s},'.csv']),'file')
        %load_raw_stop_signal(subjects{s},behav_dir,[],30,31);
    %end
    %convert csv files to mat vector files
    csv_file  = fullfile(behav_dir,subjects{s},[subjects{s},'.csv']);
    
    data = readedatcsv(csv_file);
    %make the vector
    [Vectors] = make_vectors_4POP(data);
    %save vectors
    writemat_4POP(vectpath,subjects{s},outname,Vectors);
end


%quit
