function PIPE_vectors_stop_signal(subjects)
%USER DEFINED AREA
%clear all;
addpath('/nfs/jong_exp/midbrain_pilots/scripts/stop_signal_vectors/');
pathstr = '/nfs/jong_exp/midbrain_pilots/stop_signal/behav/'; % location of raw data
% subjects = {'MP020_050613','MP021_051713','MP022_051713','MP023_052013',... 
%     'MP024_052913','MP025_061013','MP120_060513','MP121_060713',...
%     'MP122_061213','MP123_061713','MP124_062113'};
%subjects ={'MP028_062813','MP026_062613','MP027_062713','MP124_062113'};
%subjects = {'MP029_070213','MP030_070313'};
vectpath = '/nfs/jong_exp/midbrain_pilots/stop_signal/behav/'; %specify where vectors are written
outname = 'vectors'; % specify name of file to be written
%END OF USER DEFINED AREA 


for s = 1:length(subjects)
    %convert to csv files first
    %first check if csv file already existed
    %if ~exist(fullfile(vectpath,subjects{s},[subjects{s},'.csv']))
        load_raw_stop_signal(subjects{s});
    %end
    %convert csv files to mat vector files
    data = readedatcsv(fullfile(vectpath,subjects{s},[subjects{s},'.csv']));
    %make the vector
    [Vectors] = make_vectors_stop_sig(data);
    %save vectors
    writemat_stop_sig(vectpath,subjects{s},outname,Vectors);
end


%quit
end