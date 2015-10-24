%USER DEFINED AREA
clear all;
addpath('/hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/RPOP_vectors/');
behav_dir = '/hsgs/projects/jhyoon1/TMS/RPOP/behav/csv/'; % location of raw data
subjects = {'TMS203'};
vectpath = '/hsgs/projects/jhyoon1/TMS/RPOP/behav/vectors/'; %specify where vectors are written
outname = 'vectors'; % specify name of file to be written
%END OF USER DEFINED AREA 


for s = 1:length(subjects)
    %convert to csv files first
    %first check if csv file already existed
    %if ~exist(fullfile(vectpath,subjects{s},[subjects{s},'.csv']))
        %load_raw_stop_signal(subjects{s},behav_dir,[],30,31);
    %end
    %convert csv files to mat vector files
    data = readedatcsv(fullfile(behav_dir,[subjects{s},'_RPOP.csv']));
    %make the vector
    [Vectors] = make_vectors_RPOP(data);
    %save vectors
    writemat_RPOP(vectpath,subjects{s},outname,Vectors);
end


%quit
