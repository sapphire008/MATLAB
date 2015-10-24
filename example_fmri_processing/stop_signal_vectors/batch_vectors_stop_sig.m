%USER DEFINED AREA
clear all;
behav_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/behav/'; % location of raw data

subjects = {'M3039_CNI_052714','M3129_CNI_060814'};
vectpath = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/stop_signal/behav/'; %specify where vectors are written
outname = 'vectors'; % specify name of file to be written

%END OF USER DEFINED AREA 

addpath /hsgs/projects/jhyoon1/pkg64/matlabpackages/example_fmri_processing/stop_signal_vectors/
for s = 1:length(subjects)
    %convert to csv files first
    %first check if csv file already existed
    if ~exist(fullfile(vectpath,subjects{s},[subjects{s},'.csv']),'file')
        load_raw_stop_signal(subjects{s},behav_dir,[],30,31);
    end
    %convert csv files to mat vector files
    data = readedatcsv(fullfile(vectpath,subjects{s},[subjects{s},'.csv']));
    %make the vector
    [Vectors] = make_vectors_stop_sig(data);
    %save vectors
    writemat_stop_sig(vectpath,subjects{s},outname,Vectors);
end


%quit
