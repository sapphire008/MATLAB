addpath('/nfs/jong_exp/midbrain_pilots/scripts/stop_signal_vectors/');
pathstr = '/nfs/jong_exp/midbrain_pilots/stop_signal/behav/'; % location of the csv files
subject_filter = 'MP124*';  % set to filter subjects selected
%END OF USER DEFINED AREA 

files = dir([pathstr,subject_filter,'.csv']);

for n = 1:length(files),
    [str,name,ext] = fileparts(files(n).name);
    data = readedatcsv([pathstr,files(n).name]);
    str = ['save ',pathstr, name, ' data'];
    eval(str);
    clear data;
end

%quit
