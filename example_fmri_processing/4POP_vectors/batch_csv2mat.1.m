addpath('/home/thompson/example_scripts/behav_code/')
pathstr = '/nfs/u3/SN_loc/behav/csv/'; % location of the csv files
subject_filter = 'AT28_2';  % set to filter subjects selected
%END OF USER DEFINED AREA 

files = dir([pathstr,subject_filter,'.csv']);

for n = 1:length(files),
    [str,name,ext] = fileparts(files(n).name);
    data = readedatcsv([pathstr,files(n).name]);
    str = ['save ',pathstr, name, ' data'];
    eval(str);
    clear data;
end
